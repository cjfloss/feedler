/**
 * model.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public enum State
{
	READED,
	UNREADED,
	BOOKMARKED
}

public struct Folder
{
	public int id;
	public string name;
	public int parent;
}

public struct Channel
{
    public int id;
	public string title;
	public string link;
	public string source;
    public int folder;
}

public struct Item
{
    public int id;
	public string title;
	public string source;
	public string author;
	public string description;
	public int time;
}
