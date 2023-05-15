const constants = @import("constants.zig");

/// event header
/// must be the first attribute of the event
pub const EventHeader = extern struct {
    /// event size including this header, eg: sizeof (clap_event_note)
    size: u32,
    /// sample offset within the buffer for this event
    time: u32,
    /// event space, see clap_host_event_registry
    space_id: u16,
    /// event type
    type: EventType,
    /// see clap_event_flags
    flags: EventFlags,
};

// The clap core event space
pub const core_event_space_id: u16 = 0;

pub const EventFlags = enum(u32) {
    /// Indicate a live user event, for example a user turning a phisical knob
    /// or playing a physical key.
    is_live = 1 << 0,

    /// Indicate that the event should not be recorded.
    /// For example this is useful when a parameter changes because of a MIDI CC,
    /// because if the host records both the MIDI CC automation and the parameter
    /// automation there will be a conflict.
    dont_record = 1 << 1,

    _,
};

/// Some of the following events overlap, a note on can be expressed with:
/// - CLAP_EVENT_NOTE_ON
/// - CLAP_EVENT_MIDI
/// - CLAP_EVENT_MIDI2
///
/// The preferred way of sending a note event is to use CLAP_EVENT_NOTE_*.
///
/// The same event must not be sent twice: it is forbidden to send a the same note on
/// encoded with both CLAP_EVENT_NOTE_ON and CLAP_EVENT_MIDI.
///
/// The plugins are encouraged to be able to handle note events encoded as raw midi or midi2,
/// or implement clap_plugin_event_filter and reject raw midi and midi2 events.
pub const EventType = enum(u16) {
    // NOTE_ON and NOTE_OFF represents a key pressed and key released event.
    // A NOTE_ON with a velocity of 0 is valid and should not be interpreted as a NOTE_OFF.
    //
    // NOTE_CHOKE is meant to choke the voice(s), like in a drum machine when a closed hihat
    // chokes an open hihat. This event can be sent by the host to the plugin. Here two use case:
    // - a plugin is inside a drum pad in Bitwig Studio's drum machine, and this pad is choked by
    //   another one
    // - the user double clicks the DAW's stop button in the transport which then stops the sound on
    //   every tracks
    //
    // NOTE_END is sent by the plugin to the host. The port, channel, key and note_id are those given
    // by the host in the NOTE_ON event. In other words, this event is matched against the
    // plugin's note input port.
    // NOTE_END is useful to help the host to match the plugin's voice life time.
    //
    // When using polyphonic modulations, the host has to allocate and release voices for its
    // polyphonic modulator. Yet only the plugin effectively knows when the host should terminate
    // a voice. NOTE_END solves that issue in a non-intrusive and cooperative way.
    //
    // CLAP assumes that the host will allocate a unique voice on NOTE_ON event for a given port,
    // channel and key. This voice will run until the plugin will instruct the host to terminate
    // it by sending a NOTE_END event.
    //
    // Consider the following sequence:
    // - process()
    //    Host->Plugin NoteOn(port:0, channel:0, key:16, time:t0)
    //    Host->Plugin NoteOn(port:0, channel:0, key:64, time:t0)
    //    Host->Plugin NoteOff(port:0, channel:0, key:16, t1)
    //    Host->Plugin NoteOff(port:0, channel:0, key:64, t1)
    //    # on t2, both notes did terminate
    //    Host->Plugin NoteOn(port:0, channel:0, key:64, t3)
    //    # Here the plugin finished to process all the frames and will tell the host
    //    # to terminate the voice on key 16 but not 64, because a note has been started at t3
    //    Plugin->Host NoteEnd(port:0, channel:0, key:16, time:ignored)
    //
    // Those four events use clap_event_note.
    note_on,
    note_off,
    note_choke,
    note_end,

    /// Represents a note expression.
    /// Uses clap_event_note_expression.
    note_expression,

    // PARAM_VALUE sets the parameter's value; uses clap_event_param_value.
    // PARAM_MOD sets the parameter's modulation amount; uses clap_event_param_mod.
    //
    // The value heard is: param_value + param_mod.
    //
    // In case of a concurrent global value/modulation versus a polyphonic one,
    // the voice should only use the polyphonic one and the polyphonic modulation
    // amount will already include the monophonic signal.
    param_value,
    param_mod,

    // Indicates that the user started or finished to adjust a knob.
    // This is not mandatory to wrap parameter changes with gesture events, but this improves a lot
    // the user experience when recording automation or overriding automation playback.
    // Uses clap_event_param_gesture.
    param_gesture_begin,
    param_gesture_end,

    /// update the transport info; clap_event_transport
    transport,
    /// raw midi event; clap_event_midi
    midi,
    /// raw midi sysex event; clap_event_midi_sysex
    midi_sysex,
    /// raw midi 2 event; clap_event_midi2
    midi2,
    _,
};

/// Note on, off, end and choke events.
/// In the case of note choke or end events:
/// - the velocity is ignored.
/// - key and channel are used to match active notes, a value of -1 matches all.
pub const EventNote = extern struct {
    header: EventHeader,

    /// -1 if unspecified, otherwise >=0
    note_id: i32,
    port_index: i16,
    /// 0..15
    channel: i16,
    /// 0..127
    key: i16,
    /// 0..1
    velocity: f64,
};

