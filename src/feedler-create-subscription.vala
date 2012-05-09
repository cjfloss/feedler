/**
 * feedler-create-subscription.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.CreateSubs : Granite.Widgets.PopOver
{
	private Gtk.ComboBoxText folder_entry;
	private Granite.Widgets.HintedEntry channel_entry;
	private Gtk.Box vbox;
	
	construct
	{
        this.border_width = 5;
		this.folder_entry = new Gtk.ComboBoxText ();
		this.folder_entry.append_text (_("Select folder"));
		this.folder_entry.set_active (0);
		this.channel_entry = new Granite.Widgets.HintedEntry ("URI");
        
        this.vbox = this.get_content_area () as Gtk.Box;
        this.vbox.pack_start (this.folder_entry, false, true, 0);
        this.vbox.pack_start (this.channel_entry, false, true, 0);

        //this.add_button (Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL);
        this.add_button (Gtk.Stock.ADD, Gtk.ResponseType.APPLY);
		this.show_all ();
    }
    
    public void add_folder (string folder_name)
    {
		this.folder_entry.append_text (folder_name);
	}
    
    public string get_uri ()
    {
		return channel_entry.get_text ();
	}
	
	public int get_folder ()
    {
		return folder_entry.get_active () - 1;
	}
}