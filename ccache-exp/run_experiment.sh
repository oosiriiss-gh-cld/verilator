#!/usr/bin/env bash
# DESCRIPTION: Verilator ccache cacheability experiment
#
# This file ONLY is placed under the Creative Commons Public Domain.
# SPDX-License-Identifier: CC0-1.0
#
# Measures how each kind of source edit affects the ccache hit rate on
# Verilator-generated C++. Uses your normal (global) ccache; it resets
# STATISTICS between builds but never deletes cached objects unless you
# explicitly pass --clear-cache.

set -u -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$HERE/.work"          # constant path: keeps compile commands stable
OBJ="$WORK/obj_dir"
RESULTS="$HERE/results"
PREFIX="Vtb_top"

JOBS="$(nproc 2>/dev/null || echo 4)"
OPT="-O0"                   # compile opt level; hit/miss is independent of it, wall time is not
UVM_DIR=""
CLEAR_CACHE=0
SLOPPINESS="${CCACHE_SLOPPINESS:-}"
ONLY=""

usage() {
  cat <<EOF
Usage: $0 [options]

  --uvm-dir DIR     Directory holding uvm_pkg_all_*.svh and the UVM sources.
                    Default: \$VERILATOR_ROOT/test_regress/t/uvm
  --jobs N          Parallel jobs for verilate and build. Default: all cores
  --opt FLAGS       C++ opt level. Default: -O0 (fast; use -O2 for realism)
  --sloppiness S    Sets CCACHE_SLOPPINESS, e.g. pch_defines,time_macros
  --only NAMES      Comma-separated subset of variants to run
  --clear-cache     Delete ALL cached objects first (prompts). Rarely needed --
                    see the note about cold baselines below.
  -h, --help        This help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --uvm-dir)     UVM_DIR="$2"; shift 2 ;;
    --jobs)        JOBS="$2"; shift 2 ;;
    --opt)         OPT="$2"; shift 2 ;;
    --sloppiness)  SLOPPINESS="$2"; shift 2 ;;
    --only)        ONLY="$2"; shift 2 ;;
    --clear-cache) CLEAR_CACHE=1; shift ;;
    -h|--help)     usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SLOPPINESS" ] && export CCACHE_SLOPPINESS="$SLOPPINESS"

######################################################################
# Preflight

die() { echo "ERROR: $*" >&2; exit 1; }

command -v ccache >/dev/null || die "ccache not found in PATH"
command -v verilator >/dev/null || die "verilator not found in PATH"

# ccache-report in verilated.mk requires OBJCACHE to be exactly "ccache"
export OBJCACHE=ccache

if [ -z "$UVM_DIR" ]; then
  if [ -n "${VERILATOR_ROOT:-}" ] && [ -d "$VERILATOR_ROOT/test_regress/t/uvm" ]; then
    UVM_DIR="$VERILATOR_ROOT/test_regress/t/uvm"
  else
    vroot="$(verilator --getenv VERILATOR_ROOT 2>/dev/null)"
    [ -n "$vroot" ] && [ -d "$vroot/test_regress/t/uvm" ] && UVM_DIR="$vroot/test_regress/t/uvm"
  fi
fi
[ -n "$UVM_DIR" ] && [ -d "$UVM_DIR" ] || die "UVM sources not found; pass --uvm-dir"

UVM_PKG=""
for cand in uvm_pkg_all_v2020_3_2_nodpi.svh \
            uvm_pkg_all_v2020_3_1_nodpi.svh \
            uvm_pkg_all_v2017_1_0_nodpi.svh; do
  [ -f "$UVM_DIR/$cand" ] && { UVM_PKG="$UVM_DIR/$cand"; break; }
done
[ -n "$UVM_PKG" ] || die "No uvm_pkg_all_*_nodpi.svh found in $UVM_DIR"

