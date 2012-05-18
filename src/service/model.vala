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
    public GLib.List<Model.Item?> items;

    public Model.Item? get_item (int id)
    {
        foreach (Model.Item item in this.items)
            if (id == item.id)
                return item;
        return null;
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
	READED,
	UNREADED,
	BOOKMARKED
}
