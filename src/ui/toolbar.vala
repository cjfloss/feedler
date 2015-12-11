/**
 * toolbar.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Progress : Gtk.Box
{
    private Gtk.ProgressBar bar;
    private Gtk.Label label;

    construct
    {
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

    public void show_bar (string text)
    {
        this.label.set_text (text);
        this.set_no_show_all (false);
        this.show_all ();
    }

    public void hide_bar ()
    {
        this.bar.fraction = 0.0;
        this.set_no_show_all (true);
        this.hide ();
    }

    public void proceed (double fraction)
    {
        this.bar.set_fraction (fraction);
    }

}

public class Feedler.Toolbar : Gtk.HeaderBar
{
    internal Gtk.Button update = new Gtk.Button.from_icon_name ("view-refresh-symbolic", Gtk.IconSize.LARGE_TOOLBAR);

    internal Gtk.Alignment align = new Gtk.Alignment (0.5f, 0.0f, 0.2f, 0.0f);
    public Progress progress = new Progress ();
    internal Granite.Widgets.ModeButton mode = new Granite.Widgets.ModeButton ();
    internal Gtk.SearchEntry search = new Gtk.SearchEntry ();

    internal Granite.Widgets.AppMenu appmenu;
    //internal Feedler.ContractorButton sharemenu;
    internal Gtk.CheckMenuItem sidebar_visible = new Gtk.CheckMenuItem.with_label (_("Sidebar Visible"));
    internal Gtk.CheckMenuItem fullscreen_mode = new Gtk.CheckMenuItem.with_label (_("Fullscreen"));
    internal Gtk.MenuItem preferences = new Gtk.MenuItem.with_label (_("Preferences"));

    construct
    {
        this.sidebar_visible.active = true;
        this.get_style_context ().add_class ("primary-toolbar");
    this.get_style_context ().add_class ("header-bar");
        this.set_show_close_button (true);


        Gtk.Menu menu = new Gtk.Menu ();
        menu.append (sidebar_visible);
        menu.append (fullscreen_mode);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences);
        this.appmenu = Feedler.APP.create_appmenu (menu);
        //this.sharemenu = new Feedler.ContractorButton ();

        this.mode.append (new Gtk.Image.from_icon_name ("view-list-compact-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-column-symbolic", Gtk.IconSize.MENU));
        Gtk.ToolItem mode_item = new Gtk.ToolItem ();
        mode_item.margin = 5;
        mode_item.add (mode);
        Gtk.ToolItem search_item = new Gtk.ToolItem ();
        search_item.add (search);
        //Gtk.ToolItem progress_item = new Gtk.ToolItem ();
        //progress_item.set_expand (true);
        //progress_item.add (align);
        this.set_custom_title (progress);

        this.update.tooltip_text = _("Refresh all subscriptions");
        this.appmenu.tooltip_text = _("Menu");






        //this.add (sharemenu);
        this.pack_start (update);
        //this.pack_start (new Gtk.SeparatorToolItem ());
        this.pack_start (mode_item);
        //this.pack_start (progress_item);



        this.pack_end (appmenu);
        this.pack_end (search_item);
    }

    public void set_enable (bool state)
    {
        this.update.set_sensitive (state);
        this.search.set_sensitive (state);
        this.mode.set_sensitive (state);
        this.sidebar_visible.set_sensitive (state);
        this.preferences.set_sensitive (state);
        //this.sharemenu.set_sensitive (state);
    }
}
