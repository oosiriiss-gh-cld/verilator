<!-- DESCRIPTION: Verilator: ccache cacheability experiment
     SPDX-FileCopyrightText: 2026-2026 Wilson Snyder
     SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0 -->

# ccache cacheability experiment for Verilator-generated code

Measures how each kind of source edit affects the ccache hit rate on the C++
Verilator generates, using a small UVM testbench over a plain RTL DUT.

## Why this exists

ccache is already wired into every generated compile (`configure.ac:281`
autodetects it, `include/verilated.mk.in:290-307` and `src/V3EmitMk.cpp:745`
put `$(OBJCACHE)` in front of `$(CXX)`). The open question is not whether
ccache runs, it is what fraction of objects it can actually reuse after a
typical edit.

The hypothesis under test comes from the emit code:

```
V<prefix>__pch.h  ->  V<prefix>__Syms.h  ->  every non-class module header
```

Every generated implementation file includes `__pch.h`
(`src/V3EmitCImp.cpp:46`, `src/V3EmitCModel.cpp:697`, `src/V3EmitCSyms.cpp:1100`),
`__pch.h` includes `__Syms.h` (`src/V3EmitCPch.cpp:51`), and `emitSymHdr()`
includes every module header while explicitly skipping classes
(`src/V3EmitCSyms.cpp:943-947`). ccache hashes a source plus its headers, so
anything reachable through that chain is in the hash of *every* object.

Prediction: class-side edits stay local, RTL-side edits invalidate everything.

## Files

| File | Role |
|---|---|
| `dut.sv` | RTL: `dut` with four `dut_lane` instances. Module headers land in `__Syms.h`. |
| `tb_pkg.sv` | UVM-side classes. Class headers do *not* land in `__Syms.h`. |
| `tb_top.sv` | Port-less top so `--main` can generate `main()`. |
| `run_experiment.sh` | Applies one edit at a time, rebuilds, tabulates hit rates. |

The `bonus` and `extra_lane_out` signals in `dut.sv` exist so the script can
splice in a new signal or instance that is genuinely live. A dangling signal
would be optimized away and the experiment would measure nothing.

## Running it

```bash
./run_experiment.sh
```

It finds UVM under `$VERILATOR_ROOT/test_regress/t/uvm` by default; override
with `--uvm-dir`. Useful flags: `--jobs N`, `--opt -O2` (default `-O0` for
speed; hit rate is independent of opt level, wall time is not),
`--only baseline,control`, `--sloppiness pch_defines,time_macros`.

## About clearing the cache

You do not need to. These generated files have never been compiled on your
machine, so the `baseline` run is cold by construction even against a
populated global cache. The script resets ccache *statistics* between builds
(`ccache -z`) but never deletes cached objects.

Only pass `--clear-cache` if you are re-running the whole sweep a second time
and want `baseline` cold again. It deletes every object in your global cache,
for all projects, and prompts before doing so.

Do check capacity first: `ccache -s`. If the cache sits pinned at max size you
are measuring eviction rather than cacheability. `ccache -M 50G` if needed.

## Variants

| Variant | Edit | Prediction |
|---|---|---|
| `baseline` | none | low hit rate, populates the cache |
| `control` | none, fresh `obj_dir` | ~100% |
| `comment` | comment lines in `tb_pkg.sv` | ~100% |
| `method_body` | one statement in one method | high; only that class rebuilds |
| `class_member` | new member on `txn` | moderate; that class and its users |
| `dut_signal` | new live signal in `dut_lane` | low, if the `__Syms.h` theory holds |
| `dut_instance` | fifth `dut_lane` instance | low, if the `__Syms.h` theory holds |

## Reading the output

- **`control` well below ~100%** — output is not byte-stable across runs, or
  something path-dependent is in the compile command. Nothing else in the
  table means anything until that is explained.
- **`OTHER` column non-empty** — ccache is neither hitting nor missing. Most
  likely it is refusing the precompiled-header compiles: Verilator compiles
  with `-include V<prefix>__pch.h.fast` against a `.gch`
  (`include/verilated.mk.in:293,304`) and does not pass `-fpch-preprocess`
  (`CFG_CXXFLAGS_PCH`, `include/verilated.mk.in:46`). Re-run with
  `--sloppiness pch_defines,time_macros` and compare.
- **`comment`/`method_body` high but `dut_*` low** — hypothesis confirmed.
- **`dut_*` also high** — hypothesis wrong, and worth knowing. Diff the
  per-file reports in `results/`.

Per-object detail lands in `results/<variant>.ccache-report.txt`, produced by
the `ccache-report` make target (`include/verilated.mk.in:317-340`,
`bin/verilator_ccache_report`), so you can see *which* files missed rather
than only a percentage.

## One thing this cannot tell you

Verilation itself is not cached at all. `--skip-identical`
(`src/Verilator.cpp:705`) is a single in-place check against
`obj_dir/<prefix>__verFiles.dat`, so a fresh workspace or a branch switch
reuses nothing. The `VERILATE` column in the results table shows what that
step costs you on every build regardless of how well ccache does.