echo "verilator : $(command -v verilator)  ($(verilator --version 2>/dev/null | head -1))"
echo "ccache    : $(command -v ccache)  ($(ccache --version 2>/dev/null | head -1))"
echo "cache dir : $(ccache -k cache_dir 2>/dev/null || ccache -p 2>/dev/null | sed -n 's/.*cache_dir = //p' | head -1)"
echo "max size  : $(ccache -k max_size 2>/dev/null || echo '?')"
echo "sloppiness: ${CCACHE_SLOPPINESS:-<unset>}"
echo "uvm pkg   : $UVM_PKG"
echo "jobs      : $JOBS    opt: $OPT"
echo

if [ "$CLEAR_CACHE" = 1 ]; then
  echo "About to DELETE every object in your ccache (all projects, not just this one)."
  printf "Type 'yes' to continue: "
  read -r reply
  [ "$reply" = "yes" ] || die "aborted"
  ccache -C
fi

mkdir -p "$RESULTS"

######################################################################
# Source variants

# Each variant rewrites a marker line in the pristine sources. The edits are
# written so the compiler cannot optimize the change away -- a dead signal or
# a foldable statement would vanish and the experiment would measure nothing.
apply_variant() {
  local variant="$1"
  rm -rf "$WORK"
  mkdir -p "$WORK"
  cp "$HERE/dut.sv" "$HERE/tb_pkg.sv" "$HERE/tb_top.sv" "$WORK/"

  case "$variant" in
    baseline|control)
      ;;
    comment)
      # Pure comment + line-number shift. Should change NOTHING downstream.
      perl -0pi -e 's{// EXP:COMMENT}{// EXP:COMMENT\n  // an added comment line\n  // and another one}' "$WORK/tb_pkg.sv"
      ;;
    method_body)
      # Body-only change inside one class method. String literal guarantees
      # the generated code actually differs.
      perl -0pi -e 's{// EXP:METHOD_BODY}{if (sent == 32'"'"'hDEAD_BEEF) \$write("marker A\\n");}' "$WORK/tb_pkg.sv"
      ;;
    class_member)
      # New member on one class -> changes that class'"'"'s generated header.
      perl -0pi -e 's{// EXP:CLASS_MEMBER}{int unsigned extra_field;}' "$WORK/tb_pkg.sv"
      ;;
    dut_signal)
      # New, genuinely live signal inside an RTL module.
      perl -0pi -e "s{assign bonus = '0;  // EXP:DUT_SIGNAL}{logic [WIDTH-1:0] extra_sig;\n  always_ff \@(posedge clk or negedge rst_n) begin\n    if (!rst_n) extra_sig <= '0;\n    else extra_sig <= stage1;\n  end\n  assign bonus = extra_sig;}" "$WORK/dut.sv"
      ;;
    dut_instance)
      # New module instance -> new scope in the symbol table.
      perl -0pi -e "s{assign extra_lane_out = '0;  // EXP:DUT_INSTANCE}{dut_lane #(.WIDTH(8)) lane4 (.clk(clk), .rst_n(rst_n), .din(lane_out[3]), .dout(extra_lane_out));}" "$WORK/dut.sv"
      ;;
    *)
      die "unknown variant: $variant"
      ;;
  esac
}

######################################################################
# One measured build

# Parses the summary block of the ccache report into "hit% total categories"
parse_report() {
  python3 - "$1" <<'PY'
import re, sys, collections
try:
    text = open(sys.argv[1]).read()
except OSError:
    print("0.0 0 NO-REPORT"); sys.exit()
counts = collections.Counter()
for line in text.splitlines():
    m = re.match(r'^(.*?)\s*\|\s*(\d+)\s*\(', line)
    if m:
        counts[m.group(1).strip()] += int(m.group(2))
total = sum(counts.values())
if not total:
    print("0.0 0 NO-COMPILES"); sys.exit()
hits = sum(c for k, c in counts.items() if 'hit' in k.lower())
odd = [k for k in counts if 'hit' not in k.lower() and 'miss' not in k.lower()]
print("%.1f %d %s" % (100.0 * hits / total, total, ",".join(odd) if odd else "-"))
PY
}

