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
    private Backend backend;
    private GLib.MainLoop loop;
    private bool autoupdate;
    private int updatetime;
    private int counter;

    static construct
	{
		session = new Soup.SessionAsync ();
		//session.timeout = 5;
	}

    public FeedlerService.with_backend (BACKENDS back)
    {
        stderr.printf ("Feedler.Service.construct (%s)\n", back.to_string ());
        Notify.init ("org.example.Feedler");
        Bus.own_name (BusType.SESSION, "org.example.Feedler",
                      BusNameOwnerFlags.NONE, on_bus_aquired,
                      () => {}, () => stderr.printf ("Cannot aquire name.\n"));
        this.autoupdate = true;
        this.updatetime = 2000000;
        this.counter = 0;
        this.backend = GLib.Object.new (back.to_type ()) as Backend;

    }
    
    public FeedlerService ()
    {
        this.with_backend (BACKENDS.XML);
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
        string xml = (string)message.response_body.flatten ().data;
        GLib.List<Item?> items = new GLib.List<Item?> ();

		if (xml != null && this.backend.parse_items (xml, ref items))
		{
            this.updated (this.counter, (int)items.length ());
            this.send_notify ("%u new feeds".printf (items.length ()));
            foreach (Item? i in items)
                stderr.printf ("%s by %s on %i\n", i.title, i.author, i.time);
		}

        Channel ch = Channel ();
        if (xml != null && this.backend.parse_channel (xml, ref ch))
		{
            //this.updated (this.counter, (int)items.length ());
            //this.send_notify ("%u new feeds".printf (items.length ()));
            stderr.printf ("\n%s from %s\n", ch.title, ch.link);
		}
	}
    
    public void start ()
    {
        stderr.printf ("Feedler.Service.start ()\n");
        loop = new GLib.MainLoop ();
        try
        {
            ThreadFunc<void*> thread = () =>
            { 
                while (autoupdate)
                {
                    //TODO: Interval update
                    this.counter++;

                    if (autoupdate)
                        Thread.usleep (updatetime);
                }
                loop.quit ();
                return null;
            };
            Thread.create<void*> (thread, false);
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