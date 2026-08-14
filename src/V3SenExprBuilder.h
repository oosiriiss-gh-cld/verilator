// -*- mode: C++; c-file-style: "cc-mode" -*-
//*************************************************************************
// DESCRIPTION: Verilator: Builder for sensitivity checking expressions.
//
// Code available from: https://verilator.org
//
//*************************************************************************
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of either the GNU Lesser General Public License Version 3
// or the Perl Artistic License Version 2.0.
// SPDX-FileCopyrightText: 2003-2026 Wilson Snyder
// SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0
//
//*************************************************************************

#ifndef VERILATOR_V3SENEXPRBUILDER_H_
#define VERILATOR_V3SENEXPRBUILDER_H_

#include "config_build.h"
#include "verilatedos.h"

#include "V3Ast.h"
#include "V3UniqueNames.h"

//######################################################################
// SenExprBuilder constructs the expressions used to compute if an
// AstSenTree have triggered

class SenExprBuilder final {
public:
    // TYPES
    struct Results final {
        std::vector<AstNodeStmt*> m_inits;  // Initialization statements for previous values
        std::vector<AstNodeStmt*> m_preUpdates;  // Pre update assignments
        std::vector<AstNodeStmt*> m_postUpdates;  // Post update assignments
        // Aliases of destructive post updates (for example event clearFired) that may need
        // to run once before entering a fresh dynamic wait loop.
        std::vector<AstNodeStmt*> m_destructivePostUpdates;
        std::vector<AstVar*> m_vars;  // Created temporary variables
    };

private:
    // STATE
    AstScope* const m_scopep;  // The scope

    Results m_results;  // The builder result

    std::unordered_map<VNRef<AstNode>, AstVarScope*> m_prev;  // The 'previous value' signals
    std::unordered_map<VNRef<AstNode>, AstVarScope*> m_curr;  // The 'current value' signals
    std::unordered_set<VNRef<AstNode>> m_hasPreUpdate;  // Whether the given sen expression already
                                                        // has an update statement in m_preUpdates
    std::unordered_set<VNRef<AstNode>> m_hasPostUpdate;  // Likewise for m_postUpdates

    V3UniqueNames m_currNames{"__Vtrigcurrexpr"};  // For generating unique current value
                                                   // signal names
    V3UniqueNames m_prevNames{"__Vtrigprevexpr"};  // Likewise for previous values

    static bool isSupportedDType(AstNodeDType* dtypep) {
        dtypep = dtypep->skipRefp();
        if (VN_IS(dtypep, BasicDType)) return true;
        if (VN_IS(dtypep, PackArrayDType)) return true;
        if (VN_IS(dtypep, UnpackArrayDType)) return isSupportedDType(dtypep->subDTypep());
        if (VN_IS(dtypep, NodeUOrStructDType)) return true;  // All are packed at the moment
        // Per IEEE, detects reference object pointer changes, not contents of the class changes
        if (VN_IS(dtypep, ClassRefDType)) return true;
        return false;
    }

    static bool isSimpleExpr(const AstNode* const exprp) {
        return exprp->forall([](const AstNode* const nodep) {
            return VN_IS(nodep, Const) || VN_IS(nodep, NodeVarRef) || VN_IS(nodep, Sel)
                   || VN_IS(nodep, NodeSel) || VN_IS(nodep, MemberSel)
                   || VN_IS(nodep, CMethodHard);
        });
    }

    // Get all base class reference expressions that need to be null-checked before evaluating
    // 'exprp'. A class member access (e.g. a DynScope handle created in a fork block, or a
    // virtual interface) can appear anywhere within 'exprp', not just as a leading chain of
    // member selects rooted at 'exprp' itself (for example, array bounds checks wrap such an
    // access in additional GTE/LOGAND/COND logic), so the whole subtree is searched. For each
    // member selection found, the outermost class reference in its selection chain is what
    // must be checked. The result is deduplicated by structural equality.
    // Note: Returned pointers are into the original tree - caller must clone if needed.
    static std::vector<const AstNodeExpr*> getBaseClassRefs(const AstNodeExpr* const exprp) {
        std::vector<const AstNodeExpr*> resultsVec;
        if (!exprp) return resultsVec;
        std::unordered_set<VNRef<AstNode>> seen;
        exprp->foreach([&](const AstMemberSel* const mselp) {
            const AstNodeExpr* basep = mselp->fromp();
            if (!basep->dtypep() || !VN_IS(basep->dtypep()->skipRefp(), ClassRefDType)) return;
            // Walk to the outermost class reference in the selection chain
            while (const AstMemberSel* const innerp = VN_CAST(basep, MemberSel)) {
                const AstNodeExpr* const innerBasep = innerp->fromp();
                if (!innerBasep->dtypep()
                    || !VN_IS(innerBasep->dtypep()->skipRefp(), ClassRefDType)) {
                    break;
                }
                basep = innerBasep;
            }
            if (seen.emplace(*const_cast<AstNodeExpr*>(basep)).second) resultsVec.push_back(basep);
        });
        return resultsVec;
    }

