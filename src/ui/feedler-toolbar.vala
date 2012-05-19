/**
 * feedler-toolbar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Progress : Gtk.VBox
{
	internal Gtk.ProgressBar progressbar;
	internal Gtk.Label label;
	
	construct
	{
		this.progressbar = new Gtk.ProgressBar ();
		this.label = new Gtk.Label (null);
		this.label.set_justify (Gtk.Justification.CENTER);
		this.label.set_single_line_mode (true);
		this.label.ellipsize = Pango.EllipsizeMode.END;
		
		this.pack_start (label, false, false, 0);
		this.pack_end (progressbar, false, false, 0);
	}
		
	public void set_progress_value (double progress)
	{
		progressbar.set_fraction (progressbar.fraction + progress);
	}
}

public class Feedler.Toolbar : Gtk.Toolbar
{
	internal Gtk.ToolButton back = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_BACK);
    internal Gtk.ToolButton forward = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_FORWARD);
	internal Gtk.ToolButton update = new Gtk.ToolButton.from_stock (Gtk.Stock.REFRESH);

    Gtk.Alignment align;
    Progress progress = new Progress ();    
    internal Granite.Widgets.ModeButton mode = new Granite.Widgets.ModeButton ();
    internal Granite.Widgets.SearchBar search = new Granite.Widgets.SearchBar (_("Type to Search..."));
    internal Gtk.ToggleButton column = new Gtk.ToggleButton ();
    
    internal Granite.Widgets.AppMenu appmenu;
    internal Gtk.CheckMenuItem sidebar_visible = new Gtk.CheckMenuItem.with_label (_("Sidebar Visible"));
    internal Gtk.CheckMenuItem fullscreen_mode = new Gtk.CheckMenuItem.with_label (_("Fullscreen"));
    internal Gtk.MenuItem import_feeds = new Gtk.MenuItem.with_label (_("Import"));
    internal Gtk.MenuItem export_feeds = new Gtk.MenuItem.with_label (_("Export"));
    internal Gtk.MenuItem preferences = new Gtk.MenuItem.with_label (_("Preferences"));
    internal Gtk.MenuItem about_program = new Gtk.MenuItem.with_label (_("About"));
    
	construct
	{
		this.sidebar_visible.active = true;
        this.get_style_context ().add_class ("primary-toolbar");
		
        Gtk.Menu menu = new Gtk.Menu ();
        menu.append (import_feeds);
        menu.append (export_feeds);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (sidebar_visible);
        menu.append (fullscreen_mode);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (preferences);
        menu.append (about_program);
        this.appmenu = new Granite.Widgets.AppMenu (menu);
        
        //this.mode = new Granite.Widgets.ModeButton ();
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-compact-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-details-symbolic", Gtk.IconSize.MENU));
        this.column.set_image (new Gtk.Image.from_icon_name ("view-list-column-symbolic", Gtk.IconSize.MENU));
        this.column.valign = Gtk.Align.CENTER;
        Gtk.ToolItem mode_item = new Gtk.ToolItem ();
		mode_item.margin = 5;
        mode_item.add (mode);
        Gtk.ToolItem column_item = new Gtk.ToolItem ();
        column_item.add (column);
        Gtk.ToolItem search_item = new Gtk.ToolItem ();
        search_item.add (search);
		
		this.progress = new Progress ();
		Gtk.ToolItem progress_item = new Gtk.ToolItem ();
		progress_item.set_expand (true);

        this.back.tooltip_text = _("Go to the previous readed item");
        this.forward.tooltip_text = _("Go to the next readed item");
        this.update.tooltip_text = _("Refresh all subscriptions");
        this.appmenu.tooltip_text = _("Menu");
        this.back.set_sensitive (false);
		this.forward.set_sensitive (false); //TODO improve history
        
        this.insert (back, 0);
        this.insert (forward, 1);
        this.insert (update, 2);
        this.insert (new Gtk.SeparatorToolItem (), 3);
        this.insert (mode_item, 4);
        this.insert (column_item, 5);
        this.insert (progress_item, 6);
        this.insert (search_item, 7);
        this.insert (appmenu, 8);

        this.align = new Gtk.Alignment (0.5f, 0.0f, 0.2f, 0.0f);
		progress_item.add (align);
		align.add (progress);
		progress_item.show_all ();
		align.set_no_show_all (true);
		align.hide ();
	}
	
	public void set_enable (bool state)
	{
		this.back.set_sensitive (state);
		this.forward.set_sensitive (state);
		this.update.set_sensitive (state);
        this.search.set_sensitive (state);
        this.mode.set_sensitive (state);
        this.column.set_sensitive (state);
		this.export_feeds.set_sensitive (state);
		this.sidebar_visible.set_sensitive (state);
	}
	
	public void progressbar_show ()
	{
		this.progress.progressbar.set_fraction (0.01);
		this.align.show ();
	}
	
	public void progressbar_hide ()
	{
		this.align.hide ();
	}
	
	public void progressbar_text (string text)
	{
		this.progress.label.set_text (text);
	}
	
	public bool progressbar_progress (double value)
	{
		this.progress.set_progress_value (value);
		if (progress.progressbar.fraction >= 1.0)
		{
			this.align.hide ();
			return true;
		}
		return false;
	}
}
