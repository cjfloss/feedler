/**
 * feedler-create-subscription.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.CreateSubs : Gtk.Dialog
{
	internal Gtk.ComboBoxText folder_entry;
	internal Gtk.Entry channel_entry;
	internal Gtk.VBox vbox = new Gtk.VBox (false, 0);
	
	construct
	{
		this.title = "Create subscriptions";
        this.border_width = 5;
		this.folder_entry = new Gtk.ComboBoxText ();
		var folder_label = new Gtk.Label.with_mnemonic ("_Folder name:");
        folder_label.mnemonic_widget = this.folder_entry;
		this.channel_entry = new Gtk.Entry ();
		var channel_label = new Gtk.Label.with_mnemonic ("_Channel name:");
        channel_label.mnemonic_widget = this.channel_entry;
        
        var hbox = new Gtk.HBox (false, 20);
        hbox.pack_start (folder_label, false, true, 0);
        hbox.pack_start (this.folder_entry, true, true, 0);
        this.vbox.pack_start (hbox, false, true, 0);
        var hbox2 = new Gtk.HBox (false, 20);
        hbox2.pack_start (channel_label, false, true, 0);
        hbox2.pack_start (this.channel_entry, true, true, 0);
        this.vbox.pack_start (hbox2, false, true, 0);
        
        //this.add (this.vbox);
        //this.child = vbox;

        //this.add_button (Gtk.Stock.CLOSE, Gtk.ResponseType.CLOSE);
        //this.add_button (Gtk.Stock.APPLY, Gtk.ResponseType.APPLY);
		this.show_all ();
    }
}
