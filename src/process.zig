const AudioBuffer = @import("audio_buffer.zig").AudioBuffer;

pub const ProcessStatus = enum(i32) {
    /// Processing failed. The output buffer must be discarded.
    failed = 0,

    /// Processing succeed, keep processing.
    success = 1,

    /// Processing succeed, keep processing if the output is not quiet.
    continue_if_not_quiet = 2,

    /// Rely upon the plugin's tail to determine if the plugin should continue to process.
    /// see clap_plugin_tail
    tail = 3,

    /// Processing succeed, but no more processing is required,
    /// until next event or variation in audio input.
    sleep = 4,
};

pub const Process = extern struct {
    /// A steady sample time counter.
    /// This field can be used to calculate the sleep duration between two process calls.
    /// This value may be specific to this plugin instance and have no relation to what
    /// other plugin instances may receive.
    ///
    /// Set to -1 if not available, otherwise the value must be greater or equal to 0,
    /// and must be increased by at least `frames_count` for the next call to process.
    steady_time: i64,

    /// Number of frame to process
    frames_count: u32,

    /// time info at sample 0
    /// If null, then this is a free running host, no transport events will be provided
    transport: ?*const EventTransport,

    /// Audio buffers, they must have the same count as specified
    /// by clap_plugin_audio_ports->get_count().
    /// The index maps to clap_plugin_audio_ports->get_info().
    audio_inputs: *const AudioBuffer,
    audio_outputs: *AudioBuffer,
    audio_inputs_count: u32,
    audio_outputs_count: u32,

    /// Input and output events.
    ///
    /// Events must be sorted by time.
    /// The input event list can't be modified.
    in_events: *const InputEvents,
    out_events: *const OutputEvents,
};
