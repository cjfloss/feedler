/**
 * indicator.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Indicator : GLib.Object
{
	private Indicate.Server server;
	private Indicate.Indicator indicator;

	construct
	{
		this.server = Indicate.Server.ref_default ();
    	this.server.set_type ("message.im");
		this.server.set_desktop_file ("/usr/share/applications/feedler.desktop");
    	this.server.server_display.connect (server_display);
    	this.server.show ();

		this.indicator = new Indicate.Indicator ();
    	GLib.TimeVal time = GLib.TimeVal ();
    	time.get_current_time ();
	    this.indicator.set_property ("subtype", "im");
    	this.indicator.set_property ("sender", "Test message");
    	this.indicator.set_property ("body", "Test message body");
	    this.indicator.set_property_time ("time", time);
		this.indicator.show ();
    	//time = GLib.TimeVal.get_current_time (); indicator.set_property_time ("time", time);
	    this.indicator.user_display.connect (display);
	}

	private void server_display (uint timestamp)
	{
		stderr.printf ("Ah, my indicator has been displayed\n");
	}

	private bool timeout_cb ()
	{
		stderr.printf ("Modifying properties\n");
		Indicate.Indicator indicator = new Indicate.Indicator ();
		GLib.TimeVal time = GLib.TimeVal ();
		time.get_current_time ();
		indicator.set_property_time ("time", time);
		return true;
	}

	private void display (uint timestamp)
	{
		stderr.printf ("Ah, my indicator has been displayed\n");
	}
}
