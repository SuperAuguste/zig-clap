const std = @import("std");
const assert = std.debug.assert;

pub const ClapVersion = extern struct {
    pub const current: ClapVersion = .{ .major = 1, .minor = 2, .revision = 6 };

    major: u32,
    minor: u32,
    revision: u32,
};

pub const Entry = extern struct {
    clap_version: ClapVersion,
    /// Must be defended with a mutex or counter if complex behavior inside.
    initFn: *const fn (plugin_path: [*:0]const u8) callconv(.c) bool,
    /// Must be defended with a mutex or counter if complex behavior inside.
    deinitFn: *const fn () callconv(.c) void,
    /// Must be thread-safe.
    getFactoryFn: *const fn (factory: [*:0]const u8) callconv(.c) ?*const anyopaque,

    pub fn forFactories(factories: anytype) Entry {
        const Instance = struct {
            fn init(plugin_path: [*:0]const u8) callconv(.c) bool {
                _ = plugin_path;
                return true;
            }

            fn deinit() callconv(.c) void {}

            fn getFactory(factory_id_ptr: [*:0]const u8) callconv(.c) ?*const anyopaque {
                const factory_id = std.mem.span(factory_id_ptr);

                inline for (factories) |factory_ptr| {
                    if (!std.mem.eql(u8, factory_id, @TypeOf(factory_ptr.*).id)) {
                        return factory_ptr;
                    }
                }

                return null;
            }
        };

        return .{
            .clap_version = .current,
            .initFn = &Instance.init,
            .deinitFn = &Instance.deinit,
            .getFactoryFn = &Instance.getFactory,
        };
    }
};

pub const PluginFactory = extern struct {
    pub const id = "clap.plugin-factory";
    /// Must be thread-safe.
    getPluginCountFn: *const fn (plugin_factory: *const PluginFactory) callconv(.c) u32,
    /// Must be thread-safe.
    getPluginDescriptorFn: *const fn (plugin_factory: *const PluginFactory, index: u32) callconv(.c) ?*const PluginDescriptor,
    /// Must be thread-safe.
    createPluginFn: *const fn (plugin_factory: *const PluginFactory, host: *const Host, plugin_id: [*:0]const u8) callconv(.c) ?*const Plugin,

    /// PluginFactory given a slice of types with:
    /// - A `descriptor: PluginDescriptor` decl
    /// - An `fn create(allocator: std.mem.Allocator) error{OutOfMemory}!*const Plugin` decl
    pub fn forPlugins(
        allocator: std.mem.Allocator,
        comptime plugins: []const type,
    ) PluginFactory {
        const Factory = struct {
            fn getPluginCount(plugin_factory: *const PluginFactory) callconv(.c) u32 {
                _ = plugin_factory;
                return plugins.len;
            }

            fn getPluginDescriptor(plugin_factory: *const PluginFactory, index: u32) callconv(.c) ?*const PluginDescriptor {
                _ = plugin_factory;
                inline for (plugins, 0..) |PluginType, i| {
                    if (i == index) {
                        return &PluginType.descriptor;
                    }
                }
                return null;
            }

            fn createPlugin(
                plugin_factory: *const PluginFactory,
                host: *const Host,
                plugin_id_raw: [*:0]const u8,
            ) callconv(.c) ?*const Plugin {
                _ = plugin_factory;
                _ = host;

                const plugin_id = std.mem.span(plugin_id_raw);

                inline for (plugins) |PluginType| {
                    if (std.mem.eql(u8, comptime std.mem.span(PluginType.descriptor.id), plugin_id)) {
                        return PluginType.create(allocator) catch null;
                    }
                }

                return null;
            }
        };

        return .{
            .getPluginCountFn = Factory.getPluginCount,
            .getPluginDescriptorFn = Factory.getPluginDescriptor,
            .createPluginFn = Factory.createPlugin,
        };
    }
};

