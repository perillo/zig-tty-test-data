const std = @import("std");
const debug = std.debug;

fn foo() void {
    std.debug.dumpCurrentStackTrace(null);
}

pub fn main() void {
    foo();
}
