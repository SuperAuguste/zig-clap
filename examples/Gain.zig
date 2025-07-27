const std = @import("std");
const clap = @import("clap");

const Gain = @This();

pub const descriptor: clap.Plugin.Descriptor = .{
    .clap_version = .current,
    .id = "zig-clap.examples.gain",
    .name = "Gain",
    .vendor = "Zig Clap Examples",
    .url = "https://github.com/SuperAuguste/zig-clap",
    .manual_url = "https://github.com/SuperAuguste/zig-clap",
    .support_url = "https://github.com/SuperAuguste/zig-clap/issues",
    .version = "0.0.1",
    .description = "A simple gain plugin",
    .features = null,
};

pub const create = clap.Plugin.createFor(@This());

pub fn init(gain: *Gain, allocator: std.mem.Allocator) error{}!void {
    _ = gain; // autofix
    _ = allocator; // autofix
}

pub fn deinit(gain: *Gain, allocator: std.mem.Allocator) void {
    _ = gain; // autofix
    _ = allocator; // autofix
}
