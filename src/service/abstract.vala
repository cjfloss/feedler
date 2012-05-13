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
    public abstract bool parse (string data, out GLib.List<string?> items);
    public abstract BACKENDS to_type ();
    public abstract string to_string ();
    
    protected Backend ()
    {
        GLib.Type t = this.get_type ();
        stderr.printf (t.name ());
    }
}
