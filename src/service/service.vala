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
        this.counter = 0;
        switch (back)
        {
            case BACKENDS.XML:
                this.backend = new BackendXml ();
                break;
            default:
                this.backend = new BackendXml ();
                break;
        }
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
        GLib.List<string?> items = null;

		if (xml != null && this.backend.parse (xml, out items))
		{
            this.updated (this.counter, this.counter+10);
            this.send_notify ("%i new feeds".printf (this.counter));
            stderr.printf ("%s\n", xml);
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
                        Thread.usleep(1000000);
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