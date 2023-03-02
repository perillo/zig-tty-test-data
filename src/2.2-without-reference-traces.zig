const std = @import("std");
const io = std.io;

var buffer: [512]u8 = undefined;

fn write(buf: []u8) void {
    var fbs = io.fixedBufferStream(&buf);
    const out = fbs.writer();
    for (0..256) |b| {
        try out.writeByte(b);
    }
}

pub fn main() void {
    write(&buffer);
}
