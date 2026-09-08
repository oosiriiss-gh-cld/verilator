#!/usr/bin/env python3
# DESCRIPTION: Verilator: Verilog Test driver/expect definition
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of either the GNU Lesser General Public License Version 3
# or the Perl Artistic License Version 2.0.
# SPDX-FileCopyrightText: 2026 Wilson Snyder
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

import vltest_bootstrap

test.scenarios('linter')

# Assertion support logic must not trip lint checks that inspect procedural
# structure; see the per-module comments in the .v for what each covers.
test.lint(verilator_flags2=["--assert -Wall -Wno-DECLFILENAME"])

test.passes()
