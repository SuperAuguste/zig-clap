pub const audio_buffer = @import("audio_buffer.zig");
pub const constants = @import("constants.zig");
pub const events = @import("events.zig");
pub const Host = @import("host.zig").Host;
pub const plugin = @import("plugin.zig");
pub const Process = @import("process.zig").Process;

const std = @import("std");

const ExportFunctions = struct {
    init: ?fn (plugin_path: []const u8) anyerror!void = null,
    deinit: ?fn () anyerror!void = null,
};

fn castPluginType(comptime PluginType: type, plugin_data: *anyopaque) *PluginType {
    return @ptrCast(*PluginType, @alignCast(@alignOf(PluginType), plugin_data));
}

fn PluginStub(comptime PluginType: type) type {
    return struct {
        fn init(pl: *const plugin.Plugin) callconv(.C) bool {
            return PluginType.init(castPluginType(PluginType, pl.plugin_data));
        }

        fn destroy(pl: *const plugin.Plugin) callconv(.C) void {
            PluginType.deinit(castPluginType(PluginType, pl.plugin_data));
            std.heap.page_allocator.destroy(castPluginType(PluginType, pl.plugin_data));
            std.heap.page_allocator.destroy(pl);
        }

        fn activate(
            pl: *const plugin.Plugin,
            sample_rate: f64,
            min_frames_count: u32,
            max_frames_count: u32,
        ) callconv(.C) bool {
            return PluginType.activate(
                castPluginType(PluginType, pl.plugin_data),
                sample_rate,
                min_frames_count,
                max_frames_count,
            );
        }

        fn deactivate(pl: *const plugin.Plugin) callconv(.C) void {
            PluginType.deactivate(castPluginType(PluginType, pl.plugin_data));
        }

        fn startProcessing(pl: *const plugin.Plugin) callconv(.C) bool {
            return PluginType.startProcessing(castPluginType(PluginType, pl.plugin_data));
        }

        fn stopProcessing(pl: *const plugin.Plugin) callconv(.C) void {
            PluginType.stopProcessing(castPluginType(PluginType, pl.plugin_data));
        }

        fn reset(pl: *const plugin.Plugin) callconv(.C) void {
            PluginType.reset(castPluginType(PluginType, pl.plugin_data));
        }

        fn process(pl: *const plugin.Plugin, proc: *const Process) callconv(.C) Process.Status {
            return PluginType.process(castPluginType(PluginType, pl.plugin_data), proc);
        }

        // TODO: Bindings for this
        fn getExtension(pl: *const plugin.Plugin, id: [*:0]const u8) callconv(.C) ?*const anyopaque {
            return PluginType.getExtension(castPluginType(PluginType, pl.plugin_data), std.mem.span(id));
        }

        fn onMainThread(pl: *const plugin.Plugin) callconv(.C) void {
            PluginType.onMainThread(castPluginType(PluginType, pl.plugin_data));
        }
    };
}

pub fn exportPlugins(
    comptime functions: ExportFunctions,
    plugins: anytype,
) void {
    const Factory = struct {
        fn getPluginCount(_: *const plugin.PluginFactory) callconv(.C) u32 {
            return plugins.len;
        }

        fn getPluginDescriptor(_: *const plugin.PluginFactory, index: u32) callconv(.C) *const plugin.PluginDescriptor {
            inline for (plugins, 0..) |Pl, i| {
                if (i == index)
                    return &Pl.descriptor;
            }

            @panic("Attempted to get descriptor for non-existent plugin");
        }

        fn createPlugin(
            _: *const plugin.PluginFactory,
            host: *const Host,
            plugin_id: [*:0]const u8,
        ) callconv(.C) *const plugin.Plugin {
            _ = host;
            inline for (plugins) |Pl| {
                if (std.mem.eql(u8, std.mem.span(Pl.descriptor.id), std.mem.span(plugin_id))) {
                    var plug = std.heap.page_allocator.create(plugin.Plugin) catch @panic("OOM");
                    var data = std.heap.page_allocator.create(Pl) catch @panic("OOM");

                    const stub = PluginStub(Pl);
                    plug.* = .{
                        .descriptor = &Pl.descriptor,

                        .plugin_data = @ptrCast(*anyopaque, data),

                        .init = &stub.init,
                        .destroy = &stub.destroy,
                        .activate = &stub.activate,
                        .deactivate = &stub.deactivate,
                        .startProcessing = &stub.startProcessing,
                        .stopProcessing = &stub.stopProcessing,
                        .reset = &stub.reset,
                        .process = &stub.process,
                        .getExtension = &stub.getExtension,
                        .onMainThread = &stub.onMainThread,
                    };
                    return plug;
                }
            }

            @panic("Attempted to create non-existent plugin");
        }
    };

    _ = struct {
        fn init(plugin_path: [*:0]const u8) callconv(.C) bool {
            if (functions.init) |i|
                i(std.mem.span(plugin_path)) catch return false;
            return true;
        }

        fn deinit() callconv(.C) void {
            if (functions.deinit) |d|
                d();
        }

        fn getFactory(factory_id: [*:0]const u8) callconv(.C) ?*const plugin.PluginFactory {
            if (std.mem.eql(u8, std.mem.span(factory_id), "clap.plugin-factory")) {
                return &plugin.PluginFactory{
                    .getPluginCount = &Factory.getPluginCount,
                    .getPluginDescriptor = &Factory.getPluginDescriptor,
                    .createPlugin = &Factory.createPlugin,
                };
            }

            return null;
        }

        export const clap_entry = plugin.PluginEntry{
            .init = &init,
            .deinit = &deinit,
            .getFactory = &getFactory,
        };
    };
}
