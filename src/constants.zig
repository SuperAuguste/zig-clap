//! Constants used throughout clap (ids, versions, plugin features, fixed point, etc.)

const std = @import("std");

/// String capacity for names that can be displayed to the user.
pub const name_size = 256;

/// String capacity for describing a path, like a parameter in a module hierarchy or path within a
/// set of nested track groups.
///
/// This is not suited for describing a file path on the disk, as NTFS allows up to 32K long
/// paths.
pub const path_size = 1024;

pub const ClapId = enum(u32) {
    invalid = std.math.maxInt(u32),
    _,
};

/// This is the major ABI and API design
/// Version 0.X.Y correspond to the development stage, API and ABI are not stable
/// Version 1.X.Y correspont to the release stage, API and ABI are stable
pub const ClapVersion = extern struct {
    major: u32,
    minor: u32,
    revision: u32,

    pub const current = ClapVersion{ .major = 1, .minor = 1, .revision = 8 };

    pub fn isCompatible(version: ClapVersion) bool {
        // versions 0.x.y were used during development stage and aren't compatible
        return version.major >= 1;
    }
};

pub const PluginFeatures = struct {
    /////////////////////
    // Plugin category //
    /////////////////////

    /// Add this feature if your plugin can process note events and then produce audio
    pub const instrument = "instrument";

    /// Add this feature if your plugin is an audio effect
    pub const audio_effect = "audio-effect";

    /// Add this feature if your plugin is a note effect or a note generator/sequencer
    pub const note_effect = "note-effect";

    /// Add this feature if your plugin is an analyzer
    pub const analyzer = "analyzer";

    /////////////////////////
    // Plugin sub-category //
    /////////////////////////

    pub const synthesizer = "synthesizer";
    pub const sampler = "sampler";
    /// For single drum
    pub const drum = "drum";
    pub const drum_machine = "drum-machine";

    pub const filter = "filter";
    pub const phaser = "phaser";
    pub const equalizer = "equalizer";
    pub const deesser = "de-esser";
    pub const phase_vocoder = "phase-vocoder";
    pub const granular = "granular";
    pub const frequency_shifter = "frequency-shifter";
    pub const pitch_shifter = "pitch-shifter";

    pub const distortion = "distortion";
    pub const transient_shaper = "transient-shaper";
    pub const compressor = "compressor";
    pub const expander = "expander";
    pub const gate = "gate";
    pub const limiter = "limiter";

    pub const flanger = "flanger";
    pub const chorus = "chorus";
    pub const delay = "delay";
    pub const reverb = "reverb";

    pub const tremolo = "tremolo";
    pub const glitch = "glitch";

    pub const utility = "utility";
    pub const pitch_correction = "pitch-correction";
    /// repair the sound
    pub const restoration = "restoration";

    pub const multi_effects = "multi-effects";

    pub const mixing = "mixing";
    pub const mastering = "mastering";

    ////////////////////////
    // Audio Capabilities //
    ////////////////////////

    pub const mono = "mono";
    pub const stereo = "stereo";
    pub const surround = "surround";
    pub const ambisonic = "ambisonic";
};

// We use fixed point representation of beat time and seconds time
// Usage:
//   double x = ...; // in beats
//   clap_beattime y = round(CLAP_BEATTIME_FACTOR * x);

pub const FixedPointTime = enum(i64) {
    _,

    pub fn fromFloat(float: f64) FixedPointTime {
        return @as(FixedPointTime, @enumFromInt(@as(i64, @intFromFloat(std.math.round(@as(f64, @floatFromInt(1 << 31)) * float)))));
    }
};