    // METHODS
    AstVarScope* crateTemp(AstNodeExpr* exprp) {
        // For readability, use the scoped signal name if the trigger is a simple AstVarRef
        string name;
        if (AstVarRef* const refp = VN_CAST(exprp, VarRef)) {
            AstVarScope* const vscp = refp->varScopep();
            name = "__" + vscp->scopep()->nameDotless() + "__" + vscp->varp()->name();
            name = m_prevNames.get(name);
        } else {
            name = m_prevNames.get(exprp);
        }
        AstVarScope* const vscp = m_scopep->createTemp(name, exprp->dtypep());
        vscp->varp()->isInternal(true);
        m_results.m_vars.push_back(vscp->varp());
        return vscp;
    }

    // Build a conjunction of '!= null' checks for the given base class references. Returns
    // nullptr if the list is empty.
    AstNodeExpr* buildNullChecks(FileLine* flp,
                                 const std::vector<const AstNodeExpr*>& baseClassRefs) {
        AstNodeExpr* checkp = nullptr;
        for (const AstNodeExpr* const refp : baseClassRefs) {
            AstNodeExpr* const nullp = new AstConst{flp, AstConst::Null{}};
            // const_cast safe: cloneTree doesn't modify the source
            AstNodeExpr* const neqp
                = new AstNeq{flp, const_cast<AstNodeExpr*>(refp)->cloneTree(false), nullp};
            checkp = checkp ? new AstLogAnd{flp, checkp, neqp} : neqp;
        }
        return checkp;
    }

    // Helper to wrap a statement with a null check: if (ref0 != null && ref1 != null...) stmt
    AstNodeStmt* wrapStmtWithNullCheck(FileLine* flp, AstNodeStmt* stmtp,
                                       const std::vector<const AstNodeExpr*>& baseClassRefs) {
        AstNodeExpr* const checkp = buildNullChecks(flp, baseClassRefs);
        if (!checkp) return stmtp;
        return new AstIf{flp, checkp, stmtp};
    }

    // Helper to wrap a trigger expression with a null check if needed
    // Returns the expression wrapped in: (ref0 != null && ref1 != null...) ? expr : 0
    AstNodeExpr* wrapExprWithNullCheck(FileLine* flp, AstNodeExpr* exprp,
                                       const std::vector<const AstNodeExpr*>& baseClassRefs) {
        AstNodeExpr* const checkp = buildNullChecks(flp, baseClassRefs);
        if (!checkp) return exprp;
        AstNodeExpr* const falsep = new AstConst{flp, AstConst::BitFalse{}};
        AstNodeExpr* const condp = new AstCond{flp, checkp, exprp, falsep};
        condp->dtypeSetBit();
        return condp;
    }

    AstNodeExpr* getCurr(AstNodeExpr* exprp) {
        // For simple expressions like varrefs or selects, just use them directly
        if (isSimpleExpr(exprp)) return exprp->cloneTree(false);

        // Create the 'current value' variable
        FileLine* const flp = exprp->fileline();
        auto result = m_curr.emplace(*exprp, nullptr);
        if (result.second) result.first->second = crateTemp(exprp);
        AstVarScope* const currp = result.first->second;

        // Check if we need null guards for class member access
        const std::vector<const AstNodeExpr*> baseClassRefs = getBaseClassRefs(exprp);

        // Add pre update if it does not exist yet in this round
        if (m_hasPreUpdate.emplace(*currp).second) {
            m_results.m_preUpdates.push_back(
                wrapStmtWithNullCheck(flp,
                                      new AstAssign{flp, new AstVarRef{flp, currp, VAccess::WRITE},
                                                    exprp->cloneTree(false)},
                                      baseClassRefs));
        }
        return new AstVarRef{flp, currp, VAccess::READ};
    }

