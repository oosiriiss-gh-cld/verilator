// -*- mode: C++; c-file-style: "cc-mode" -*-
//*************************************************************************
// DESCRIPTION: Verilator: Assertion expansion
//
// Code available from: https://verilator.org
//
//*************************************************************************
//
// This program is free software; you can redistribute it and/or modify it
// under the terms of either the GNU Lesser General Public License Version 3
// or the Perl Artistic License Version 2.0.
// SPDX-FileCopyrightText: 2005-2026 Wilson Snyder
// SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0
//
//*************************************************************************

#ifndef VERILATOR_V3ASSERT_H_
#define VERILATOR_V3ASSERT_H_

#include "config_build.h"
#include "verilatedos.h"

#include "V3Ast.h"

//============================================================================

// Mark 'nodep' as compiler-generated verification logic and return it, so it can be applied
// inline where the node is built:
//     modp->addStmtsp(verificationLogicp(new AstAlways{...}));
// The rule for assertion lowering is: mark every procedure you create, and every statement
// you inject into a procedure the user wrote.  Nodes nested below an already-marked node
// inherit the mark from their position, so a helper shared between those two cases can mark
// unconditionally - a redundant mark costs nothing.  Skipping a mark lets style checks that
// reason about synthesized hardware structure (SYNCASYNCNET, LATCH) mistake checker logic for
// user RTL.  See AstNode::isVerificationLogic.
template <typename T_Node>
T_Node* verificationLogicp(T_Node* nodep) {
    nodep->isVerificationLogic(true);
    return nodep;
}

class V3AssertCommon final {
public:
    static void collectDefaultDisable(AstNetlist* nodep) VL_MT_DISABLED;
    // counter = count; while (counter > 0) { action; counter--; }
    static AstNode* repeatLoop(FileLine* flp, AstVar* counterp, AstNodeExpr* countp,
                               AstNode* actionp) VL_MT_DISABLED;
    static void lowerSequenceEvents(AstNetlist* nodep) VL_MT_DISABLED;
};

class V3Assert final {
public:
    static void assertAll(AstNetlist* nodep) VL_MT_DISABLED;
};

#endif  // Guard
