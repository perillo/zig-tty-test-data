const std = @import("std");
const debug = std.debug;

fn callee() !void {
    return error.Error;
}

fn caller() !void {
    try callee();
}

pub fn main() !void {
    try caller();
}
