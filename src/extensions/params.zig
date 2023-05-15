const std = @import("std");
const constants = @import("constants.zig");

pub const extension = "clap.params";

pub const InfoFlags = packed struct(u32) {
    /// Is this param stepped? (integer values only)
    /// if so the double value is converted to integer using a cast (equivalent to trunc).
    is_stepped: bool,

    /// Useful for periodic parameters like a phase
    is_periodic: bool,

    /// The parameter should not be shown to the user, because it is currently not used.
    /// It is not necessary to process automation for this parameter.
    is_hidden: bool,

    /// The parameter can't be changed by the host.
    is_readonly: bool,

    /// This parameter is used to merge the plugin and host bypass button.
    /// It implies that the parameter is stepped.
    /// min: 0 -> bypass off
    /// max: 1 -> bypass on
    is_bypass: bool,

    /// When set:
    /// - automation can be recorded
    /// - automation can be played back
    ///
    /// The host can send live user changes for this parameter regardless of this flag.
    ///
    /// If this parameter affects the internal processing structure of the plugin, ie: max delay, fft
    /// size, ... and the plugins needs to re-allocate its working buffers, then it should call
    /// host->request_restart(), and perform the change once the plugin is re-activated.
    is_automatable: bool,

    /// Does this parameter support per note automations?
    is_automatable_per_note_id: bool,

    /// Does this parameter support per key automations?
    is_automatable_per_key: bool,

    /// Does this parameter support per channel automations?
    is_automatable_per_channel: bool,

    /// Does this parameter support per port automations?
    is_automatable_per_port: bool,

    /// Does this parameter support the modulation signal?
    is_modulatable: bool,

    /// Does this parameter support per note modulations?
    is_modulatable_per_note_id: bool,

    /// Does this parameter support per key modulations?
    is_modulatable_per_key: bool,

    /// Does this parameter support per channel modulations?
    is_modulatable_per_channel: bool,

    /// Does this parameter support per port modulations?
    is_modulatable_per_port: bool,

    /// Any change to this parameter will affect the plugin output and requires to be done via
    /// process() if the plugin is active.
    ///
    /// A simple example would be a DC Offset, changing it will change the output signal and must be
    /// processed.
    requires_process: bool,

    _unallocated: u16 = 0,
};

pub const ParamInfo = extern struct {
    /// Stable parameter identifier, it must never change.
    id: constants.ClapId,

    flags: InfoFlags,

    /// This value is optional and set by the plugin.
    /// Its purpose is to provide fast access to the plugin parameter object by caching its pointer.
    /// For instance:
    ///
    /// in clap_plugin_params.get_info():
    ///    Parameter *p = findParameter(param_id);
    ///    param_info->cookie = p;
    ///
    /// later, in clap_plugin.process():
    ///
    ///    Parameter *p = (Parameter *)event->cookie;
    ///    if (!p) [[unlikely]]
    ///       p = findParameter(event->param_id);
    ///
    /// where findParameter() is a function the plugin implements to map parameter ids to internal
    /// objects.
    ///
    /// Important:
    ///  - The cookie is invalidated by a call to clap_host_params->rescan(CLAP_PARAM_RESCAN_ALL) or
    ///    when the plugin is destroyed.
    ///  - The host will either provide the cookie as issued or nullptr in events addressing
    ///    parameters.
    ///  - The plugin must gracefully handle the case of a cookie which is nullptr.
    ///  - Many plugins will process the parameter events more quickly if the host can provide the
    ///    cookie in a faster time than a hashmap lookup per param per event.
    cookie: *anyopaque,

    /// The display name. eg: "Volume". This does not need to be unique. Do not include the module
    /// text in this. The host should concatenate/format the module + name in the case where showing
    /// the name alone would be too vague.
    name: [constants.name_size]u8,

    // The module path containing the param, eg: "Oscillators/Wavetable 1".
    // '/' will be used as a separator to show a tree-like structure.
    module: [constants.path_size]u8,

    /// Minimum plain value
    min_value: f64,
    /// Maximum plain value
    max_value: f64,
    /// Default plain value
    default_value: f64,
};
