/**
 * statusbar.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Statusbar : Gtk.Statusbar {
    internal Feedler.StatusMenuButton add_feed;
    internal Feedler.StatusButton mark_feed;
    internal Feedler.StatusButton next_feed;

    public Statusbar () {
        this.add_feed = new Feedler.StatusMenuButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU), _("Add new.."));
        this.mark_feed = new Feedler.StatusButton (new Gtk.Image.from_gicon (Feedler.Icons.MARK, Gtk.IconSize.MENU), _("Mark all items as read"));
        this.next_feed = new Feedler.StatusButton (new Gtk.Image.from_icon_name ("go-next-symbolic", Gtk.IconSize.MENU), _("Go to the channel with unread items"));
        this.pack_start (add_feed);
        this.pack_start (mark_feed);
        this.pack_start (next_feed);
        //this.get_style_context ().add_class ("action-bar");
    }

    public void counter (uint count) {
        uint context_id = this.get_context_id ("example");
        if (count > 0) {
            string description = count > 1 ? _("unread feeds") : _("unread feed");
            this.push (context_id, "%u %s".printf (count, description));
        } else {
            this.push (context_id, "");
        }
    }
}

public class Feedler.StatusButton : Gtk.EventBox {
    public StatusButton (Gtk.Image icon, string ? tooltip = null) {
        this.add (icon);
        this.tooltip_text = tooltip;
        this.above_child = true;
        this.visible_window = false;
        this.show_all ();
    }
}

private class Feedler.StatusMenuButton : Gtk.EventBox {
    private Gtk.Menu menu;
    internal Gtk.MenuItem folder;
    internal Gtk.MenuItem subscription;
    internal Gtk.MenuItem import;

    public StatusMenuButton (Gtk.Image icon, string ? tooltip = null) {
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

    public override bool button_press_event (Gdk.EventButton event) {
        if (event.type == Gdk.EventType.BUTTON_PRESS) {
            menu.popup_at_pointer (event);
            return true;
        }

        return false;
    }
}