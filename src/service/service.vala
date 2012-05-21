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
    public signal void iconed (string uri, uint8[] data);
    public signal void imported (Serializer.Folder[] folders);
    public signal void updated (Serializer.Channel channel);

    private Backend backend;
    private GLib.MainLoop loop;
    private unowned Thread<void*> thread;

    public Service.with_backend (BACKENDS back)
    {
        stderr.printf ("Feedler.Service.construct (%s)\n", back.to_string ());
        Notify.init ("org.example.Feedler");
        Bus.own_name (BusType.SESSION, "org.example.Feedler",
                      BusNameOwnerFlags.NONE, on_bus_aquired,
                      () => {}, () => stderr.printf ("Cannot aquire name.\n"));
        this.autoupdate = false;
        this.updatetime = 15;
        this.backend = GLib.Object.new (back.to_type ()) as Backend;
        this.backend.service = this;
        this.loop = new GLib.MainLoop ();
    }
    
    public Service ()
    {
        this.with_backend (BACKENDS.XML);
    }

    public void favicon (string uri)
	{
        stderr.printf ("Feedler.Service.favicon (%s)\n", uri);
		Soup.Message msg = new Soup.Message("GET", "http://getfavicon.appspot.com/"+uri);
        this.backend.session.queue_message (msg, favicon_cb);
	}

    public void favicon_all (string[] uris)
	{
		stderr.printf ("Feedler.Service.favicon_all ()\n");
        foreach (string uri in uris)
            this.favicon (uri);
	}

    private void favicon_cb (Soup.Session session, Soup.Message message)
	{
        string uri = message.uri.to_string (false);
        //this.iconed (uri, message.response_body.data);
        stderr.printf ("URI: %s", uri);
	}

    public void update (string uri)
    {
        stderr.printf ("Feedler.Service.update (%s)\n", uri);
        this.backend.update (uri);
    }

    public void update_all (string[] uris)
    {
        stderr.printf ("Feedler.Service.update_all ()\n");
        foreach (string uri in uris)
            this.update (uri);
    }

    public void import (string uri)
    {
        stderr.printf ("Feedler.Service.import (%s)\n", uri);
        this.backend.import (uri);
    }
    
    public void start ()
    {
        stderr.printf ("Feedler.Service.start ()\n");
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
            //TODO string[] uris
            //this.update_all ();

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

    public string ping ()
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

    public void notification (string msg)
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