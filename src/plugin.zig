const constants = @import("constants.zig");
const ClapVersion = constants.ClapVersion;
const Host = @import("host.zig").Host;
const process = @import("process.zig");

pub const PluginDescriptor = extern struct {
    /// Initialized to current version
    clap_version: ClapVersion = ClapVersion.current,

    // Mandatory fields must be set and must not be blank.
    // Otherwise the fields can be null or blank, though it is safer to make them blank.
    /// eg: "com.u-he.diva", mandatory
    id: [*:0]const u8,
    /// eg: "Diva", mandatory
    name: [*:0]const u8,
    /// eg: "u-he"
    vendor: ?[*:0]const u8,
    /// eg: "https://u-he.com/products/diva/"
    url: ?[*:0]const u8,
    /// eg: "https://dl.u-he.com/manuals/plugins/diva/Diva-user-guide.pdf"
    manual_url: ?[*:0]const u8,
    /// eg: "https://u-he.com/support/"
    support_url: ?[*:0]const u8,
    /// eg: "1.4.4"
    version: ?[*:0]const u8,
    /// eg: "The spirit of analogue"
    description: ?[*:0]const u8,

    /// Arbitrary list of keywords.
    /// They can be matched by the host indexer and used to classify the plugin.
    /// The array of pointers must be null terminated.
    features: [*:0][*:0]const u8,
};

/// This interface is the entry point of the dynamic library.
///
/// CLAP plugins standard search path:
///
/// Linux
///   - ~/.clap
///   - /usr/lib/clap
///
/// Windows
///   - %CommonFilesFolder%/CLAP/
///   - %LOCALAPPDATA%/Programs/Common/CLAP/
///
/// MacOS
///   - /Library/Audio/Plug-Ins/CLAP
///   - ~/Library/Audio/Plug-Ins/CLAP
///
/// Additionally, extra path may be specified in CLAP_PATH environment variable.
/// CLAP_PATH is formated in the same way as the OS' binary search path (PATH on UNIX, Path on Windows).
///
/// Every methods must be thread-safe.
pub const PluginEntry = extern struct {
    /// Initialized to current version
    clap_version: ClapVersion = ClapVersion.current,

    /// This function must be called first, and can only be called once.
    ///
    /// It should be as fast as possible, in order to perform very quick scan of the plugin
    /// descriptors.
    ///
    /// It is forbidden to display graphical user interface in this call.
    /// It is forbidden to perform user inter-action in this call.
    ///
    /// If the initialization depends upon expensive computation, maybe try to do them ahead of time
    /// and cache the result.
    init: fn (plugin_path: [*:0]const u8) bool,

    /// No more calls into the DSO must be made after calling deinit().
    deinit: fn () void,

    /// Get the pointer to a factory. See plugin-factory.h for an example.
    ///
    /// Returns null if the factory is not provided.
    /// The returned pointer must *not* be freed by the caller.
    /// Should be a const pointer but Zig doesn't support *const fn atm :(
    getFactory: fn (factory_id: [*:0]const u8) ?*const PluginFactory,
};

/// Every methods must be thread-safe.
/// It is very important to be able to scan the plugin as quickly as possible.
///
/// If the content of the factory may change due to external events, like the user installed
pub const PluginFactory = struct {
    /// Get the number of plugins available.
    /// [thread-safe]
    getPluginCount: fn (factory: *const PluginFactory) u32,

    /// Retrieves a plugin descriptor by its index.
    /// Returns null in case of error.
    /// The descriptor must not be freed.
    /// [thread-safe]
    getPluginDescriptor: fn (factory: *const PluginFactory, index: u32) *const PluginDescriptor,

    /// Create a clap_plugin by its plugin_id.
    /// The returned pointer must be freed by calling plugin->destroy(plugin);
    /// The plugin is not allowed to use the host callbacks in the create method.
    /// Returns null in case of error.
    /// [thread-safe]
    createPlugin: fn (factory: *const PluginFactory, host: *const Host, plugin_id: [*:0]const u8) *const Plugin,
};

// CLAP_EXPORT extern const clap_plugin_entry_t clap_entry;

pub const Plugin = extern struct {
    descriptor: *const PluginDescriptor,

    /// reserved pointer for the plugin
    plugin_data: *anyopaque,

    /// Must be called after creating the plugin.
    /// If init returns false, the host must destroy the plugin instance.
    /// [main-thread]
    init: fn (plugin: *const Plugin) bool,

    /// Free the plugin and its resources.
    /// It is not required to deactivate the plugin prior to this call.
    /// [main-thread & !active]
    destroy: fn (plugin: *const Plugin) void,

    /// Activate and deactivate the plugin.
    /// In this call the plugin may allocate memory and prepare everything needed for the process
    /// call. The process's sample rate will be constant and process's frame count will included in
    /// the [min, max] range, which is bounded by [1, INT32_MAX].
    /// Once activated the latency and port configuration must remain constant, until deactivation.
    ///
    /// [main-thread & !active_state]
    activate: fn (
        plugin: *const Plugin,
        sample_rate: f64,
        min_frames_count: u32,
        max_frames_count: u32,
    ) bool,

    /// [main-thread & active_state]
    deactivate: fn (plugin: *const Plugin) void,

    /// Call start processing before processing.
    /// [audio-thread & active_state & !processing_state]
    startProcessing: fn (plugin: *const Plugin) bool,

    /// Call stop processing before sending the plugin to sleep.
    /// [audio-thread & active_state & processing_state]
    stopProcessing: fn (plugin: *const Plugin) void,

    /// - Clears all buffers, performs a full reset of the processing state (filters, oscillators,
    ///   enveloppes, lfo, ...) and kills all voices.
    /// - The parameter's value remain unchanged.
    /// - clap_process.steady_time may jump backward.
    ///
    /// [audio-thread & active_state]
    reset: fn (plugin: *const Plugin) void,

    /// process audio, events, ...
    /// [audio-thread & active_state & processing_state]
    process: fn (plugin: *const Plugin, process: *const process.Process) process.ProcessStatus,

    /// Query an extension.
    /// The returned pointer is owned by the plugin.
    /// [thread-safe]
    getExtension: fn (plugin: *const Plugin, id: [*:0]const u8) ?*const anyopaque,

    /// Called by the host on the main thread in response to a previous call to:
    ///   host.requestCallback();
    /// [main-thread]
    onMainThread: fn (plugin: *const Plugin) void,
};
