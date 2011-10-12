/**
 * feedler-preferences.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class PrefView : Gtk.VBox
{
	Gtk.CheckButton enable_image;
	Gtk.CheckButton enable_script;
	Gtk.CheckButton enable_java;
	Gtk.CheckButton enable_plugin;
	
	construct
	{
		this.border_width = 5;
		this.enable_image = new Gtk.CheckButton.with_label ("Enable images");
		this.enable_script = new Gtk.CheckButton.with_label ("Enable scripts");
		this.enable_java = new Gtk.CheckButton.with_label ("Enable java");
		this.enable_plugin = new Gtk.CheckButton.with_label ("Enable plugins");
		
		this.enable_image.active = Feedler.Pref.enable_image;
		this.enable_script.active = Feedler.Pref.enable_script;
		this.enable_java.active = Feedler.Pref.enable_java;
		this.enable_plugin.active = Feedler.Pref.enable_plugin;
		
		this.pack_start (enable_image, false, true, 5);
		this.pack_start (enable_script, false, true, 5);
		this.pack_start (enable_java, false, true, 5);
		this.pack_start (enable_plugin, false, true, 5);
	}
	
	public void save ()
	{
		Feedler.Pref.enable_image = this.enable_image.active;
		Feedler.Pref.enable_script = this.enable_script.active;
		Feedler.Pref.enable_java = this.enable_java.active;
		Feedler.Pref.enable_plugin = this.enable_plugin.active;
	}
}

public class Feedler.Pref
{
	public static bool enable_image = true;
	public static bool enable_script = true;
	public static bool enable_java = true;
	public static bool enable_plugin = true;
}
 
public class Feedler.Preferences : Gtk.Dialog
{
	public signal void favicons ();
	private Granite.Widgets.StaticNotebook tabs;
	private Gtk.Box vbox;
	internal PrefView web;
	internal Gtk.Button fav;
	
	construct
	{
		this.title = "Preferences";
        this.border_width = 5;
        this.web = new PrefView ();
        this.fav = new Gtk.Button.with_label ("Update favicons");
		this.tabs = new Granite.Widgets.StaticNotebook ();
		this.tabs.append_page (web, new Gtk.Label ("Views"));
		this.tabs.append_page (fav, new Gtk.Label ("Other"));
		
		this.fav.clicked.connect (() => {this.favicons ();});
        this.vbox = this.get_content_area () as Gtk.Box;
        this.vbox.pack_start (this.tabs, false, true, 0);

        this.add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
        this.add_button (Gtk.Stock.APPLY, Gtk.ResponseType.APPLY);
		this.show_all ();
    }
    
    public void save ()
	{
		web.save ();
	}
}
