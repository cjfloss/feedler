/**
 * feedler-statusbar.vala
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
    public uint total_unreaded { get; private set; default = 0; }

    private string STATUS_TEXT_FORMAT = _("%u %s");

    public void set_unreaded (uint total_unreaded)
    {
        this.total_unreaded = total_unreaded;
        this.update_label ();
    }

    private void update_label ()
    {
        if (this.total_unreaded == 0)
        {
            status_label.set_text ("");
            return;
        }

        string description = total_unreaded > 1 ? _("unreaded feeds") : _("unreaded feed");
        this.set_text (STATUS_TEXT_FORMAT.printf (total_unreaded, description));
    }
}
