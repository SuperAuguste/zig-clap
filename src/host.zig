const constants = @import("constants.zig");
const ClapVersion = constants.ClapVersion;

pub const Host = extern struct {
    /// Initialized to current version
    clap_version: ClapVersion = ClapVersion.current,

    /// reserved pointer for the host
    host_data: *anyopaque,

    // name and version are mandatory.
    /// eg: "Bitwig Studio"
    name: [*:0]const u8,
    /// eg: "Bitwig GmbH"
    vendor: ?[*:0]const u8,
    /// eg: "https://bitwig.com"
    url: ?[*:0]const u8,
    /// eg: "4.3"
    version: [*:0]const u8,

    /// Query an extension.
    /// [thread-safe]
    getExtension: *const fn (host: *const Host, extension_id: [*:0]const u8) *const anyopaque,

    /// Request the host to deactivate and then reactivate the plugin.
    /// The operation may be delayed by the host.
    /// [thread-safe]
    requestRestart: *const fn (host: *const Host) void,

    /// Request the host to activate and start processing the plugin.
    /// This is useful if you have external IO and need to wake up the plugin from "sleep".
    /// [thread-safe]
    requestProcess: *const fn (host: *const Host) void,

    /// Request the host to schedule a call to plugin.onMainThread() on the main thread.
    /// [thread-safe]
    requestCallback: *const fn (host: *const Host) void,
};
