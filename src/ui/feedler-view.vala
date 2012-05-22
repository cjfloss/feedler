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
	
	public static WebKit.WebSettings settings;
	
	static construct
	{
		settings = new WebKit.WebSettings ();
		settings.auto_resize_window = false;
		settings.default_font_size = 9;
		settings.auto_load_images = Feedler.SETTING.enable_image;
		settings.auto_shrink_images = Feedler.SETTING.shrink_image;
	}

	construct
	{
		this.set_shadow_type (Gtk.ShadowType.NONE);
	}
		
	public abstract void clear ();
	
	public abstract void add_feed (Model.Item item, string time_format);
	
	public abstract void load_feeds ();
	
	public abstract void refilter (string text);
	
	public abstract void select (Gtk.TreePath path);

	public abstract void change ();

    public abstract int to_type ();
}
