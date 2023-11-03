const clap = @import("zig-clap");

const Amp = @This();

plugin: clap.Plugin,
host: *const clap.Host,

pub const descriptor = clap.Plugin.Descriptor{
    .id = "superauguste.amp",
    .name = "Auguste's Amp",
    .vendor = "SuperAuguste",
    .url = "https://github.com/SuperAuguste/zig-clap",
    .manual_url = "https://github.com/SuperAuguste/zig-clap",
    .support_url = "https://github.com/SuperAuguste/zig-clap",
    .version = "0.0.1",
    .description = "It's an amp. Yeah.",
    .features = clap.Plugin.Descriptor.features(.{
        .audio_effect,
        .utility,
        .mono,
        .stereo,
        .surround,
        .ambisonic,
    }),
};

pub fn init(plugin: *Amp) bool {
    _ = plugin;
    return true;
}

pub fn deinit(plugin: *Amp) void {
    _ = plugin;
}

pub fn activate(
    plugin: *Amp,
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

pub fn deactivate(plugin: *Amp) void {
    _ = plugin;
}

pub fn startProcessing(plugin: *Amp) bool {
    _ = plugin;
    return true;
}

pub fn stopProcessing(plugin: *Amp) void {
    _ = plugin;
}

pub fn reset(plugin: *Amp) void {
    _ = plugin;
}

pub fn process(plugin: *Amp, proc: *const clap.Process) clap.Process.Status {
    _ = proc;
    _ = plugin;
    return .failed;
}

pub fn getExtension(plugin: *Amp, id: []const u8) ?*const anyopaque {
    _ = id;
    _ = plugin;
    return null;
}

pub fn onMainThread(plugin: *Amp) void {
    _ = plugin;
}

comptime {
    clap.exportPlugins(.{}, .{Amp});
}
