/**
 * menu.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.MenuSide : Gtk.Menu
{
    internal Gtk.Menu news = new Gtk.Menu ();
    internal Gtk.MenuItem upd = new Gtk.MenuItem.with_label (_("Update"));
    internal Gtk.MenuItem mark = new Gtk.MenuItem.with_label (_("Mark as read"));
    internal Gtk.MenuItem rem = new Gtk.MenuItem.with_label (_("Delete"));
    internal Gtk.MenuItem edit = new Gtk.MenuItem.with_label (_("Properties"));
    internal Gtk.MenuItem anew = new Gtk.MenuItem.with_label (_("New"));
    internal Gtk.MenuItem add_sub = new Gtk.MenuItem.with_label (_("Subscription"));
    internal Gtk.MenuItem add_fol = new Gtk.MenuItem.with_label (_("Folder"));
    
	construct
	{
        this.news.append (add_sub);
        this.news.append (add_fol);
        this.anew.set_submenu (news);

        this.append (anew);
        this.append (new Gtk.SeparatorMenuItem ());
        this.append (upd);
        this.append (mark);
        this.append (rem);
        this.append (new Gtk.SeparatorMenuItem ());
        this.append (edit);
	}
}
