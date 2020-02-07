/**
 * preferences.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

private class PreferenceTab : Gtk.Grid {
    private int id;

    public PreferenceTab () {
        Object (border_width: 5, row_spacing: 8, column_spacing: 12);
        this.id = 0;
    }

    public void add_title (string title) {
        var label = new Gtk.Label (null);
        label.set_markup ("<b>%s</b>".printf (title));
        label.set_halign (Gtk.Align.START);

        if (id > 0) {
            label.margin_top = 15;
        }

        this.attach (label, 0, id++, 2, 1);
    }

    public void add_content (Gtk.Widget widget, string description) {
        var label = new Gtk.Label (description);
        label.halign = Gtk.Align.END;
        widget.halign = Gtk.Align.START;
        widget.margin_end = 15;
        this.attach (label, 0, id, 1, 1);
        this.attach (widget, 1, id++, 1, 1);
    }
}

private class Behavior : PreferenceTab {
    private Gtk.ComboBoxText browser_id;
    private Gtk.Entry browser_name;
    construct {
        var enable_image = new Gtk.Switch ();
        var enable_script = new Gtk.Switch ();
        var enable_java = new Gtk.Switch ();
        var enable_plugin = new Gtk.Switch ();
        var shrink_image = new Gtk.Switch ();
        browser_id = new Gtk.ComboBoxText ();
        browser_id.append ("xdg-open", _("Automatic"));
        browser_id.append ("firefox", _("Mozilla Firefox"));
        browser_id.append ("midori", _("Midori"));
        browser_id.append ("chromium", _("Chromium"));
        browser_id.append ("chrome", _("Google Chrome"));
        browser_id.append ("opera", _("Opera"));
        browser_id.append ("", _("Manual"));
        browser_name = new Gtk.Entry ();
        browser_id.changed.connect ((e) =>
        {
            if (browser_id.active_id == "")
                browser_name.set_sensitive (true);
            else {
                browser_name.set_sensitive (false);
            }
        });

        Feedler.SETTING.schema.bind ("enable-image", enable_image, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("enable-script", enable_script, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("enable-java", enable_java, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("enable-plugin", enable_plugin, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("shrink-image", shrink_image, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("browser-id", browser_id, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("browser-name", browser_name, "text", SettingsBindFlags.DEFAULT);

        if (browser_id.active_id != "") {
            browser_name.set_sensitive (false);
        }

        this.add_title (_("Content:"));
        this.add_content (enable_image, _("Enable images:"));
        this.add_content (shrink_image, _("Shrink image to fit:"));
        this.add_content (enable_plugin, _("Enable plugins:"));
        this.add_content (enable_script, _("Enable JavaScripts:"));
        this.add_content (enable_java, _("Enable Java:"));
        this.add_title (_("Browser:"));
        this.add_content (browser_id, _("Open links in:"));
        this.add_content (browser_name, _("Manual command:"));
    }
}

private class UserInterface : PreferenceTab {
    construct {
        var hide_close = new Gtk.Switch ();
        var hide_start = new Gtk.Switch ();
        var hide_header = new Gtk.Switch ();
        var limit_items = new Gtk.SpinButton.with_range (0, 200, 10); // 0 => no limit
        Feedler.SETTING.schema.bind ("hide-close", hide_close, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("hide-start", hide_start, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("hide-header", hide_header, "active", SettingsBindFlags.DEFAULT);
        Feedler.SETTING.schema.bind ("limit-items", limit_items, "value", SettingsBindFlags.DEFAULT);

        this.add_title (_("Window:"));
        this.add_content (hide_close, _("Hiding window instead of closing:"));
        this.add_content (hide_start, _("Hide on start to the messaging menu:"));

        this.add_title (_("Application:"));
        this.add_content (hide_header, _("Hide additional headers in sidebar:"));
        this.add_content (limit_items, _("Maximum items stored in the channel:"));
    }
}

private class Update : PreferenceTab {
    internal Gtk.Button fav;
    construct {
        var auto_update = new Gtk.Switch ();
        var start_update = new Gtk.Switch ();
        var update_time = new Gtk.SpinButton.with_range (5, 90, 5);
        Feedler.SERVICE.schema.bind ("auto-update", auto_update, "active", SettingsBindFlags.DEFAULT);
        Feedler.SERVICE.schema.bind ("start-update", start_update, "active", SettingsBindFlags.DEFAULT);
        Feedler.SERVICE.schema.bind ("update-time", update_time, "value", SettingsBindFlags.DEFAULT);

        this.fav = new Gtk.Button ();
        this.fav.set_image (new Gtk.Image.from_icon_name ("go-bottom-symbolic", Gtk.IconSize.MENU));
        this.add_title (_("Subscriptions:"));
        this.add_content (auto_update, _("Enable automatic updates:"));
        this.add_content (start_update, _("Enable updates on start:"));
        this.add_content (update_time, _("Time interval between updates:"));
        this.add_title (_("Favicons:"));
        this.add_content (fav, _("Download now all favicons:"));
    }
}

public class Feedler.Preferences : Gtk.Dialog {
    private Gtk.StackSwitcher stack_switcher;
    private Gtk.Stack stack;
    private Gtk.Box content;

    internal Behavior behavior;
    internal UserInterface uinterface;
    internal Update update;

    public Preferences () {
        Object (title: _("Preferences"), window_position: Gtk.WindowPosition.CENTER_ON_PARENT, modal: true, destroy_with_parent: true, border_width: 12, use_header_bar: 1, resizable: false);

        this.behavior = new Behavior ();
        this.uinterface = new UserInterface ();
        this.update = new Update ();

        this.stack_switcher = new Gtk.StackSwitcher ();
        this.stack = new Gtk.Stack ();
        stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);
        stack_switcher.set_stack (stack);
        stack.add_titled (uinterface, "interface", _("Interface"));
        stack.add_titled (behavior, "behavior", _("Behavior"));
        stack.add_titled (update, "updates", _("Updates"));

        this.content = (Gtk.Box) this.get_content_area ();
        this.content.add (stack);
        ((Gtk.HeaderBar) this.get_header_bar ()).set_custom_title (stack_switcher);

        this.show_all ();
    }
}