run_build() {
  local variant="$1"
  local label="$2"

  apply_variant "$variant"
  rm -rf "$OBJ"

  ccache -z >/dev/null

  local t0 t1 vtime btime
  t0=$(date +%s.%N)
  if ! verilator --main --exe --cc --timing -Wno-fatal \
        --Mdir "$OBJ" -j "$JOBS" \
        "+incdir+$UVM_DIR" "$UVM_PKG" \
        "$WORK/dut.sv" "$WORK/tb_pkg.sv" "$WORK/tb_top.sv" \
        > "$RESULTS/$label.verilate.log" 2>&1; then
    echo "  VERILATION FAILED -- see $RESULTS/$label.verilate.log"
    tail -20 "$RESULTS/$label.verilate.log"
    return 1
  fi
  t1=$(date +%s.%N); vtime=$(echo "$t1 - $t0" | bc)

  t0=$(date +%s.%N)
  if ! make -C "$OBJ" -f "$PREFIX.mk" -j "$JOBS" "$PREFIX" ccache-report \
        > "$RESULTS/$label.build.log" 2>&1; then
    echo "  BUILD FAILED -- see $RESULTS/$label.build.log"
    tail -20 "$RESULTS/$label.build.log"
    return 1
  fi
  t1=$(date +%s.%N); btime=$(echo "$t1 - $t0" | bc)

  cp "$OBJ/${PREFIX}__ccache_report.txt" "$RESULTS/$label.ccache-report.txt" 2>/dev/null
  ccache -s > "$RESULTS/$label.ccache-stats.txt" 2>&1

  local parsed
  parsed=$(parse_report "$RESULTS/$label.ccache-report.txt")
  echo "$label|$parsed|$vtime|$btime" >> "$RESULTS/summary.psv"

  local hitpct total odd
  read -r hitpct total odd <<< "$parsed"
  printf "  hit rate %6s%%   objects %5s   verilate %6.1fs   build %6.1fs   other-categories: %s\n" \
    "$hitpct" "$total" "$vtime" "$btime" "$odd"
}

######################################################################
# Sweep

rm -f "$RESULTS/summary.psv"

ALL_VARIANTS="baseline control comment method_body class_member dut_signal dut_instance"
if [ -n "$ONLY" ]; then
  VARIANTS="$(echo "$ONLY" | tr ',' ' ')"
else
  VARIANTS="$ALL_VARIANTS"
fi

for v in $VARIANTS; do
  case "$v" in
    baseline) echo "[1] baseline -- populates the cache. Expect a LOW hit rate; that is the point." ;;
    control)  echo "[2] control  -- identical sources, fresh obj_dir. Expect ~100%." ;;
    *)        echo "[*] $v" ;;
  esac
  run_build "$v" "$v" || echo "  (continuing)"
done

######################################################################
# Report

echo
echo "===================================================================="
printf "%-14s %9s %9s %11s %9s  %s\n" VARIANT "HIT %" OBJECTS "VERILATE" "BUILD" "OTHER"
echo "--------------------------------------------------------------------"
while IFS='|' read -r label parsed vtime btime; do
  read -r hitpct total odd <<< "$parsed"
  printf "%-14s %8s%% %9s %10.1fs %8.1fs  %s\n" "$label" "$hitpct" "$total" "$vtime" "$btime" "$odd"
done < "$RESULTS/summary.psv"
echo "===================================================================="
echo
echo "Per-file detail: $RESULTS/<variant>.ccache-report.txt"
echo
echo "How to read this:"
echo "  * control well below ~100%  -> output is not byte-stable across runs;"
echo "    nothing else in this table means anything until that is fixed."
echo "  * OTHER column non-empty    -> ccache is neither hitting nor missing,"
echo "    most likely refusing the precompiled-header compiles. Re-run with"
echo "    --sloppiness pch_defines,time_macros and compare."
echo "  * comment/method_body high, dut_* low -> confirms the __Syms.h coupling:"
echo "    class edits stay local, RTL edits invalidate everything."