pub const NoteExpression = enum(i32) {
    /// with 0 < x <= 4, plain = 20 * log(x)
    volume,

    /// pan, 0 left, 0.5 center, 1 right
    pan,

    /// relative tuning in semitone, from -120 to +120
    tuning,

    /// 0..1
    vibrato,
    /// 0..1
    expression,
    /// 0..1
    brightness,
    /// 0..1
    pressure,
};

pub const EventNoteExpression = extern struct {
    header: EventHeader,

    expression_id: NoteExpression,

    // target a specific note_id, port, key and channel, -1 for global
    note_id: i32,
    port_index: i16,
    channel: i16,
    key: i16,

    value: f64, // see expression for the range
};

pub const EventParamValue = extern struct {
    header: EventHeader,

    // target parameter
    /// @ref clap_param_info.id
    param_id: constants.ClapId,
    /// @ref clap_param_info.cookie
    cookie: *anyopaque,

    // target a specific note_id, port, key and channel, -1 for global
    note_id: i32,
    port_index: i16,
    channel: i16,
    key: i16,

    value: f64,
};

pub const EventParamMod = extern struct {
    header: EventHeader,

    // target parameter
    /// @ref clap_param_info.id
    param_id: constants.ClapId,
    /// @ref clap_param_info.cookie
    cookie: *anyopaque,

    // target a specific note_id, port, key and channel, -1 for global
    note_id: i32,
    port_index: i16,
    channel: i16,
    key: i16,

    /// modulation amount
    amount: f64,
};

pub const EventParamGesture = extern struct {
    header: EventHeader,

    // target parameter
    /// @ref clap_param_info.id
    param_id: constants.ClapId,
};

pub const TransportFlags = enum(u32) {
    has_tempo = 1 << 0,
    has_beats_timeline = 1 << 1,
    has_seconds_timeline = 1 << 2,
    has_time_signature = 1 << 3,
    is_playing = 1 << 4,
    is_recording = 1 << 5,
    is_loop_active = 1 << 6,
    is_within_pre_roll = 1 << 7,

    pub fn is(value: constants.ConstantMask, desired: constants.ConstantMask) bool {
        return (@enumToInt(value) & @enumToInt(desired)) != 0;
    }
};

pub const EventTransport = extern struct {
    header: EventHeader,

    flags: TransportFlags,

    /// position in beats
    song_pos_beats: constants.FixedPointTime,
    /// position in seconds
    song_pos_seconds: constants.FixedPointTime,

    /// in bpm
    tempo: f64,
    /// tempo increment for each samples and until the next time info event
    tempo_inc: f64,

    loop_start_beats: constants.FixedPointTime,
    loop_end_beats: constants.FixedPointTime,
    loop_start_seconds: constants.FixedPointTime,
    loop_end_seconds: constants.FixedPointTime,

    /// start pos of the current bar
    bar_start: constants.FixedPointTime,
    /// bar at song pos 0 has the number 0
    bar_number: i32,

    /// time signature numerator
    tsig_num: u16,
    /// time signature denominator
    tsig_denom: u16,
};

pub const EventMidi = extern struct {
    header: EventHeader,

    port_index: u16,
    data: [3]u8,
};

pub const EventMidiSysex = extern struct {
    header: EventHeader,

    port_index: u16,
    /// midi buffer
    buffer: [*]u8,
    size: u32,

    pub fn slice(event: EventMidiSysex) []u8 {
        return event.buffer[0..event.size];
    }
};

/// While it is possible to use a series of midi2 event to send a sysex,
/// prefer clap_event_midi_sysex if possible for efficiency.
pub const EventMidi2 = extern struct {
    header: EventHeader,

    port_index: u16,
    data: [4]u32,
};

// Input event list, events must be sorted by time.
pub const InputEvents = extern struct {
    /// reserved pointer for the list
    ctx: *anyopaque,

    size: *const fn (list: *const InputEvents) u32,
    /// Don't free the returned event, it belongs to the list
    get: *const fn (list: *const InputEvents, index: u32) *const EventHeader,

    pub const Iterator = struct {
        events: *const InputEvents,
        index: u32,

        /// Don't free the returned event, it belongs to the list
        pub fn next(it: Iterator) ?*const EventHeader {
            if (iterator.index == it.events.size(it.events))
                return null;

            var header = it.events.get(it.events, it.index);
            it.index += 1;
            return header;
        }
    };

    pub fn iterator(events: *const InputEvents) Iterator {
        return .{ .events = events, .index = 0 };
    }
};

// Output event list, events must be sorted by time.
pub const OutputEvents = extern struct {
    /// reserved pointer for the list
    ctx: *anyopaque,

    // Pushes a copy of the event
    // returns false if the event could not be pushed to the queue (out of memory?)
    tryPush: *const fn (list: *const OutputEvents, event: *const EventHeader) bool,

    pub fn push(list: *const OutputEvents, event: *const EventHeader) error{OutOfMemory}!void {
        if (!list.tryPush(list, event)) return error.OutOfMemory;
    }
};
