const std = @import("std");
const clap = @import("clap");
const assert = std.debug.assert;

export const clap_entry: clap.Entry = .forFactories(.{
    &clap.PluginFactory.forPlugins(std.heap.c_allocator, &.{
        @import("Gain.zig"),
    }),
});
