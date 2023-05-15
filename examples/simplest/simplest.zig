const clap = @import("zig-clap");

const MyPlugin = struct {
    plugin: clap.plugin.Plugin,
    host: *const clap.Host,

    pub const descriptor = clap.plugin.PluginDescriptor{
        .id = "com.your-company.YourPlugin",
        .name = "Plugin Name",
        .vendor = "Vendor",
        .url = "https://your-domain.com/your-plugin",
        .manual_url = "https://your-domain.com/your-plugin/manual",
        .support_url = "https://your-domain.com/support",
        .version = "1.4.2",
        .description = "The plugin description.",
        .features = &[_:null]?[*:0]const u8{
            clap.constants.PluginFeatures.instrument,
            clap.constants.PluginFeatures.stereo,
            null,
        },
    };

    pub fn init(plugin: *MyPlugin) bool {
        _ = plugin;
        return true;
    }

    pub fn deinit(plugin: *MyPlugin) void {
        _ = plugin;
    }

    pub fn activate(
        plugin: *MyPlugin,
        sample_rate: f64,
        min_frames_count: u32,
        max_frames_count: u32,
    ) bool {
        _ = max_frames_count;
        _ = min_frames_count;
        _ = sample_rate;
        _ = plugin;
        return true;
    }

    pub fn deactivate(plugin: *MyPlugin) void {
        _ = plugin;
    }

    pub fn startProcessing(plugin: *MyPlugin) bool {
        _ = plugin;
        return true;
    }

    pub fn stopProcessing(plugin: *MyPlugin) void {
        _ = plugin;
    }

    pub fn reset(plugin: *MyPlugin) void {
        _ = plugin;
    }

    pub fn process(plugin: *MyPlugin, proc: *const clap.Process) clap.Process.Status {
        _ = proc;
        _ = plugin;
        return .failed;
    }

    pub fn getExtension(plugin: *MyPlugin, id: []const u8) ?*const anyopaque {
        _ = id;
        _ = plugin;
        return null;
    }

    pub fn onMainThread(plugin: *MyPlugin) void {
        _ = plugin;
    }
};

comptime {
    clap.exportPlugins(.{}, .{MyPlugin});
}
