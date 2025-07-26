const std = @import("std");
const clap = @import("clap");
const assert = std.debug.assert;

export const clap_entry: clap.PluginEntry = .{
    .clap_version = .current,
    .init = &pluginEntryInit,
    .deinit = &pluginEntryDeinit,
    .getFactory = &getFactory,
};

fn pluginEntryInit(plugin_path: [*:0]const u8) callconv(.c) bool {
    _ = plugin_path;
    return true;
}

fn pluginEntryDeinit() callconv(.c) void {}

fn getFactory(factory_ptr: [*:0]const u8) callconv(.c) ?*const anyopaque {
    const factory = std.mem.span(factory_ptr);

    if (!std.mem.eql(u8, factory, clap.PluginFactory.id)) {
        return null;
    }

    return &plugin_factory_instance;
}

const plugin_factory_instance: clap.PluginFactory = .{
    .getPluginCount = &getPluginCount,
    .getPluginDescriptor = &getPluginDescriptor,
    .createPlugin = &createPlugin,
};

fn getPluginCount(plugin_factory: *const clap.PluginFactory) callconv(.c) u32 {
    assert(plugin_factory == &plugin_factory_instance);
    return 1;
}

const plugin_descriptor: clap.PluginDescriptor = .{
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

fn getPluginDescriptor(plugin_factory: *const clap.PluginFactory, index: u32) callconv(.c) ?*const clap.PluginDescriptor {
    assert(plugin_factory == &plugin_factory_instance);
    if (index != 0) {
        return null;
    }
    return &plugin_descriptor;
}

const GainPlugin = struct {
    plugin: clap.Plugin,
};

fn createPlugin(
    plugin_factory: *const clap.PluginFactory,
    host: *const clap.Host,
    plugin_id: [*:0]const u8,
) callconv(.c) ?*const clap.Plugin {
    _ = host;
    _ = plugin_id;
    assert(plugin_factory == &plugin_factory_instance);

    const gain_plugin = std.heap.c_allocator.create(GainPlugin) catch return null;

    gain_plugin.plugin = .{
        .descriptor = &plugin_descriptor,
        // For sanity checking.
        .plugin_data = gain_plugin,
        .init = init,
        .deinit = deinit,
        .activate = activate,
        .deactivate = deactivate,
        .startProcesing = startProcesing,
        .stopProcesing = stopProcesing,
        .reset = reset,
        .process = process,
        .getExtension = getExtension,
        .onMainThread = onMainThread,
    };

    return &gain_plugin.plugin;
}

fn init(plugin: *const clap.Plugin) callconv(.c) bool {
    _ = plugin;
    return true;
}

fn deinit(plugin: *const clap.Plugin) callconv(.c) void {
    _ = plugin;
}

fn activate(plugin: *const clap.Plugin, sample_rate: f64, min_frames_count: u32, max_frames_count: u32) callconv(.c) bool {
    _ = plugin;
    _ = sample_rate;
    _ = min_frames_count;
    _ = max_frames_count;
    return true;
}

fn deactivate(plugin: *const clap.Plugin) callconv(.c) void {
    _ = plugin;
}

fn startProcesing(plugin: *const clap.Plugin) callconv(.c) bool {
    _ = plugin;
    return true;
}

fn stopProcesing(plugin: *const clap.Plugin) callconv(.c) void {
    _ = plugin;
}

fn reset(plugin: *const clap.Plugin) callconv(.c) void {
    _ = plugin;
}

fn process(plugin: *const clap.Plugin, proc: *const clap.Process) callconv(.c) clap.Process.Status {
    _ = plugin;
    _ = proc;
    return .sleep;
}

fn getExtension(plugin: *const clap.Plugin, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque {
    _ = plugin;
    _ = extension_id;
    return null;
}

fn onMainThread(plugin: *const clap.Plugin) callconv(.c) void {
    _ = plugin;
}
