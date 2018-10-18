/**
 * service.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

[DBus (name = "org.example.Feedler")]
public class Feedler.Service : Object {
    public signal void iconed (string uri, uint8[] data);
    public signal void added (Serializer.Channel channel);
    public signal void imported (Serializer.Folder[] folders);
    public signal void updated (Serializer.Channel channel);
    internal Feedler.Settings settings;
    //internal Feedler.Db db;
    private Backend backend;
    private unowned Thread<void*> thread;

    public Service.with_backend (BACKENDS back) {
        warning ("Feedler.Service.construct (" + back.to_string () + ")");
        Notify.init ("org.example.Feedler");
        this.settings = new Feedler.Settings ();
        //this.db = new Feedler.Db ();
        //unowned GLib.List<Model.Folder> tmp = this.db.select_data ();
        this.backend = GLib.Object.new (back.to_type ()) as Backend;
        this.backend.service = this;
        this.run ();
    }

    public Service () {
        this.with_backend (BACKENDS.XML);
    }

    public void favicon (string uri) {
        warning ("Feedler.Service.favicon (" + uri + ")");
        Soup.Message msg = new Soup.Message("GET", "http://www.google.com/s2/favicons?domain=" + uri);
        this.backend.session.queue_message (msg, favicon_func);
    }

    public void favicon_all (string[] uris) {
        warning ("Feedler.Service.favicon_all ()");

        foreach (string uri in uris) {
            this.favicon (uri);
        }
    }

    private void favicon_func (Soup.Session session, Soup.Message message) {
        string uri = message.uri.to_string (false).substring (41);
        this.iconed (uri, message.response_body.data);
        warning ("Feedler.Service.favicon_func.URI: " + uri + ".");
    }

    public void update (string uri) {
        warning ("Feedler.Service.update (" + uri + ").");
        this.backend.update (uri);
    }

    public void update_all (string[] uris) {
        warning ("Feedler.Service.update_all ()");

        foreach (string uri in uris) {
            this.update (uri);
        }
    }

    public void import (string uri) {
        warning ("Feedler.Service.import (" + uri + ").");
        this.backend.import (uri);
    }

    public void add (string uri) {
        warning ("Feedler.Service.add (" + uri + ").");
        this.backend.add (uri);
    }

    public void run () {
        warning ("Feedler.Service.run ()");

        try {
            ThreadFunc<void*> thread_func = () => {
                if (!settings.start_update) {
                    Thread.usleep (settings.update_time * 60 * 1000000);
                }

                while (settings.auto_update) {
                    this.update_all (settings.uri);

                    if (settings.auto_update) {
                        Thread.usleep (settings.update_time * 60 * 1000000);
                    }
                }

                return null;
            };
            this.thread = Thread.create<void*> (thread_func, false);
        } catch (GLib.ThreadError e) {
            warning ("Cannot run threads.");
        }
    }

    public string ping () {
        return "Welcome in Feedler service!\n";
    }

    public void notification (string msg) {
        try {
            Notify.Notification notify = new Notify.Notification ("Feedler News Reader", msg, "internet-news-reader");
            notify.show ();
        } catch (GLib.Error e) {
            warning ("Cannot send notify " + msg + ".");
        }
    }

    public new Serializer.Folder[] get_data () {
        /*Serializer.Folder[] data = new Serializer.Folder[this.db.data.length ()];
        int i = 0;
        foreach (unowned Model.Folder f in this.db.data)
        {
            data[i++] = new Serializer.Folder.from_model (f, true);
        }
        return data;*/
        Serializer.Folder[] data = new Serializer.Folder[2];
        return data;
    }
}

void on_bus_aquired (DBusConnection conn) {
    try {
        conn.register_object ("/org/example/feedler", new Feedler.Service ());
    } catch (IOError e) {
        warning ("Cannot register service.");
    }
}

void main () {
    Bus.own_name (BusType.SESSION, "org.example.Feedler",
                  BusNameOwnerFlags.NONE, on_bus_aquired,
    () => {}, () => warning ("Cannot aquire name."));
    new MainLoop ().run ();
}
