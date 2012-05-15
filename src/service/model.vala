/**
 * model.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public enum Model.State
{
	READED,
	UNREADED,
	BOOKMARKED
}

public struct Model.Folder
{
	public int id;
	public string name;
	public int parent;
}

public struct Model.Channel
{
    public int id;
	public string title;
	public string link;
	public string source;
    public int folder;
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