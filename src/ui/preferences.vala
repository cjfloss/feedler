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
		var p_label = new Gtk.Label ("");
        p_label.set_markup ("<b>%s</b>".printf (_("Content")));
        p_label.set_halign (Gtk.Align.START);
		var p_grid = new Gtk.Grid ();
		p_grid.row_spacing = 8;
		p_grid.column_spacing = 12;
		var enable_image = new Gtk.CheckButton.with_label (_("Enable images"));
		var enable_script = new Gtk.CheckButton.with_label (_("Enable scripts"));
		var enable_java = new Gtk.CheckButton.with_label (_("Enable java"));
		var enable_plugin = new Gtk.CheckButton.with_label (_("Enable plugins"));
		var shrink_image = new Gtk.CheckButton.with_label (_("Shrink image to fit"));

		Feedler.SETTING.schema.bind ("enable-image", enable_image, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-script", enable_script, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-java", enable_java, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-plugin", enable_plugin, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("shrink-image", shrink_image, "active", SettingsBindFlags.DEFAULT);
		
		p_grid.attach (enable_plugin, 0, 0, 1, 1);
		p_grid.attach (enable_script, 0, 1, 1, 1);
		p_grid.attach (enable_java, 0, 2, 1, 1);
		p_grid.attach (enable_image, 1, 0, 1, 1);
		p_grid.attach (shrink_image, 1, 1, 1, 1);

		this.pack_start (p_label, false, true, 3);
		this.pack_start (p_grid, false, true, 3);
	}
}

public class Update : Gtk.VBox
{
	internal Gtk.Button fav;
	construct
	{
		this.border_width = 5;		
        this.fav = new Gtk.Button.with_label (_("Update favicons"));
		
		this.pack_start (fav, false, true, 3);
	}
}

public class Other : Gtk.VBox
{
	internal Gtk.Button fav;
	construct
	{
		this.border_width = 5;		
        this.fav = new Gtk.Button.with_label (_("Update favicons"));
		
		this.pack_start (fav, false, true, 3);
	}
}
 
public class Feedler.Preferences : Gtk.Dialog
{
	private Granite.Widgets.StaticNotebook tabs;
	private Gtk.Box content;
	private Behavior behavior;
	private Update update;
	internal Other other;
	
	construct
	{
		this.title = _("Preferences");
        this.border_width = 5;
		this.set_resizable (false);
		this.tabs = new Granite.Widgets.StaticNotebook ();
		this.behavior = new Behavior ();
		this.update = new Update ();
		this.other = new Other ();
		this.tabs.append_page (behavior, new Gtk.Label (_("Behavior")));
		this.tabs.append_page (update, new Gtk.Label (_("Update")));
		this.tabs.append_page (other, new Gtk.Label (_("Other")));
		
        this.content = this.get_content_area () as Gtk.Box;
        this.content.pack_start (tabs, false, true, 0);

        this.add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
		this.show_all ();
    }
}
