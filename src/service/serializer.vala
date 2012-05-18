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
    public Serializer.Item[]? items;

    public Channel.from_model (Model.Channel model, bool full = true)
    {
        //this.id = model.id;
        this.title = model.title;
        this.link = model.link;
        this.source = model.source ?? "";
        this.folder = model.folder;
        if (full)
        {
            int i = 0;
            this.items = new Serializer.Item[model.items.length ()];
            foreach (var item in model.items)
                this.items[i++] = Serializer.Item.from_model (item);
        }
    }
}

public struct Serializer.Item
{
    //public int id;
	public string title;
	public string source;
	public string author;
	public string description;
	public int time;
    //public Model.State state;
    //public int channel;

    public Item.from_model (Model.Item model)
    {
        //this.id = model.id;
        this.title = model.title ?? "No title";
        this.source = model.source;
        this.author = model.author;
        this.description = model.description ?? "";
        this.time = model.time;
        //this.state = model.state;
    }
}