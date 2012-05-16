/**
 * service.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

[DBus (name = "org.example.Feedler")]
public class Feedler.Service : Object
{
    public bool autoupdate;
    public int updatetime;
    private signal void iconed (int channel, bool state);
  	public signal void updated (int channel, int unreaded);

    private static Soup.Session session;
    private Backend backend;
    private GLib.MainLoop loop;
    private unowned Thread<void*> thread;
    private int connection;
    private int unreaded;

    static construct
	{
		session = new Soup.SessionAsync ();
		//session.timeout = 5;
	}

    public Service.with_backend (BACKENDS back)
    {
        stderr.printf ("Feedler.Service.construct (%s)\n", back.to_string ());
        Notify.init ("org.example.Feedler");
        Bus.own_name (BusType.SESSION, "org.example.Feedler",
                      BusNameOwnerFlags.NONE, on_bus_aquired,
                      () => {}, () => stderr.printf ("Cannot aquire name.\n"));
        this.autoupdate = false;
        this.updatetime = 15;
        this.connection = 0;
        this.backend = GLib.Object.new (back.to_type ()) as Backend;

    }
    
    public Service ()
    {
        this.with_backend (BACKENDS.XML);
    }

    public void favicon (string url)
	{
		//stderr.printf ("http://getfavicon.appspot.com/%s\n", url);
		Soup.Message msg = new Soup.Message("GET", "http://getfavicon.appspot.com/"+url);
        session.queue_message (msg, favicon_func);
	}

    private void favicon_func (Soup.Session session, Soup.Message message)
	{
		try
		{
            int id = 0;
            //TODO select channel
			var loader = new Gdk.PixbufLoader.with_type ("ico");
			loader.write (message.response_body.data);
			loader.close ();
			var pix = loader.get_pixbuf ();
			if (pix.get_height () != 16)
				pix.scale_simple (16, 16, Gdk.InterpType.BILINEAR);
            pix.save ("%s/feedler/fav/%i.png".printf (GLib.Environment.get_user_data_dir (), id), "png");
			this.iconed (id, true);
		}
		catch (GLib.Error e)
		{
			//this.iconed (id, false);
			stderr.printf ("Cannot get favicon from %s\n", message.uri.to_string (false));
		}
	}

    public void update (string uri)
    {
        stderr.printf ("Feedler.Service.update (%s)\n", uri);
        ++this.connection;
        Soup.Message msg = new Soup.Message ("GET", uri);
        session.queue_message (msg, update_func);
    }

    public void update_all ()
    {
        stderr.printf ("Feedler.Service.update_all ()\n");
        foreach (var uri in this.backend.db.select_channels_uri ())
            this.update (uri);
    }

    private void update_func (Soup.Session session, Soup.Message message)
	{
        stderr.printf ("Feedler.Service.update_func %s\n", message.uri.to_string (false));
        string xml = (string)message.response_body.flatten ().data;
        GLib.List<Model.Item?> items = new GLib.List<Model.Item?> ();

		if (xml != null && this.backend.parse_items (xml, ref items))
		{
            this.unreaded += (int)items.length ();
            --this.connection;
            this.updated (this.backend.db.select_channel (message.uri.to_string (false)), (int)items.length ());
            if (this.connection == 0)
            {
                this.send_notify ("%i new feeds".printf (this.unreaded)); //TODO gettext
                this.unreaded = 0;
            }
            this.backend.db.begin ();
            foreach (Model.Item item in items)
                this.backend.db.insert_item (item);
            this.backend.db.commit ();
		}
	}

    public void import (string uri)
    {
        stderr.printf ("Feedler.Service.import (%s)\n", uri);
        this.backend.parse_folders (uri);
    }
    
    public void start ()
    {
        stderr.printf ("Feedler.Service.start ()\n");
        loop = new GLib.MainLoop ();
        try
        {
            ThreadFunc<void*> thread_func = () =>
            { 
                this.run ();
                return null;
            };
            this.thread = Thread.create<void*> (thread_func, false);
        }
        catch (GLib.ThreadError e)
        {
            stderr.printf ("Cannot run threads.\n");
        }
        loop.run ();
    }
    
    public void run ()
    {
        Thread.usleep (10000000);
        while (autoupdate)
        {
            this.update_all ();

            if (autoupdate)
                Thread.usleep (this.updatetime * 1000000);
        }
        //loop.quit ();
    }

    public void stop ()
    {
        autoupdate = false;
        //this.thread.exit (null);
        stderr.printf ("Feedler.Service.stop ()\n");
        loop.quit ();
    }

    public string test ()
    {
        return "Welcome in Feedler service!\n";
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
            stderr.printf ("Cannot send notify %s.\n", msg);
        }
    }
}

void main ()
{
    Feedler.Service service = new Feedler.Service ();
    service.start ();
}