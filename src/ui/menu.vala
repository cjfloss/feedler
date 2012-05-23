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

public class Feedler.MenuView : Gtk.Menu
{
    internal Gtk.MenuItem disp = new Gtk.MenuItem.with_label (_("Display"));
    internal Gtk.MenuItem open = new Gtk.MenuItem.with_label (_("Open in browser"));
    internal Gtk.MenuItem read = new Gtk.MenuItem.with_label (_("Mark as read"));
	internal Gtk.MenuItem unre = new Gtk.MenuItem.with_label (_("Mark as unread"));
    
	construct
	{
        this.append (disp);
        this.append (open);
        this.append (new Gtk.SeparatorMenuItem ());
        this.append (read);
        this.append (unre);
	}

	public void select_mark (bool type)
	{
		if (type)
		{
			this.read.set_sensitive (true);
			this.unre.set_sensitive (false);
		}
		else
		{
			this.read.set_sensitive (false);
			this.unre.set_sensitive (true);
		}
	}
}
