/**
 * subscription-editor.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.EditSubs : Granite.Widgets.LightWindow
{
    public signal void feed_edited (int id, int folder, string channel,  string url);
    public signal void subscription_edited (int id, int folder, string channel, string url);
    private int id;
	private Gtk.ComboBoxText folder;
    private Granite.Widgets.HintedEntry channel;
	private Granite.Widgets.HintedEntry uri;
	
	public EditSubs ()
	{
        this.border_width = 15;
        this.window_position = Gtk.WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
		this.set_modal (false);
		this.destroy_with_parent = true;
        this.set_size_request (320, -1);
		this.resizable = false;

		this.folder = new Gtk.ComboBoxText ();
		this.channel = new Granite.Widgets.HintedEntry ("Name");
        this.uri = new Granite.Widgets.HintedEntry ("URI");

        var save = new Gtk.Button.with_label (_("Save"));
        save.valign = save.halign = Gtk.Align.END;
        save.clicked.connect_after (() => { feed_edited (this.id, this.folder.get_active () + 1, this.channel.get_text () ,this.uri.get_text ()); this.destroy (); });

        var cancel = new Gtk.Button.with_label (_("Cancel"));
        cancel.valign = cancel.halign = Gtk.Align.END;
        cancel.clicked.connect_after (() => { this.destroy (); });

        var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        button_box.pack_start (cancel, false, false, 0);
        button_box.pack_end (save, false, false, 0);
        button_box.margin_top = 10;

        var f_label = new Gtk.Label ("");
        f_label.set_markup ("<b>%s</b>".printf (_("Folder")));
        f_label.set_halign (Gtk.Align.START);
        var n_label = new Gtk.Label ("");
        n_label.set_markup ("<b>%s</b>".printf (_("Name")));
        n_label.set_halign (Gtk.Align.START);
        n_label.margin_top = 5;
        var c_label = new Gtk.Label ("");
        c_label.set_markup ("<b>%s</b>".printf (_("URI Address")));
        c_label.set_halign (Gtk.Align.START);
        c_label.margin_top = 5;
        
        var content = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        content.pack_start (f_label);
        content.pack_start (this.folder, false, true, 0);
        content.pack_start (n_label);
        content.pack_start (this.channel, false, true, 0);
        content.pack_start (c_label);
        content.pack_start (this.uri, false, true, 0);
        content.pack_end (button_box, false, false, 0);
        
		this.add (content);
		this.show_all ();
    }
    
    public void add_folder (string folder_name)
    {
		this.folder.append_text (folder_name);
	}

    public void set_model (int id, string title, string uri, int folder)
    {
        this.id = id;
		this.channel.set_text (title);
		this.uri.set_text (uri);
        this.folder.set_active (folder);
    }
}
