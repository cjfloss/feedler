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
    public abstract string to_string ();
    //TODO: Abstract class for backends
}