    AstVarScope* getPrev(AstNodeExpr* exprp) {
        FileLine* const flp = exprp->fileline();
        const auto rdCurr = [this, exprp]() { return getCurr(exprp); };

        // Check if we need null guards for class member access
        const std::vector<const AstNodeExpr*> baseClassRefs = getBaseClassRefs(exprp);

        AstNode* scopeExprp = exprp;
        if (AstVarRef* const refp = VN_CAST(exprp, VarRef)) scopeExprp = refp->varScopep();
        // Create the 'previous value' variable
        const auto pair = m_prev.emplace(*scopeExprp, nullptr);
        if (pair.second) {
            AstVarScope* const prevp = crateTemp(exprp);
            pair.first->second = prevp;
            // Add the initializer init (guarded if class member access)
            AstAssign* const initp = new AstAssign{flp, new AstVarRef{flp, prevp, VAccess::WRITE},
                                                   exprp->cloneTree(false)};
            m_results.m_inits.push_back(wrapStmtWithNullCheck(flp, initp, baseClassRefs));
        }

        AstVarScope* const prevp = pair.first->second;

        const auto wrPrev = [=]() { return new AstVarRef{flp, prevp, VAccess::WRITE}; };

        // Add post update if it does not exist yet
        if (m_hasPostUpdate.emplace(*exprp).second) {
            AstNodeDType* const exprDtp = exprp->dtypep()->skipRefp();
            if (!isSupportedDType(exprDtp)) {
                exprp->v3warn(
                    E_UNSUPPORTED,
                    "Unsupported: Cannot detect changes on expression of complex type "
                        << exprDtp->prettyDTypeNameQ() << "\n"
                        << exprp->warnMore()
                        << "... May be caused by combinational cycles reported with UNOPTFLAT");
                return prevp;
            }
            if (VN_IS(exprDtp, UnpackArrayDType)) {
                AstCMethodHard* const cmhp
                    = new AstCMethodHard{flp, wrPrev(), VCMethod::UNPACKED_ASSIGN, rdCurr()};
                cmhp->dtypeSetVoid();
                m_results.m_postUpdates.push_back(
                    wrapStmtWithNullCheck(flp, cmhp->makeStmt(), baseClassRefs));
            } else {
                m_results.m_postUpdates.push_back(wrapStmtWithNullCheck(
                    flp, new AstAssign{flp, wrPrev(), rdCurr()}, baseClassRefs));
            }
        }

        return prevp;
    }

