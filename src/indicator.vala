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

	construct
	{
		this.server = Indicate.Server.ref_default ();
    	this.server.set_type ("message.feed");
		this.server.set_desktop_file ("/usr/share/applications/feedler.desktop");
    	this.server.server_display.connect (Feedler.APP.switch_display);
    	this.server.show ();

		this.update = new Indicate.Indicator.with_server (server);
		this.update.set_property ("name", _("Update"));
	    this.update.user_display.connect (_update);
		this.update.show ();
		//this.server.show ();
	}

	private void _update (uint timestamp)
	{
		stderr.printf ("UPDATE\n");
	}
}
