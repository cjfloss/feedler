/**
 * service.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

[DBus (name = "org.example.Feedler")]
public class FeedlerService : Object
{
  	public signal void updated (int channel, int unreaded);
    private static Soup.Session session;
    private bool autoupdate = true;  
    //private FeedlerClient client;    
    //private uint watch;    
    private GLib.MainLoop loop;
    private int counter;

    static construct
	{
		session = new Soup.SessionAsync ();
		//session.timeout = 5;
	}
    
    public FeedlerService ()
    {
        try
        {
            Bus.own_name (BusType.SESSION, "org.example.Feedler",
                          BusNameOwnerFlags.NONE, on_bus_aquired,
                          () => {}, () => stderr.printf ("Cannot aquire name.\n"));
/*
            watch = Bus.watch_name (BusType.SESSION, "org.example.Feedler",
                                    BusNameWatcherFlags.AUTO_START, () => {},
                                    on_name_vanished);
            
            client = Bus.get_proxy_sync (BusType.SESSION, "org.example.Feedler",
                                                          "/org/example/feedler");
*/
            autoupdate = true;
            counter = 0;
            Notify.init ("org.example.Feedler");
            this.send_notify ("There are new feeds to read!");
        }
        catch (GLib.IOError e)
        {
            stderr.printf ("%s\n", e.message);
            autoupdate = false;
        }
    }

    public void update (string uri)
    {
        stderr.printf ("Feedler.Service.update (%s)\n", uri);
        Soup.Message msg = new Soup.Message ("GET", uri);
        session.queue_message (msg, update_func);
    }

    private void update_func (Soup.Session session, Soup.Message message)
	{
        stderr.printf ("Feedler.Service.update_func\n");
		string rss = (string) message.response_body.data;

		if (rss != null)
		{
            this.updated (this.counter, this.counter+10);
            this.send_notify ("%i new feeds".printf (this.counter));
            stderr.printf ("%s\n", rss);
            //TODO Parse XML
		}
	}
    
    public void start ()
    {
        loop = new GLib.MainLoop ();
        try
        {
            Thread.create<void*> (() => { this.run (); return null;}, false);
        }
        catch (GLib.ThreadError e)
        {
            stderr.printf ("Cannot run threads.\n");
        }
        loop.run ();
    }
    
    public void run ()
    {
        while (autoupdate)
        {
            //client.ping ("UPDATE");
            //TODO: Interval update
            this.counter++;

            if (autoupdate)
                Thread.usleep(1000000);
        }
        loop.quit ();
    }

    public void stop ()
    {
        autoupdate = false;
        stderr.printf ("Feedler.Service.stop ()\n");
    }

    void on_bus_aquired (DBusConnection conn)
    {
        try
        {
            conn.register_object ("/org/example/feedler", this);
        }
        catch (IOError e)
        {
            stderr.printf ("Cannot register service.\n");
        }
    }
/*    
    void on_name_vanished (DBusConnection conn, string name)
    {
        stdout.printf ("%s vanished, closing down.\n", name);
        autoupdate = false;
    }
*/
    private void send_notify (string msg)
    {
        try
        {
            Notify.Notification notify = new Notify.Notification ("Feedler News Reader", msg, "internet-feed-reader");
			notify.show ();
        }
        catch (GLib.Error e)
        {
            stderr.printf ("Cannot send notify: Feedler.Service.send_notify (%s)\n", msg);
        }
    }
}

void main ()
{
    FeedlerService demo = new FeedlerService ();
    demo.start ();
}