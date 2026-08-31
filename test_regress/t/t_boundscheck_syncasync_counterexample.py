#!/usr/bin/env python3
# DESCRIPTION: Verilator: Verilog Test driver/expect definition
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either the GNU Lesser General Public License Version 3
# or the Perl Artistic License Version 2.0.
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

import vltest_bootstrap

test.scenarios('linter')

# -fno-split: keep the V3Unknown-generated bounds-check If intact through to
# V3Gate; V3Split otherwise happens to rebuild the If without copying
# isBoundsCheck(), which would mask the issue this test guards against.
test.lint(verilator_flags2=["-Wall -Wno-DECLFILENAME -fno-split"],
          fails=True,
          expect_filename=test.golden_filename)

test.passes()
