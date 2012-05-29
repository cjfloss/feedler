/**
 * indicator.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Indicator : GLib.Object
{
	private Indicate.Server server;
	private Indicate.Indicator update;
	private Indicate.Indicator unread;

	construct
	{
		this.server = Indicate.Server.ref_default ();
    	this.server.set_type ("message");
		this.server.set_desktop_file ("/usr/share/applications/feedler.desktop");
    	this.server.server_display.connect (Feedler.APP.switch_display);
    	this.server.show ();

		this.update = new Indicate.Indicator.with_server (server);
		//this.update.set_property ("subtype", "im");
		this.update.set_property ("name", _("Update subscriptions"));
		GLib.TimeVal time = GLib.TimeVal ();
	    time.get_current_time ();
		this.update.set_property_time ("time", time);
	    this.update.user_display.connect (_update);
		this.update.show ();

		this.unread = new Indicate.Indicator.with_server (server);
		this.unread.set_property ("sender", _("Unread feeds"));
	    this.unread.user_display.connect (_test);
		this.unread.show ();

		this.set_unread (2);
	}

	public void set_unread (int count)
	{
		//this.unread.set_property_int ("count", 5);
		this.unread.set_property ("count", "5");
		this.unread.set_property_bool ("draw-attention", true);
	}

	private void _update (uint timestamp)
	{
		stderr.printf ("UPDATE\n");
	}

	private void _test (uint timestamp)
	{
		stderr.printf ("TEST\n");
		this.unread.set_property_bool ("draw-attention", false);
	}
}
