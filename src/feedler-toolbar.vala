/**
 * feedler-toolbar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Toolbar : Gtk.Toolbar
{
	internal Gtk.ToolButton back = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_BACK);
    internal Gtk.ToolButton forward = new Gtk.ToolButton.from_stock (Gtk.Stock.GO_FORWARD);
	internal Gtk.ToolButton update = new Gtk.ToolButton.from_stock (Gtk.Stock.REFRESH);
    internal Gtk.ToolButton mark = new Gtk.ToolButton.from_stock (Gtk.Stock.APPLY);
    internal Gtk.ToolButton add_new = new Gtk.ToolButton.from_stock (Gtk.Stock.ADD);
    
    internal Gtk.CheckMenuItem sidebar_visible = new Gtk.CheckMenuItem.with_label ("Sidebar visible");
    internal Gtk.MenuItem import_feeds = new Gtk.MenuItem.with_label ("Import subscriptions");
    internal Gtk.MenuItem export_feeds = new Gtk.MenuItem.with_label ("Export subscriptions");
    internal Gtk.MenuItem about_program = new Gtk.MenuItem.with_label ("About");
    
    //internal Granite.Widgets.ModeButton mode;
    internal Granite.Widgets.ModeButtonMarlin mode;
    internal Granite.Widgets.SearchBar search = new Granite.Widgets.SearchBar ("Type to search..");
    
	construct
	{
		this.get_style_context().add_class("primary-toolbar");
		sidebar_visible.active = true;
        Gtk.Menu menu = new Gtk.Menu ();
        menu.append (import_feeds);
        menu.append (export_feeds);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (sidebar_visible);
        menu.append (new Gtk.SeparatorMenuItem ());
        menu.append (about_program);
        
        Granite.Widgets.AppMenu appmenu = new Granite.Widgets.AppMenu (menu);
        
        this.mode = new Granite.Widgets.ModeButtonMarlin ();
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-compact-symbolic", Gtk.IconSize.MENU));
        this.mode.append (new Gtk.Image.from_icon_name ("view-list-details-symbolic", Gtk.IconSize.MENU));
        Gtk.ToolItem mode_item = new Gtk.ToolItem ();
        mode_item.set_border_width (5);
        mode_item.add (mode);
        Gtk.ToolItem search_item = new Gtk.ToolItem ();
        search_item.add (search);
        
        var separator = new Gtk.SeparatorToolItem ();
		separator.set_expand (true);
		separator.draw = false;
        
        this.insert (back, 0);
        this.insert (forward, 1);
        this.insert (update, 2);
        this.insert (mark, 3);
        this.insert (add_new, 4);
        this.insert (separator, 5);
        this.insert (search_item, 6);
        this.insert (mode_item, 7);
        this.insert (appmenu, 8);
	}
}
