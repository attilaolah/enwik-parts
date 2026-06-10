const std = @import("std");
const config = @import("config");

const urls = @embedFile(config.urls_src);

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(init.io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll(urls);
    try stdout.flush();
}
