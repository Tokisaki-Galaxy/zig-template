const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Hello, world!\n", .{});
    try stdout.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});
    try stdout.print("OS: {s}\n", .{@tagName(builtin.os.tag)});
}
