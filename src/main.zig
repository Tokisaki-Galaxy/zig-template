const std = @import("std");
const builtin = @import("builtin");

pub fn main() !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("Hello, world!\n", .{});
    try stdout.print("Architecture: {s}\n", .{@tagName(builtin.cpu.arch)});
    try stdout.print("OS: {s}\n", .{@tagName(builtin.os.tag)});
    try stdout.flush();
}
