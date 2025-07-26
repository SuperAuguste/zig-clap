pub const ClapVersion = extern struct {
    pub const current: ClapVersion = .{ .major = 1, .minor = 2, .revision = 6 };

    major: u32,
    minor: u32,
    revision: u32,
};

pub const PluginEntry = extern struct {
    clap_version: ClapVersion,
    /// Must be defended with a mutex or counter if complex behavior inside.
    init: *const fn (plugin_path: [*:0]const u8) callconv(.c) bool,
    /// Must be defended with a mutex or counter if complex behavior inside.
    deinit: *const fn () callconv(.c) void,
    /// Must be thread-safe.
    getFactory: *const fn (factory: [*:0]const u8) callconv(.c) ?*const anyopaque,
};

pub const PluginFactory = extern struct {
    pub const id = "clap.plugin-factory";
    /// Must be thread-safe.
    getPluginCount: *const fn (plugin_factory: *const PluginFactory) callconv(.c) u32,
    /// Must be thread-safe.
    getPluginDescriptor: *const fn (plugin_factory: *const PluginFactory, index: u32) callconv(.c) ?*const PluginDescriptor,
    /// Must be thread-safe.
    createPlugin: *const fn (plugin_factory: *const PluginFactory, host: *const Host, plugin_id: [*:0]const u8) callconv(.c) ?*const Plugin,
};

pub const Host = extern struct {
    clap_version: ClapVersion,

    host_data: ?*anyopaque,
    name: [*:0]const u8,
    vendor: ?[*:0]const u8,
    url: ?[*:0]const u8,
    version: [*:0]const u8,

    /// Must be thread-safe.
    getExtension: *const fn (host: *const Host, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque,
    /// Must be thread-safe.
    requestRestart: *const fn (host: *const Host) callconv(.c) void,
    /// Must be thread-safe.
    requestProcess: *const fn (host: *const Host) callconv(.c) void,
    /// Must be thread-safe.
    requestCallback: *const fn (host: *const Host) callconv(.c) void,
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
    init: *const fn (plugin: *const Plugin) callconv(.c) bool,
    /// Called on main thread. Must be deactivated.
    deinit: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on main thread. Must be deactivated.
    activate: *const fn (plugin: *const Plugin, sample_rate: f64, min_frames_count: u32, max_frames_count: u32) callconv(.c) bool,
    /// Called on main thread. Must be activated.
    deactivate: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated and not processing.
    startProcesing: *const fn (plugin: *const Plugin) callconv(.c) bool,
    /// Called on audio thread. Must be activated and processing.
    stopProcesing: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated.
    reset: *const fn (plugin: *const Plugin) callconv(.c) void,
    /// Called on audio thread. Must be activated and processing.
    process: *const fn (plugin: *const Plugin, process: *const Process) callconv(.c) Process.Status,
    /// Must be thread-safe.
    getExtension: *const fn (plugin: *const Plugin, extension_id: [*:0]const u8) callconv(.c) ?*const anyopaque,
    /// Called on main thread after host.request_callback().
    onMainThread: *const fn (plugin: *const Plugin) callconv(.c) void,
};

pub const Process = extern struct {
    steady_time: i64,
    frames_count: u32,
    event_transport: ?*EventTransport,
    audio_inputs: [*]const AudioBuffer,
    audio_outputs: [*]AudioBuffer,
    audio_inputs_count: u32,
    audio_ouputs_count: u32,
    /// Sorted in sample order.
    input_events: *const InputEvents,
    /// Must be sorted in sample order.
    output_events: *const OutputEvents,

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

pub const EventTransport = extern struct {
    header: EventHeader,

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

pub const BeatTime = enum(i64) { _ };
pub const SecTime = enum(i64) { _ };

/// Sorted in sample order. Owned by host.
pub const InputEvents = extern struct {
    ctx: *anyopaque,
    getSize: *const fn (input_events: *const InputEvents) callconv(.c) u32,
    get: *const fn (input_events: *const InputEvents, index: u32) callconv(.c) *const EventHeader,
};

/// Sorted in sample order. Owned by host.
pub const OutputEvents = extern struct {
    ctx: *anyopaque,
    tryPush: *const fn (output_events: *const OutputEvents, event: *const EventHeader) callconv(.c) bool,
};

pub const EventHeader = extern struct {
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
    pub const Flags = packed struct(u32) {
        is_live: bool,
        dont_record: bool,
        padding: u30,
    };
};
