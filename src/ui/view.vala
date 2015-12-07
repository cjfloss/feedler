/**
 * view.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public abstract class Feedler.View : Gtk.VBox
{
	public signal void item_marked (int id, Model.State state);
	
	public static WebKit.WebSettings settings;
	
	static construct
	{
		settings = new WebKit.WebSettings ();
		settings.auto_resize_window = false;
		settings.default_font_size = 9;
		settings.auto_load_images = Feedler.SETTING.enable_image;
		settings.auto_shrink_images = Feedler.SETTING.shrink_image;
		settings.enable_plugins = Feedler.SETTING.enable_plugin;
		settings.enable_scripts = Feedler.SETTING.enable_script;
		settings.enable_java_applet = Feedler.SETTING.enable_java;
	}

	public abstract void clear ();
	
	public abstract void add_feed (Model.Item item, string time_format);
	
	public abstract void load_feeds ();
	
	public abstract void refilter (string text);

	public abstract bool contract ();

	protected string generate_style (string title_color, string time_color, string content_color, string link_color)
	{
		return """<!DOCTYPE HTML><style>.title{color:%s;} .time{color:%s;} .content{color:%s;} a,a:link,a:visited{color:%s;}</style>""".printf (title_color, time_color, content_color, link_color);
	}
}
