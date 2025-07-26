const std = @import("std");
const clap = @import("clap");
const assert = std.debug.assert;

export const clap_entry: clap.Entry = .forFactories(.{
    &clap.PluginFactory.forPlugins(std.heap.c_allocator, &.{GainPlugin}),
});

const GainPlugin = struct {
    pub const descriptor: clap.PluginDescriptor = .{
        .clap_version = .current,
        .id = "zig.gain",
        .name = "Zig Gain",
        .vendor = "Auguste Rame",
        .url = "https://github.com/SuperAuguste/zig-clap",
        .manual_url = "https://github.com/SuperAuguste/zig-clap",
        .support_url = "https://github.com/SuperAuguste/zig-clap/issues",
        .version = "0.0.1",
        .description = "A simple gain plugin",
        .features = null,
    };

    pub const create = clap.Plugin.createFor(@This());

    pub fn init(gain: *GainPlugin, allocator: std.mem.Allocator) error{}!void {
        _ = gain; // autofix
        _ = allocator; // autofix
    }

    pub fn deinit(gain: *GainPlugin, allocator: std.mem.Allocator) void {
        _ = gain; // autofix
        _ = allocator; // autofix
    }
};
