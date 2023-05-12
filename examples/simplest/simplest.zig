const clap = @import("zig-clap");

const my_plug_desc = clap.plugin.PluginDescriptor{
    .id = "com.your-company.YourPlugin",
    .name = "Plugin Name",
    .vendor = "Vendor",
    .url = "https://your-domain.com/your-plugin",
    .manual_url = "https://your-domain.com/your-plugin/manual",
    .support_url = "https://your-domain.com/support",
    .version = "1.4.2",
    .description = "The plugin description.",
    .features = .{
        clap.constants.PluginFeatures.instrument,
        clap.constants.PluginFeatures.stereo,
    },
};

const MyPlugin = struct {
    plugin: clap.plugin.Plugin,
    host: *const clap.host.Host,
};

pub fn myPluginInit(plugin: *const clap.plugin.Plugin) bool {
    _ = plugin;
    return true;
}

pub fn myPluginDestroy(plugin: *const clap.plugin.Plugin) void {
    _ = plugin;
}

pub fn myPluginActivate(
    plugin: *const clap.plugin.Plugin,
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

pub fn myPluginDeactivate(plugin: *const clap.plugin.Plugin) void {
    _ = plugin;
}

pub fn myPluginStartProcessing(plugin: *const clap.plugin.Plugin) bool {
    _ = plugin;
    return true;
}

pub fn myPluginStopProcessing(plugin: *const clap.plugin.Plugin) void {
    _ = plugin;
}

pub fn myPluginReset(plugin: *const clap.plugin.Plugin) void {
    _ = plugin;
}

// static void my_plug_process_event(my_plug_t *plug, const clap_event_header_t *hdr) {
//    if (hdr->space_id == CLAP_CORE_EVENT_SPACE_ID) {
//       switch (hdr->type) {
//       case CLAP_EVENT_NOTE_ON: {
//          const clap_event_note_t *ev = (const clap_event_note_t *)hdr;
//          // TODO: handle note on
//          break;
//       }

//       case CLAP_EVENT_NOTE_OFF: {
//          const clap_event_note_t *ev = (const clap_event_note_t *)hdr;
//          // TODO: handle note on
//          break;
//       }

//       case CLAP_EVENT_NOTE_CHOKE: {
//          const clap_event_note_t *ev = (const clap_event_note_t *)hdr;
//          // TODO: handle note choke
//          break;
//       }

//       case CLAP_EVENT_NOTE_EXPRESSION: {
//          const clap_event_note_expression_t *ev = (const clap_event_note_expression_t *)hdr;
//          // TODO: handle note expression
//          break;
//       }

//       case CLAP_EVENT_PARAM_VALUE: {
//          const clap_event_param_value_t *ev = (const clap_event_param_value_t *)hdr;
//          // TODO: handle parameter change
//          break;
//       }

//       case CLAP_EVENT_PARAM_MOD: {
//          const clap_event_param_mod_t *ev = (const clap_event_param_mod_t *)hdr;
//          // TODO: handle parameter modulation
//          break;
//       }

//       case CLAP_EVENT_TRANSPORT: {
//          const clap_event_transport_t *ev = (const clap_event_transport_t *)hdr;
//          // TODO: handle transport event
//          break;
//       }

//       case CLAP_EVENT_MIDI: {
//          const clap_event_midi_t *ev = (const clap_event_midi_t *)hdr;
//          // TODO: handle MIDI event
//          break;
//       }

//       case CLAP_EVENT_MIDI_SYSEX: {
//          const clap_event_midi_sysex_t *ev = (const clap_event_midi_sysex_t *)hdr;
//          // TODO: handle MIDI Sysex event
//          break;
//       }

//       case CLAP_EVENT_MIDI2: {
//          const clap_event_midi2_t *ev = (const clap_event_midi2_t *)hdr;
//          // TODO: handle MIDI2 event
//          break;
//       }
//       }
//    }
// }

// static clap_process_status my_plug_process(const struct clap_plugin *plugin,
//                                            const clap_process_t     *process) {
//    my_plug_t     *plug = plugin->plugin_data;
//    const uint32_t nframes = process->frames_count;
//    const uint32_t nev = process->in_events->size(process->in_events);
//    uint32_t       ev_index = 0;
//    uint32_t       next_ev_frame = nev > 0 ? 0 : nframes;

//    for (uint32_t i = 0; i < nframes;) {
//       /* handle every events that happrens at the frame "i" */
//       while (ev_index < nev && next_ev_frame == i) {
//          const clap_event_header_t *hdr = process->in_events->get(process->in_events, ev_index);
//          if (hdr->time != i) {
//             next_ev_frame = hdr->time;
//             break;
//          }

//          my_plug_process_event(plug, hdr);
//          ++ev_index;

//          if (ev_index == nev) {
//             // we reached the end of the event list
//             next_ev_frame = nframes;
//             break;
//          }
//       }

//       /* process every samples until the next event */
//       for (; i < next_ev_frame; ++i) {
//          // fetch input samples
//          const float in_l = process->audio_inputs[0].data32[0][i];
//          const float in_r = process->audio_inputs[0].data32[1][i];

//          /* TODO: process samples, here we simply swap left and right channels */
//          const float out_l = in_r;
//          const float out_r = in_l;

//          // store output samples
//          process->audio_outputs[0].data32[0][i] = out_l;
//          process->audio_outputs[0].data32[1][i] = out_r;
//       }
//    }

//    return CLAP_PROCESS_CONTINUE;
// }

pub fn myPluginGetExtension(plugin: *const clap.plugin.Plugin, id: [*:0]const u8) ?*const anyopaque {
    _ = id;
    _ = plugin;
    return null;
}

pub fn myPluginOnMainThread(plugin: *const clap.plugin.Plugin) void {
    _ = plugin;
}

// clap_plugin_t *my_plug_create(const clap_host_t *host) {
//    my_plug_t *p = calloc(1, sizeof(*p));
//    p->host = host;
//    p->plugin.desc = &s_my_plug_desc;
//    p->plugin.plugin_data = p;
//    p->plugin.init = my_plug_init;
//    p->plugin.destroy = my_plug_destroy;
//    p->plugin.activate = my_plug_activate;
//    p->plugin.deactivate = my_plug_deactivate;
//    p->plugin.start_processing = my_plug_start_processing;
//    p->plugin.stop_processing = my_plug_stop_processing;
//    p->plugin.reset = my_plug_reset;
//    p->plugin.process = my_plug_process;
//    p->plugin.get_extension = my_plug_get_extension;
//    p->plugin.on_main_thread = my_plug_on_main_thread;

//    // Don't call into the host here

//    return &p->plugin;
// }

// /////////////////////////
// // clap_plugin_factory //
// /////////////////////////

// static struct {
//    const clap_plugin_descriptor_t *desc;
//    clap_plugin_t *(*create)(const clap_host_t *host);
// } s_plugins[] = {
//    {
//       .desc = &s_my_plug_desc,
//       .create = my_plug_create,
//    },
// };

// static uint32_t plugin_factory_get_plugin_count(const struct clap_plugin_factory *factory) {
//    return sizeof(s_plugins) / sizeof(s_plugins[0]);
// }

// static const clap_plugin_descriptor_t *
// plugin_factory_get_plugin_descriptor(const struct clap_plugin_factory *factory, uint32_t index) {
//    return s_plugins[index].desc;
// }

// static const clap_plugin_t *plugin_factory_create_plugin(const struct clap_plugin_factory *factory,
//                                                          const clap_host_t                *host,
//                                                          const char *plugin_id) {
//    if (!clap_version_is_compatible(host->clap_version)) {
//       return NULL;
//    }

//    const int N = sizeof(s_plugins) / sizeof(s_plugins[0]);
//    for (int i = 0; i < N; ++i)
//       if (!strcmp(plugin_id, s_plugins[i].desc->id))
//          return s_plugins[i].create(host);

//    return NULL;
// }

// static const clap_plugin_factory_t s_plugin_factory = {
//    .get_plugin_count = plugin_factory_get_plugin_count,
//    .get_plugin_descriptor = plugin_factory_get_plugin_descriptor,
//    .create_plugin = plugin_factory_create_plugin,
// };

// ////////////////
// // clap_entry //
// ////////////////

// static bool entry_init(const char *plugin_path) {
//    // called only once, and very first
//    return true;
// }

// static void entry_deinit(void) {
//    // called before unloading the DSO
// }

// static const void *entry_get_factory(const char *factory_id) {
//    if (!strcmp(factory_id, CLAP_PLUGIN_FACTORY_ID))
//       return &s_plugin_factory;
//    return NULL;
// }

// CLAP_EXPORT const clap_plugin_entry_t clap_entry = {
//    .clap_version = CLAP_VERSION_INIT,
//    .init = entry_init,
//    .deinit = entry_deinit,
//    .get_factory = entry_get_factory,
// };
