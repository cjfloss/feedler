/**
 * feedler-view.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
public abstract class Feedler.View : Gtk.Viewport
{
	public signal void item_readed (int item_id);
	public signal void item_selected (string item_path);
	public signal void item_browsed ();

	construct
	{
		this.set_shadow_type (Gtk.ShadowType.NONE);
	}
		
	public abstract void clear ();
	
	public abstract void add_feed (Feedler.Item item, string time_format);
	
	public abstract void load_feeds ();
	
	public abstract void refilter (string text);
	
	public abstract void load_settings ();
	
	public abstract void select (Gtk.TreePath path);
}
