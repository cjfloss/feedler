/**
 * statusbar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.StatusButton : Gtk.EventBox
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
}