pub const Host = extern struct {
    clap_version: ClapVersion,

    host_data: ?*anyopaque,
    name: [*:0]const u8,
    vendor: ?[*:0]const u8,
    url: ?[*:0]const u8,
    version: [*:0]const u8,

    /// Must be thread-safe.
    getExtensionFn: *const fn (host: *const Host, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque,
    /// Must be thread-safe.
    requestRestartFn: *const fn (host: *const Host) callconv(.c) void,
    /// Must be thread-safe.
    requestProcessFn: *const fn (host: *const Host) callconv(.c) void,
    /// Must be thread-safe.
    requestCallbackFn: *const fn (host: *const Host) callconv(.c) void,

    pub fn getExtension(host: *const Host, extension_id: [:0]const u8) ?*const anyopaque {
        return host.getExtensionFn(host, extension_id);
    }
};

pub const PluginDescriptor = extern struct {
    clap_version: ClapVersion,

    id: [*:0]const u8,
    name: [*:0]const u8,
    vendor: ?[*:0]const u8,
    url: ?[*:0]const u8,
    manual_url: ?[*:0]const u8,
    support_url: ?[*:0]const u8,
    version: ?[*:0]const u8,
    description: ?[*:0]const u8,

    features: ?[*:null]?[*:0]const u8,
};

pub const Plugin = extern struct {
    descriptor: *const PluginDescriptor,

    plugin_data: ?*anyopaque,

    /// Called on main thread.
    initFn: *const fn (plugin: *const Plugin) callconv(.c) bool,
    /// Called on main thread. Must be deactivated.
    destroyFn: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on main thread. Must be deactivated.
    activateFn: *const fn (plugin: *const Plugin, sample_rate: f64, min_frames_count: u32, max_frames_count: u32) callconv(.c) bool,
    /// Called on main thread. Must be activated.
    deactivateFn: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated and not processing.
    startProcesingFn: *const fn (plugin: *const Plugin) callconv(.c) bool,
    /// Called on audio thread. Must be activated and processing.
    stopProcesingFn: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated.
    resetFn: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated and processing.
    processFn: *const fn (plugin: *const Plugin, process: *const Process) callconv(.c) Process.Status,
    /// Must be thread-safe.
    getExtensionFn: *const fn (plugin: *const Plugin, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque,
    /// Called on main thread after host.request_callback().
    onMainThreadFn: *const fn (plugin: *const Plugin) callconv(.c) void,

    /// `T` must have a `descriptor: PluginDescriptor` decl
    ///
    /// The following functions are required on `T`:
    /// - `init(plugin: *T, allocator: std.mem.Allocator) error{...}!void`
    /// - `deinit(plugin: *T, allocator: std.mem.Allocator) void` (destroy is implemented by `createFor`; you only need to deinit your plugin instance)
    ///
    /// The following functions are optional on `T`:
    /// - `activate(plugin: *T, allocator: std.mem.Allocator, sample_rate: f64, min_frames_count: u32, max_frames_count: u32) error{...}!void`
    /// - `deactivate(plugin: *T, allocator: std.mem.Allocator) void`
    /// - `startProcesing(plugin: *T) error{...}!void`
    /// - `stopProcesing(plugin: *T) void`
    /// - `reset(plugin: *T)`
    /// - `process(plugin: *T, process: *const Process) Process.Status`
    /// - `getExtension(plugin: *T, extension_id: [:0]const u8) ?*const anyopaque`
    /// - `onMainThread(plugin: *T, allocator: std.mem.Allocator) void`
    pub fn createFor(
        comptime T: type,
    ) fn (allocator: std.mem.Allocator) error{OutOfMemory}!*const Plugin {
        return struct {
            const PluginData = struct {
                allocator: std.mem.Allocator,
                is_initialized: bool,
                user_plugin: T,
            };

            fn create(allocator: std.mem.Allocator) error{OutOfMemory}!*const Plugin {
                const plugin = try allocator.create(Plugin);
                errdefer allocator.destroy(plugin);

                const plugin_data = try allocator.create(PluginData);
                errdefer allocator.destroy(plugin_data);

                plugin_data.* = .{
                    .allocator = allocator,
                    .is_initialized = false,
                    .user_plugin = undefined,
                };

                plugin.* = .{
                    .descriptor = &T.descriptor,
                    .plugin_data = plugin_data,
                    .initFn = init,
                    .destroyFn = destroy,
                    .activateFn = activate,
                    .deactivateFn = deactivate,
                    .startProcesingFn = startProcesing,
                    .stopProcesingFn = stopProcesing,
                    .resetFn = reset,
                    .processFn = process,
                    .getExtensionFn = getExtension,
                    .onMainThreadFn = onMainThread,
                };

                return plugin;
            }

            fn init(plugin: *const Plugin) callconv(.c) bool {
                const plugin_data: *PluginData = @alignCast(@ptrCast(plugin.plugin_data));

                if (plugin_data.is_initialized) {
                    return true;
                }

                T.init(&plugin_data.user_plugin, plugin_data.allocator) catch {
                    return false;
                };
                plugin_data.is_initialized = true;
                return true;
            }

            fn destroy(plugin: *const Plugin) callconv(.c) void {
                const plugin_data: *PluginData = @alignCast(@ptrCast(plugin.plugin_data));

                if (plugin_data.is_initialized) {
                    T.deinit(&plugin_data.user_plugin, plugin_data.allocator);
                }

                plugin_data.allocator.destroy(plugin_data);
                plugin_data.allocator.destroy(plugin);
            }

            fn activate(plugin: *const Plugin, sample_rate: f64, min_frames_count: u32, max_frames_count: u32) callconv(.c) bool {
                if (!@hasDecl(T, "activate")) {
                    return false;
                }

                // const plugin_data: *PluginData = @alignCast(@ptrCast(plugin.plugin_data));

                _ = plugin;
                _ = sample_rate;
                _ = min_frames_count;
                _ = max_frames_count;
                return true;
            }

            fn deactivate(plugin: *const Plugin) callconv(.c) void {
                if (!@hasDecl(T, "deactivate")) {
                    return;
                }

                _ = plugin;
            }

            fn startProcesing(plugin: *const Plugin) callconv(.c) bool {
                if (!@hasDecl(T, "startProcesing")) {
                    return false;
                }

                _ = plugin;
                return true;
            }

            fn stopProcesing(plugin: *const Plugin) callconv(.c) void {
                if (!@hasDecl(T, "stopProcesing")) {
                    return;
                }

                _ = plugin;
            }

            fn reset(plugin: *const Plugin) callconv(.c) void {
                _ = plugin; // autofix
                if (!@hasDecl(T, "reset")) {
                    return;
                }
            }

            fn process(plugin: *const Plugin, proc: *const Process) callconv(.c) Process.Status {
                if (!@hasDecl(T, "process")) {
                    return .sleep;
                }
                _ = plugin;
                _ = proc;
            }

            fn getExtension(plugin: *const Plugin, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque {
                if (!@hasDecl(T, "getExtension")) {
                    return null;
                }
                _ = plugin;
                _ = extension_id;
                return null;
            }

            fn onMainThread(plugin: *const Plugin) callconv(.c) void {
                if (!@hasDecl(T, "onMainThread")) {
                    return;
                }

                _ = plugin;
            }
        }.create;
    }
};

pub const Process = extern struct {
    steady_time: i64,
    frames_count: u32,
    event_transport: ?*Event.Transport,
    audio_inputs: [*]const AudioBuffer,
    audio_outputs: [*]AudioBuffer,
    audio_inputs_count: u32,
    audio_ouputs_count: u32,
    /// Sorted in sample order.
    input_events: *const Event.InputList,
    /// Must be sorted in sample order.
    output_events: *const Event.OutputList,

    pub const Status = enum(i32) {
        @"error" = 0,
        @"continue" = 1,
        continue_if_not_quiet = 2,
        tail = 3,
        sleep = 4,
        _,
    };
};

pub const AudioBuffer = extern struct {
    data_32: [*][*]f32,
    data_64: [*][*]f64,
    channel_count: u32,
    latency: u32,
    constant_mask: u64,
};

pub const BeatTime = enum(i64) { _ };
pub const SecTime = enum(i64) { _ };

pub const Event = struct {
    /// Sorted in sample order. Owned by host.
    pub const InputList = extern struct {
        ctx: *anyopaque,
        getLenFn: *const fn (input_events: *const InputList) callconv(.c) u32,
        atFn: *const fn (input_events: *const InputList, index: u32) callconv(.c) ?*const Event,

        pub fn len(input_events: *const InputList) u32 {
            return input_events.getLenFn();
        }

        pub fn at(input_events: *const InputList, index: u32) *const Event {
            assert(index < input_events.getSize());
            return input_events.atFn(index).?;
        }
    };

    /// Sorted in sample order. Owned by host.
    pub const OutputList = extern struct {
        ctx: *anyopaque,
        tryPushFn: *const fn (output_events: *const OutputList, event: *const Event) callconv(.c) bool,

        pub fn push(output_events: *const OutputList, event: *const Event) error{OutOfMemory}!void {
            if (!output_events.tryPushFn(output_events, event)) {
                return error.OutOfMemory;
            }
        }
    };

    pub const Type = enum(u16) {
        note_on = 0,
        note_off = 1,
        note_choke = 2,
        note_end = 3,
        note_expression = 4,
        param_value = 5,
        param_mod = 6,
        param_gesture_begin = 7,
        param_gesture_end = 8,
        transport = 9,
        midi = 10,
        midi_sysex = 11,
        midi2 = 12,
        _,
    };

    pub const Header = extern struct {
        /// Size including header.
        size: u32,
        time: u32,
        space_id: SpaceId,
        type: Type,
        flags: Flags,

        pub const SpaceId = enum(u16) {
            core = 0,
            _,
        };
        pub const Flags = packed struct(u32) {
            is_live: bool,
            dont_record: bool,
            padding: u30,
        };
    };

    pub const Transport = extern struct {
        header: Event.Header,

        flags: Flags,
        song_pos_beats: BeatTime,
        song_pos_seconds: SecTime,
        tempo: f64,
        tempo_inc: f64,
        loop_start_beats: BeatTime,
        loop_end_beats: BeatTime,
        loop_start_seconds: SecTime,
        loop_end_seconds: SecTime,
        bar_start: BeatTime,
        bar_number: i32,
        tsig_num: u16,
        tsig_denom: u16,

        pub const Flags = packed struct(u32) {
            has_tempo: bool,
            has_beats_timeline: bool,
            has_seconds_timeline: bool,
            has_time_signature: bool,
            is_playing: bool,
            is_recording: bool,
            is_loop_active: bool,
            is_within_pre_roll: bool,
            padding: u24,
        };
    };
};
