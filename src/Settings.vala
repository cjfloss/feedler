/**
 * settings.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.State : Granite.Services.Settings {
    public int window_width { get; set; }
    public int window_height { get; set; }
    public int sidebar_width { get; set; }
    public int view_mode { get; set; }

    public State () {
        base ("com.github.cjfloss.feedler.state");
    }
}

public class Feedler.Settings : Granite.Services.Settings {
    public bool enable_image { get; set; }
    public bool enable_script { get; set; }
    public bool enable_java { get; set; }
    public bool enable_plugin { get; set; }
    public bool shrink_image { get; set; }
    public int browser_id { get; set; }
    public string browser_name { get; set; }
    public bool hide_close { get; set; }
    public bool hide_start { get; set; }
    public bool hide_header { get; set; }
    public int limit_items { get; set; }

    public Settings () {
        base ("com.github.cjfloss.feedler.settings");
    }
}

public class Feedler.Service : Granite.Services.Settings {
    public bool auto_update { get; set; }
    public bool start_update { get; set; }
    public int update_time { get; set; }
    public string[] uri { get; set; }

    public Service () {
        base ("com.github.cjfloss.feedler.service");
    }
}