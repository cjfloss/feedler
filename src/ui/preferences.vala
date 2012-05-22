/**
 * preferences.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Behavior : Gtk.VBox
{
	construct
	{
		this.border_width = 5;		
		var enable_image = new Gtk.CheckButton.with_label ("Enable images");
		var enable_script = new Gtk.CheckButton.with_label ("Enable scripts");
		var enable_java = new Gtk.CheckButton.with_label ("Enable java");
		var enable_plugin = new Gtk.CheckButton.with_label ("Enable plugins");
		var shrink_image = new Gtk.CheckButton.with_label ("Shrink image to fit");

		Feedler.SETTING.schema.bind ("enable-image", enable_image, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-script", enable_script, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-java", enable_java, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-plugin", enable_plugin, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("shrink-image", shrink_image, "active", SettingsBindFlags.DEFAULT);
		
		this.pack_start (enable_image, false, true, 3);
		this.pack_start (enable_script, false, true, 3);
		this.pack_start (enable_java, false, true, 3);
		this.pack_start (enable_plugin, false, true, 3);
		this.pack_start (shrink_image, false, true, 3);
	}
}
 
public class Feedler.Preferences : Gtk.Dialog
{
	private Granite.Widgets.StaticNotebook tabs;
	private Gtk.Box vbox;
	internal Gtk.Button fav;
	
	construct
	{
		this.title = "Preferences";
        this.border_width = 5;
		this.set_default_size (300, 300);
        this.fav = new Gtk.Button.with_label ("Update favicons");
		this.tabs = new Granite.Widgets.StaticNotebook ();
		this.tabs.append_page (new Behavior (), new Gtk.Label (_("Behavior")));
		this.tabs.append_page (fav, new Gtk.Label ("Other"));
		
        this.vbox = this.get_content_area () as Gtk.Box;
        this.vbox.pack_start (this.tabs, false, true, 0);

        this.add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
		this.show_all ();
    }
}
