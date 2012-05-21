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
	Gtk.CheckButton shrink_image;
	
	construct
	{
		this.border_width = 5;		
		this.enable_image = new Gtk.CheckButton.with_label ("Enable images");
		this.enable_script = new Gtk.CheckButton.with_label ("Enable scripts");
		this.enable_java = new Gtk.CheckButton.with_label ("Enable java");
		this.enable_plugin = new Gtk.CheckButton.with_label ("Enable plugins");
		this.shrink_image = new Gtk.CheckButton.with_label ("Shrink image to fit");		
		this.enable_image.active = Feedler.View.settings.auto_load_images;
		this.enable_script.active = Feedler.View.settings.enable_scripts;
		this.enable_java.active = Feedler.View.settings.enable_java_applet;
		this.enable_plugin.active = Feedler.View.settings.enable_plugins;
		this.shrink_image.active = Feedler.View.settings.auto_shrink_images;
		
		this.pack_start (enable_image, false, true, 3);
		this.pack_start (enable_script, false, true, 3);
		this.pack_start (enable_java, false, true, 3);
		this.pack_start (enable_plugin, false, true, 3);
		this.pack_start (shrink_image, false, true, 3);
	}
	
	public void save ()
	{
		Feedler.View.settings.auto_load_images = this.enable_image.active;
		Feedler.View.settings.enable_scripts = this.enable_script.active;
		Feedler.View.settings.enable_java_applet = this.enable_java.active;
		Feedler.View.settings.enable_plugins = this.enable_plugin.active;
		Feedler.View.settings.auto_shrink_images = this.shrink_image.active;
	}
}
 
public class Feedler.Preferences : Gtk.Dialog
{
	private Granite.Widgets.StaticNotebook tabs;
	private Gtk.Box vbox;
	internal PrefView web;
	internal Gtk.Button fav;
	
	construct
	{
		this.title = "Preferences";
        this.border_width = 5;
		this.set_default_size (300, 300);
        this.web = new PrefView ();
        this.fav = new Gtk.Button.with_label ("Update favicons");
		this.tabs = new Granite.Widgets.StaticNotebook ();
		this.tabs.append_page (web, new Gtk.Label ("Views"));
		this.tabs.append_page (fav, new Gtk.Label ("Other"));
		
        this.vbox = this.get_content_area () as Gtk.Box;
        this.vbox.pack_start (this.tabs, false, true, 0);

        this.add_button (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
        this.add_button (Gtk.Stock.APPLY, Gtk.ResponseType.APPLY);
		this.show_all ();
    }
    
    public void save ()
	{
		web.save ();
	}
}
