/**
 * feedler-toolbar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Progress : Gtk.VBox
{
	private Gtk.ProgressBar progressbar;
	private Gtk.Label label;
	
	construct
	{
		this.progressbar = new Gtk.ProgressBar ();
		this.progressbar.set_fraction (0.01);
		this.label = new Gtk.Label ("");
		this.label.set_justify (Gtk.Justification.CENTER);
		this.label.set_single_line_mode (true);
		this.label.ellipsize = Pango.EllipsizeMode.END;
	}
	
	public void pack ()
	{
		this.pack_start (label, false, false, 0);
		this.pack_end (progressbar, false, false, 2);
	}
	
	public void set_text (string text)
	{
		this.label.set_text (text);
	}

	public void set_markup (string markup)
	{
		this.label.set_markup (markup);
	}

	public string get_text ()
	{
		return label.get_text ();
	}

	public void show_ ()
	{
		if (this.get_children ().length () == 0)
			this.pack ();

		this.label.show ();
		this.progressbar.show ();
	}
	
	public void hide_ ()
	{
		this.label.hide ();
		this.progressbar.hide ();
	}

	public void set_progress_value (double progress)
	{
		progressbar.set_fraction (progressbar.fraction + progress);
			
		if (progressbar.fraction >= 1.0)
			this.hide_ ();
	}
}

public class Feedler.Toolbar : Gtk.Toolbar
{
	internal Gtk.ToolButton back = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_BACK);
    internal Gtk.ToolButton forward = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_FORWARD);
	internal Gtk.ToolButton update = new Gtk.ToolButton.from_stock (Gtk.Stock.REFRESH);
    internal Gtk.ToolButton mark = new Gtk.ToolButton.from_stock (Gtk.Stock.APPLY);
    internal Gtk.ToolButton add_new = new Gtk.ToolButton.from_stock (Gtk.Stock.ADD);
    
    Gtk.ToolItem progress_item;
    Progress progress;    
    //internal Granite.Widgets.ModeButton mode;
    internal Granite.Widgets.ModeButtonMarlin mode;
    internal Granite.Widgets.SearchBar search = new Granite.Widgets.SearchBar ("Type to search..");
    Gtk.ToolItem mode_item;
    Gtk.ToolItem search_item;
    
    internal Granite.Widgets.AppMenu appmenu;
    internal Gtk.CheckMenuItem sidebar_visible = new Gtk.CheckMenuItem.with_label ("Sidebar visible");
    internal Gtk.MenuItem import_feeds = new Gtk.MenuItem.with_label ("Import subscriptions");
    internal Gtk.MenuItem export_feeds = new Gtk.MenuItem.with_label ("Export subscriptions");
    internal Gtk.MenuItem about_program = new Gtk.MenuItem.with_label ("About");
    
	construct
	{
		sidebar_visible.active = true;
		
        Gtk.Menu menu = new Gtk.Menu ();
        menu.append (import_feeds);
        menu.append (export_feeds);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (sidebar_visible);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (about_program);        
        this.appmenu = new Granite.Widgets.AppMenu (menu);
        
        this.mode = new Granite.Widgets.ModeButtonMarlin ();
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-compact-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-details-symbolic", Gtk.IconSize.MENU));
        this.mode_item = new Gtk.ToolItem ();
        mode_item.set_border_width (5);
        mode_item.add (mode);
        search_item = new Gtk.ToolItem ();
        search_item.add (search);
        
        var separator = new Gtk.SeparatorToolItem ();
		separator.set_expand (true);
		separator.draw = false;
		
		this.progress = new Progress ();
		this.progress_item = new Gtk.ToolItem ();
		this.progress_item.add (progress);
		//progress_item.set_border_width (5);
		progress_item.set_expand (true);
        
        this.insert (back, 0);
        this.insert (forward, 1);
        this.insert (update, 2);
        this.insert (mark, 3);
        this.insert (add_new, 4);
        this.insert (separator, 5);
        this.insert (progress_item, 6);
        this.insert (search_item, 7);
        this.insert (mode_item, 8);
        this.insert (appmenu, 9);
	}
	
	public void set_enable (bool state)
	{
		this.back.set_sensitive (state);
		this.forward.set_sensitive (state);
		this.update.set_sensitive (state);
		this.mark.set_sensitive (state);
		this.add_new.set_sensitive (state);
		
		this.search_item.set_sensitive (state);
		this.mode_item.set_sensitive (state);
		this.appmenu.set_sensitive (state);
	}
	
	public void progressbar_show ()
	{
		this.progress.show_ ();
	}
	
	public void progressbar_hide ()
	{
		this.progress.hide_ ();
	}
	
	public void progressbar_text (string text)
	{
		this.progress.set_text (text);
	}
	
	public void progressbar_progress (double value)
	{
		this.progress.set_progress_value (value);
	}
	
	public void progressbar_pack ()
	{
		this.progress.pack ();
	}
}
