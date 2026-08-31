#!/usr/bin/env python3
# DESCRIPTION: Verilator: Verilog Test driver/expect definition
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either the GNU Lesser General Public License Version 3
# or the Perl Artistic License Version 2.0.
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

import vltest_bootstrap

test.scenarios('linter')

# No -fno-split (or any other special flag) needed here: idx_r is computed
# locally, so V3Split never splits this always block in the first place,
# and the bounds-check If (with isBoundsCheck() set) reaches V3Gate intact
# under plain default flags.
test.lint(verilator_flags2=["-Wall -Wno-DECLFILENAME -Wno-BLKSEQ"],
          fails=True,
          expect_filename=test.golden_filename)

test.passes()
