/**
 * model.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public struct Model.Folder
{
	public int id;
	public string name;
	public int parent;
}

public class Model.Channel
{
    public int id;
	public string title;
	public string link;
	public string source;
    public int folder;
	public int unread;
    public GLib.List<Model.Item?> items;

    public Channel.with_data (int id, string title, string link, string source, int folder)
    {
        this.id = id;
        this.title = title;
        this.link = link;
        this.source = source;
        this.folder = folder;
    }

    public Model.Item? get_item (int id)
    {
        foreach (Model.Item item in this.items)
            if (id == item.id)
                return item;
        return null;
    }

	public string last_item_title ()
	{
        if (this.items.length () > 0)
            return this.items.last ().data.title;
        return "";
	}
}

public struct Model.Item
{
    public int id;
	public string title;
	public string source;
	public string author;
	public string description;
	public int time;
    public Model.State state;
    public int channel;
}

public enum Model.State
{
	READ = 0, UNREAD = 1, BOOKMARK = 2;
}
