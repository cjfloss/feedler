/**
 * toolbar.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Progress : Gtk.Box {
    private Gtk.ProgressBar bar;
    private Gtk.Label label;

    construct {
        this.set_orientation (Gtk.Orientation.VERTICAL);
        this.bar = new Gtk.ProgressBar ();
        this.bar.width_request = 300;
        this.label = new Gtk.Label (null);
        this.label.set_justify (Gtk.Justification.CENTER);
        this.label.set_single_line_mode (true);
        this.label.ellipsize = Pango.EllipsizeMode.END;

        this.pack_start (label, false, false, 0);
        this.pack_end (bar, false, false, 0);
        this.set_no_show_all (true);
        this.hide ();
    }

    public void show_bar (string text) {
        this.label.set_text (text);
        this.set_no_show_all (false);
        this.show_all ();
    }

    public void hide_bar () {
        this.bar.fraction = 0.0;
        this.set_no_show_all (true);
        this.hide ();
    }

    public void proceed (double fraction) {
        this.bar.set_fraction (fraction);
    }

}

public class Feedler.Toolbar : Gtk.HeaderBar {
    internal Gtk.Button update = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.MENU);

    public Progress progress = new Progress ();
    internal Granite.Widgets.ModeButton mode = new Granite.Widgets.ModeButton ();
    internal Gtk.SearchEntry search = new Gtk.SearchEntry ();

    internal Gtk.CheckMenuItem sidebar_visible = new Gtk.CheckMenuItem.with_label (_("Sidebar Visible"));
    internal Gtk.CheckMenuItem fullscreen_mode = new Gtk.CheckMenuItem.with_label (_("Fullscreen"));
    internal Gtk.MenuItem preferences = new Gtk.MenuItem.with_label (_("Preferences"));

    construct {
        this.sidebar_visible.active = true;
        this.get_style_context ().add_class (Gtk.STYLE_CLASS_TITLEBAR);
        this.set_show_close_button (true);

        Gtk.Menu menu = new Gtk.Menu ();
        menu.append (sidebar_visible);
        menu.append (fullscreen_mode);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences);
        menu.show_all ();

        var setting = new Gtk.MenuButton ();
        setting.set_image (new Gtk.Image.from_icon_name ("application-menu", Gtk.IconSize.MENU));
        setting.set_popup (menu);

        this.mode.append (new Gtk.Image.from_icon_name ("view-list-compact-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-column-symbolic", Gtk.IconSize.MENU));
        Gtk.ToolItem mode_item = new Gtk.ToolItem ();
        mode_item.add (mode);

        search.set_placeholder_text (_("Type to Search"));
        Gtk.ToolItem search_item = new Gtk.ToolItem ();
        search_item.add (search);
        this.set_custom_title (progress);

        this.update.tooltip_text = _("Refresh all subscriptions");
        setting.tooltip_text = _("Menu");

        var btt = new Gtk.Button ();
        btt.always_show_image = true;
        btt.image = new Gtk.Image.from_gicon (Feedler.Icons.SIDEBAR, Gtk.IconSize.MENU);

        this.pack_start (new Gtk.Button.from_icon_name ("news-subscribe", Gtk.IconSize.MENU));
        this.pack_start (btt);
        this.pack_start (update);
        this.pack_start (mode_item);
        this.pack_start (new Gtk.Button.from_icon_name ("view-dual-symbolic", Gtk.IconSize.MENU));
        this.pack_start (new Gtk.Button.from_icon_name ("view-left-close", Gtk.IconSize.MENU));
        this.pack_start (new Gtk.Button.from_icon_name ("view-right-new", Gtk.IconSize.MENU));
        this.pack_start (new Gtk.Button.from_icon_name ("builder-view-left-pane-symbolic", Gtk.IconSize.MENU));
        this.pack_start (new Gtk.Button.from_icon_name ("view-sidebar-symbolic", Gtk.IconSize.MENU));

        this.pack_end (setting);
        this.pack_end (search_item);

        this.pack_end (new Gtk.Button.from_icon_name ("tag-new-symbolic", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("tag-symbolic", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("user-bookmarks", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("bookmark-add-symbolic", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("action-rss_tag", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("object-select-symbolic", Gtk.IconSize.MENU));

        // this.pack_end (new Gtk.Button.from_icon_name ("view-filter", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("dialog-xml-editor", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-export-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-import-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-info", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-print", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-print-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-revert", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("document-revert-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("send-to-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU));
        // this.pack_end (new Gtk.Button.from_icon_name ("go-previous-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("im-facebook", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("im-google", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("im-skype", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("im-twitter", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("im-yahoo", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("view-fullscreen", Gtk.IconSize.MENU));
        this.pack_end (new Gtk.Button.from_icon_name ("view-preview", Gtk.IconSize.MENU));

        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        // //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        // //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
        //this.pack_end (new Gtk.Button.from_icon_name ("star-new-symbolic", Gtk.IconSize.MENU));
    }

    public void set_enable (bool state) {
        this.update.set_sensitive (state);
        this.search.set_sensitive (state);
        this.mode.set_sensitive (state);
        this.sidebar_visible.set_sensitive (state);
        this.preferences.set_sensitive (state);
    }
}