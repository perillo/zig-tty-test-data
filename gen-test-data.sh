#!/bin/sh
set -x

export ZIG_DEBUG_COLOR=1
test_data_dir=${1:-"data"}

# 1. Zig build-exe progress messages
zig run --color on src/1.1-with-build-progress.zig &> /tmp/buf-1.1
zstring-decode < /tmp/buf-1.1 > "$test_data_dir"/1.1-with-build-progress.out

# 2. Zig build-exe error messages
zig build-exe --color on src/2.1-with-reference-traces.zig &> /tmp/buf-2.1
zstring-decode < /tmp/buf-2.1 > "$test_data_dir"/2.1-with-reference-traces.out

zig build-exe --color on src/2.2-without-reference-traces.zig &> /tmp/buf-2.2
zstring-decode < /tmp/buf-2.2 > "$test_data_dir"/2.2-without-reference-traces.out

zig build-exe --color on src/2.3-with-notes.zig &> /tmp/buf-2.3
zstring-decode < /tmp/buf-2.3 > "$test_data_dir"/2.3-with-notes.out

# 3. Zig run error messages
zig build-exe -femit-bin=binary src/3.1-with-error-return-traces.zig > /dev/null
./binary &> /tmp/buf-3.1
zstring-decode < /tmp/buf-3.1 > "$test_data_dir"/3.1-with-error-return-traces.out

zig build-exe -femit-bin=binary src/3.2-with-stack-trace.zig > /dev/null
./binary &> /tmp/buf-3.2
zstring-decode < /tmp/buf-3.2 > "$test_data_dir"/3.2-with-stack-trace.out

# Write the Zig version.
zig version > "$test_data_dir"/VERSION
