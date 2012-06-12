/**
 * infobar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Infobar : Gtk.InfoBar
{	
	private Gtk.Label label;
	
	public Infobar ()
	{
		this.set_message_type (Gtk.MessageType.QUESTION);

		this.label = new Gtk.Label ("");
		this.label.set_line_wrap (true);
		this.label.halign = Gtk.Align.START;
		this.label.use_markup = true;

		var no = new Gtk.Button.with_label (("   ") + _("Dismiss") + ("   "));
		no.clicked.connect (() => { this.hide (); });

		var yes = new Gtk.Button.with_label (("   ") + _("Undo") + ("   "));
		yes.clicked.connect (() => {
			//var mw = get_toplevel () as MainWindow;
			this.hide ();
		});
		
		var box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
		box.add (yes);
		box.add (no);
		
		var expander = new Gtk.Label ("");
		expander.hexpand = true;
		
		((Gtk.Box)get_content_area ()).add (label);
		((Gtk.Box)get_content_area ()).add (expander);
		((Gtk.Box)get_content_area ()).add (box);
		
		this.no_show_all = true;
	}
	
	public void question (string msg)
	{
		this.label.set_markup (msg);
		this.no_show_all = false;
		this.show_all ();
		this.no_show_all = true;
	}
}
