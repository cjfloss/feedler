/**
 * serializer.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public struct Serializer.Folder
{
	public string name;
	//public int parent;
    //public Serializer.Folder[]? folders;
    public Serializer.Channel[]? channels;

    public Folder.from_model (Model.Folder model, GLib.List<Model.Channel?> models)
    {
        this.name = model.name;
        this.channels = new Serializer.Channel[models.length ()];
        int i = 0;
        foreach (var c in models)
            this.channels[i++] = Serializer.Channel.from_model (c, false);
    }
}

public struct Serializer.Channel
{
	public string title;
	public string link;
	public string source;
    public int folder;
    public Serializer.Item[]? items;

    public Channel.from_model (Model.Channel model, bool full = true)
    {
        this.title = model.title;
        this.link = model.link ?? "";
        this.source = model.source ?? "";
        this.folder = model.folder;
        //this.items = null;
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
	public string title;
	public string source;
	public string author;
	public string description;
	public int time;

    public Item.from_model (Model.Item model)
    {
        this.title = model.title ?? "No title";
        this.source = model.source;
        this.author = model.author;
        this.description = model.description ?? "";
        this.time = model.time;
    }
}