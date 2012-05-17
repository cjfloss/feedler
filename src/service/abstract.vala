/**
 * abstract.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public enum BACKENDS
{
    XML,
    READER;

    public GLib.Type to_type ()
    {
        switch (this)
        {
            case XML:
                return GLib.Type.from_name (typeof (BackendXml).name ());
            case READER:
                return GLib.Type.from_name (typeof (BackendXml).name ());//TODO: Reader
            default:
                assert_not_reached();
        }
    }
    
    public string to_string ()
    {
        switch (this)
        {
            case XML:
                return "XML";
            case READER:
                return "Google Reader";
            default:
                assert_not_reached();
        }
    }
}

public abstract class Backend : GLib.Object
{
    public abstract bool subscriptions (string data);
    public abstract bool channel (string data);
    public abstract bool items (string data);
    public abstract BACKENDS to_type ();
    public abstract string to_string ();
    internal abstract void update_func (Soup.Session session, Soup.Message message);
    internal unowned Feedler.Service service;
    internal static Soup.Session session;
    internal static Database db;

    static construct
    {
        session = new Soup.SessionAsync ();
		//session.timeout = 5;
        db = new Database ();
    }
}
