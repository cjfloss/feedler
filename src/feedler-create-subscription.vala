/**
 * feedler-create-subscription.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.CreateSubs : Gtk.Window//Granite.Widgets.LightWindow
{
    public signal void feed_added (int folder, string url);
	private Gtk.ComboBoxText folder;
	private Granite.Widgets.HintedEntry channel;
	
	construct
	{
        this.border_width = 10;
        this.window_position = Gtk.WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal (false);
		this.destroy_with_parent = true;
        this.set_size_request (240, -1);
		this.resizable = false;

		this.folder = new Gtk.ComboBoxText ();
		this.folder.append_text (_("Select folder"));
		this.folder.set_active (0);
		this.channel = new Granite.Widgets.HintedEntry ("URI");

        var save = new Gtk.Button.with_label (_("Add"));
        save.valign = save.halign = Gtk.Align.END;
        save.clicked.connect_after (() => { feed_added (this.folder.get_active () - 1, this.channel.get_text ()); });

        var cancel = new Gtk.Button.with_label (_("Cancel"));
        cancel.valign = cancel.halign = Gtk.Align.END;
        cancel.clicked.connect_after (() => { this.destroy (); });

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_box.pack_start (cancel, false, false, 0);
        button_box.pack_end (save, false, false, 0);

        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        content.pack_start (this.folder, false, true, 0);
        content.pack_start (this.channel, false, true, 0);
        content.pack_end (button_box, false, false, 0);
        
		this.add (content);
		this.show_all ();
    }
    
    public void add_folder (string folder_name)
    {
		this.folder.append_text (folder_name);
	}
}