    std::pair<AstNodeExpr*, bool> createTerm(const AstSenItem* senItemp) {
        FileLine* const flp = senItemp->fileline();
        AstNodeExpr* const senp = senItemp->sensp();

        // Check if the sensitivity expression involves accessing through a class reference
        // that may be null (e.g., DynScope handles created in fork blocks, or class member
        // virtual interfaces). If so, we need to guard against null pointer dereference.
        const std::vector<const AstNodeExpr*> baseClassRefs = getBaseClassRefs(senp);

        const auto currp = [this, senp]() { return getCurr(senp); };
        const auto prevp
            = [this, flp, senp]() { return new AstVarRef{flp, getPrev(senp), VAccess::READ}; };
        const auto lsb = [=](AstNodeExpr* opp) { return new AstSel{flp, opp, 0, 1}; };

        // All event signals should be 1-bit at this point
        switch (senItemp->edgeType()) {
        case VEdgeType::ET_CHANGED:
        case VEdgeType::ET_HYBRID:  //
            if (VN_IS(senp->dtypep()->skipRefp(), UnpackArrayDType)) {
                // operand order reversed to avoid calling neq() method on non-VlUnpacked type, see
                // issue #5125
                AstCMethodHard* const resultp
                    = new AstCMethodHard{flp, prevp(), VCMethod::UNPACKED_NEQ, currp()};
                resultp->dtypeSetBit();
                return {wrapExprWithNullCheck(flp, resultp, baseClassRefs), true};
            }
            return {wrapExprWithNullCheck(flp, new AstNeq{flp, currp(), prevp()}, baseClassRefs),
                    true};
        case VEdgeType::ET_BOTHEDGE:  //
            return {
                wrapExprWithNullCheck(flp, lsb(new AstXor{flp, currp(), prevp()}), baseClassRefs),
                false};
        case VEdgeType::ET_POSEDGE:  //
            return {wrapExprWithNullCheck(flp,
                                          lsb(new AstAnd{flp, currp(), new AstNot{flp, prevp()}}),
                                          baseClassRefs),
                    false};
        case VEdgeType::ET_NEGEDGE:  //
            return {wrapExprWithNullCheck(flp,
                                          lsb(new AstAnd{flp, new AstNot{flp, currp()}, prevp()}),
                                          baseClassRefs),
                    false};
        case VEdgeType::ET_EVENT: {
            UASSERT_OBJ(v3Global.hasEvents(), senItemp, "Inconsistent");

            // Clear 'fired' state when done (guarded if class member access)
            AstCMethodHard* const clearp
                = new AstCMethodHard{flp, currp(), VCMethod::EVENT_CLEAR_FIRED};
            clearp->dtypeSetVoid();
            AstNodeStmt* const clearStmtp
                = wrapStmtWithNullCheck(flp, clearp->makeStmt(), baseClassRefs);
            m_results.m_postUpdates.push_back(clearStmtp);
            m_results.m_destructivePostUpdates.push_back(clearStmtp);

            // Get 'fired' state
            AstCMethodHard* const callp
                = new AstCMethodHard{flp, currp(), VCMethod::EVENT_IS_FIRED};
            callp->dtypeSetBit();
            AstNodeExpr* const firedp = wrapExprWithNullCheck(flp, callp, baseClassRefs);
            if (const AstVarRef* const refp = VN_CAST(senp, VarRef)) {
                // The private NBA event must run so pending assignments finish settling.
                if (refp->varScopep() == v3Global.rootp()->nbaEventp()) return {firedp, false};
            }
            // Do not trigger user named-event processes after $finish.
            AstNodeExpr* const notFinishp
                = new AstCExpr{flp,
                               "VL_LIKELY(!vlSymsp->_vm_contextp__->gotFinish() && "
                               "!vlSymsp->_vm_contextp__->finishPending())",
                               1};
            return {new AstLogAnd{flp, notFinishp, firedp}, false};
        }
        case VEdgeType::ET_TRUE:  //
            return {currp(), false};
        case VEdgeType::ET_INITIAL_NBA:  //
            return {new AstConst{flp, AstConst::BitFalse{}}, true};
        default:  // LCOV_EXCL_START
            senItemp->v3fatalSrc("Unknown edge type");
            return {nullptr, false};
        }  // LCOV_EXCL_STOP
    }

public:
    // Returns the expression computing the trigger, and a bool indicating that
    // this trigger should be fired on the first evaluation (at initialization)
    std::pair<AstNodeExpr*, bool> build(const AstSenItem* senItemp) {
        auto term = createTerm(senItemp);
        if (AstNodeExpr* const condp = senItemp->condp()) {
            term.first = new AstAnd{senItemp->fileline(), condp->cloneTreePure(false), term.first};
        }
        return term;
    }

    // Like above, but for a whole SenTree
    std::pair<AstNodeExpr*, bool> build(const AstSenTree* senTreep) {
        FileLine* const flp = senTreep->fileline();
        AstNodeExpr* resultp = nullptr;
        bool firedAtInitialization = false;
        for (AstSenItem* senItemp = senTreep->sensesp(); senItemp;
             senItemp = VN_AS(senItemp->nextp(), SenItem)) {
            const auto& pair = build(senItemp);
            if (AstNodeExpr* termp = pair.first) {
                resultp = resultp ? new AstOr{flp, resultp, termp} : termp;
                firedAtInitialization |= pair.second;
            }
        }
        return {resultp, firedAtInitialization};
    }

    Results getResultsAndClearUpdates() {
        m_hasPreUpdate.clear();
        m_hasPostUpdate.clear();
        Results ans = std::move(m_results);
        m_results = {};
        return ans;
    }

    Results getAndClearResults() {
        m_curr.clear();
        m_prev.clear();
        m_hasPreUpdate.clear();
        m_hasPostUpdate.clear();
        return std::move(m_results);
    }

    // CONSTRUCTOR
    explicit SenExprBuilder(AstScope* scopep)
        : m_scopep{scopep} {}
};

#endif  // Guard
