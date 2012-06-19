/**
 * preferences.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class PreferenceTab : Gtk.Grid
{
	private int id;

	construct
	{
		this.id = 0;
		this.border_width = 5;
		this.row_spacing = 8;
		this.column_spacing = 12;
	}

	public void add_title (string title)
	{
		var label = new Gtk.Label (null);
		label.set_markup ("<b>%s</b>".printf (title));
        label.set_halign (Gtk.Align.START);
		if (id > 0)
			label.margin_top = 15;
		this.attach (label, 0, id++, 2, 1);
	}

	public void add_content (Gtk.Widget widget, string description)
	{
		var label = new Gtk.Label (description);
		label.halign = Gtk.Align.END;
		widget.halign = Gtk.Align.START;
		widget.margin_right = 15;
		this.attach (label, 0, id, 1, 1);
		this.attach (widget, 1, id++, 1, 1);
	}
}

public class Behavior : PreferenceTab
{
	construct
	{
		var enable_image = new Gtk.CheckButton ();
		var enable_script = new Gtk.CheckButton ();
		var enable_java = new Gtk.CheckButton ();
		var enable_plugin = new Gtk.CheckButton ();
		var shrink_image = new Gtk.CheckButton ();
		var hide_close = new Gtk.Switch ();
		var hide_start = new Gtk.Switch ();
		Feedler.SETTING.schema.bind ("enable-image", enable_image, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-script", enable_script, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-java", enable_java, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("enable-plugin", enable_plugin, "active", SettingsBindFlags.DEFAULT);
		Feedler.SETTING.schema.bind ("shrink-image", shrink_image, "active", SettingsBindFlags.DEFAULT);
		Feedler.STATE.schema.bind ("hide-close", hide_close, "active", SettingsBindFlags.DEFAULT);
		Feedler.STATE.schema.bind ("hide-start", hide_start, "active", SettingsBindFlags.DEFAULT);
		
		this.add_title (_("Content:"));
		this.add_content (enable_image, _("Enable images:"));
		this.add_content (shrink_image, _("Shrink image to fit:"));
		this.add_content (enable_plugin, _("Enable plugins:"));
		this.add_content (enable_script, _("Enable JavaScripts:"));
		this.add_content (enable_java, _("Enable Java:"));
		this.add_title (_("Window:"));
		this.add_content (hide_close, _("Hiding window instead of closing:"));
		this.add_content (hide_start, _("Hide window on start to the messaging menu:"));
	}
}

public class Update : PreferenceTab
{
	internal Gtk.Button fav;
	construct
	{
		var auto_update = new Gtk.Switch ();
		var start_update = new Gtk.Switch ();
		var update_time = new Gtk.SpinButton.with_range (5, 90, 5);
		Feedler.SERVICE.schema.bind ("auto-update", auto_update, "active", SettingsBindFlags.DEFAULT);
		Feedler.SERVICE.schema.bind ("start-update", start_update, "active", SettingsBindFlags.DEFAULT);
		Feedler.SERVICE.schema.bind ("update-time", update_time, "value", SettingsBindFlags.DEFAULT);

        this.fav = new Gtk.Button ();
		this.fav.set_image (new Gtk.Image.from_icon_name ("go-bottom-symbolic", Gtk.IconSize.MENU));
		this.add_title (_("Subscriptions:"));
		this.add_content (auto_update, _("Enable automatic updates:"));
		this.add_content (start_update, _("Enable updates on start:"));
		this.add_content (update_time, _("Time interval between updates:"));
		this.add_title (_("Favicons:"));
		this.add_content (fav, _("Download now all favicons:"));
	}
}
 
public class Feedler.Preferences : Gtk.Dialog
{
	private Granite.Widgets.StaticNotebook tabs;
	private Gtk.Box content;
	internal Behavior behavior;
	internal Update update;
	
	construct
	{
		this.title = _("Preferences");
        this.border_width = 5;
		this.set_resizable (false);
		this.tabs = new Granite.Widgets.StaticNotebook (false);
		this.behavior = new Behavior ();
		this.update = new Update ();
		this.tabs.append_page (behavior, new Gtk.Label (_("Behavior")));
		this.tabs.append_page (update, new Gtk.Label (_("Updates")));
		
        this.content = this.get_content_area () as Gtk.Box;
        this.content.pack_start (tabs, false, true, 0);

        this.add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
		this.show_all ();
    }
}
