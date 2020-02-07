/**
 * folder.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Folder : Gtk.Dialog {
    public signal void saved_folder (int id, string name);
    private int id;
    private Gtk.Entry folder;

    public Folder () {
        Object (title: _("Add new folder"), window_position: Gtk.WindowPosition.CENTER_ON_PARENT, modal: false, destroy_with_parent: true, border_width: 12, use_header_bar: 1, resizable: false);

        this.id = 0;
        this.folder = new Gtk.Entry ();

        var save = new Gtk.Button.with_label (_("Save"));
        save.set_size_request (85, -1);
        save.valign = save.halign = Gtk.Align.END;
        save.sensitive = false;
        save.clicked.connect_after (() => {
            saved_folder (this.id, this.folder.get_text ());
            this.destroy ();
        });
        save.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

        folder.key_release_event.connect (() => {
            folder.get_text () == "" ? save.sensitive = false : save.sensitive = true;
            return true;
        });

        //var button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 10);
        //button_box.pack_end (save, false, false, 0);
        //button_box.margin_top = 30;

        var f_label = new Gtk.Label ("");
        f_label.set_markup ("<b>%s</b>".printf (_("Name")));
        f_label.set_halign (Gtk.Align.START);

        Gtk.Box content = (Gtk.Box) this.get_content_area ();
        content.pack_start (f_label);
        content.pack_start (folder, false, true, 0);
        //content.pack_end (button_box, false, false, 0);
        content.border_width = 12;

        this.add_action_widget (save, 0);

        this.show_all ();
    }

    public void set_model (int id, string title) {
        this.title = _("Edit folder %s").printf (title);
        this.id = id;
        this.folder.set_text (title);
    }
}