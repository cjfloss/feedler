/**
 * backend-xml.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class BackendXml : Backend
{
    public override bool parse (string data, out GLib.List<string?> items)
    {
        items = null;
        return true;
    }

    public override string to_string ()
    {
        return "Default XML-based backend.";
    }
    //TODO: Default backend based on XML file
}
