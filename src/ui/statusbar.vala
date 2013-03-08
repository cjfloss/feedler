/**
 * statusbar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Statusbar : Granite.Widgets.StatusBar
{
	internal Feedler.StatusMenuButton add_feed;	
	internal Feedler.StatusButton mark_feed;
	internal Feedler.StatusButton next_feed;

	public Statusbar ()
	{
		this.add_feed = new Feedler.StatusMenuButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU), _("Add new.."));
		this.mark_feed = new Feedler.StatusButton (new Gtk.Image.from_gicon (Feedler.Icons.MARK, Gtk.IconSize.MENU), _("Mark all items as read"));
		this.next_feed = new Feedler.StatusButton (new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU), _("Go to the channel with unread items"));
        this.insert_widget (add_feed, true);
		this.insert_widget (mark_feed, true);
		this.insert_widget (next_feed, false);
	}

	public void counter (uint count)
	{
		if (count > 0)
		{
			string description = count > 1 ? _("unread feeds") : _("unread feed");
			this.set_text ("%u %s".printf (count, description));
		}
		else
			this.set_text ("");
	}
}

public class Feedler.StatusButton : Gtk.EventBox
{
	public StatusButton (Gtk.Image icon, string? tooltip = null)
    {
		this.add (icon);
		this.tooltip_text = tooltip;
		this.above_child = true;
		this.visible_window = false;
        this.show_all ();
	}
}

private class Feedler.StatusMenuButton : Gtk.EventBox
{
	private Gtk.Menu menu;
	internal Gtk.MenuItem folder;
	internal Gtk.MenuItem subscription;
	internal Gtk.MenuItem import;

	public StatusMenuButton (Gtk.Image icon, string? tooltip = null)
	{
		this.add (icon);
		this.tooltip_text = tooltip;
		this.above_child = true;
		this.visible_window = false;		

		this.folder = new Gtk.MenuItem.with_label (_("Add new folder"));
		this.subscription = new Gtk.MenuItem.with_label (_("Add new subscription"));
		this.import = new Gtk.MenuItem.with_label (_("Import subscription from file"));

		this.menu = new Gtk.Menu ();
		this.menu.attach_widget = this;
		this.menu.append (folder);
		this.menu.append (subscription);
		this.menu.append (import);
		this.menu.show_all ();
	}

	public override bool button_press_event (Gdk.EventButton event)
	{
		if (event.type == Gdk.EventType.BUTTON_PRESS)
		{
			menu.popup (null, null, null, Gdk.BUTTON_SECONDARY, event.time);
			return true;
		}
		return false;
	}
}

/*public class Feedler.StatusButton : Gtk.EventBox
{
	Gtk.Image icon;

	public StatusButton.from_pixbuf (Gdk.Pixbuf icon)
    {
		this.icon = new Gtk.Image.from_pixbuf (icon);
        this.initialize ();
	}

	public StatusButton.from_image (Gtk.Image icon)
    {
		this.icon = icon;
		this.initialize ();
	}

	private void initialize ()
    {
		this.set_above_child (true);
		this.set_visible_window (false);
        this.add (this.icon);
        this.show_all ();
	}

	public void set_tooltip (string tooltip)
    {
		this.icon.set_tooltip_text (tooltip);
	}
}

public class Feedler.Statusbar : Granite.Widgets.StatusBar
{
    internal Feedler.StatusButton add_feed;
    internal Feedler.StatusButton delete_feed;
    internal Feedler.StatusButton import_feed;
    internal Feedler.StatusButton next_feed;
    internal Feedler.StatusButton mark_feed;

    public Statusbar ()
    {
        this.add_feed = new Feedler.StatusButton.from_image (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU));
        this.add_feed.set_tooltip (_("Add new subscription URL"));

        this.delete_feed = new Feedler.StatusButton.from_image (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.MENU));
        this.delete_feed.set_tooltip (_("Remove selected subscription"));

		this.import_feed = new Feedler.StatusButton.from_image (new Gtk.Image.from_icon_name ("edit-undo-symbolic", Gtk.IconSize.MENU));
        this.import_feed.set_tooltip (_("Import subscription from OPML"));

		this.next_feed = new Feedler.StatusButton.from_image (new Gtk.Image.from_icon_name ("go-jump-symbolic", Gtk.IconSize.MENU));
        this.next_feed.set_tooltip (_("Go to the channel with unread items"));
		
		this.mark_feed = new Feedler.StatusButton.from_image (new Gtk.Image.from_icon_name ("folder-documents-symbolic", Gtk.IconSize.MENU));
        this.mark_feed.set_tooltip (_("Mark all items as read"));

        this.insert_widget (this.add_feed, true);
        this.insert_widget (this.delete_feed, true);
        //this.insert_widget (this.import_feed, true);
        this.insert_widget (this.mark_feed, false);
        this.insert_widget (this.next_feed, false);
    }

	public void counter (uint count)
	{
		if (count > 0)
        {
			string description = count > 1 ? _("unread feeds") : _("unread feed");
	        this.set_text ("%u %s".printf (count, description));
        }
		else
			this.set_text ("");
	}
}*/
