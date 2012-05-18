/**
 * serializer.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

namespace Serializer.List
{
    public static Model.Folder[] folders_array (GLib.List<Model.Folder?> folders)
    {
        Model.Folder[] f = new Model.Folder[folders.length ()];
        for (uint i = 0; i < folders.length (); i++)
            f[i] = folders.nth_data (i);
        return f;
    }

    public static Serializer.Channel[] channels_array (GLib.List<Model.Channel?> channels)
    {
        Serializer.Channel[] c = new Serializer.Channel[channels.length ()];
        for (uint i = 0; i < channels.length (); i++)
            c[i] = Channel.from_model (channels.nth_data (i), false);
        return c;
    }
}

public struct Serializer.Channel
{
    //public int id;
	public string title;
	public string link;
	public string source;
    public int folder;
    public Model.Item[] items;

    public Channel.from_model (Model.Channel model, bool items = true)
    {
        //this.id = model.id;
        this.title = model.title;
        this.link = model.link;
        this.source = model.source;
        this.folder = model.folder;
        if (items)
        {
            this.items = new Model.Item[model.items.length ()];
            for (uint i = 0, j = model.items.length ()-1; i <= j; i++, j--)
                this.items[i] = model.items.nth_data (j);
        }
    }
}