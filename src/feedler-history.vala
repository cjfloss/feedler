/**
 * feedler-history.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.HistoryItem : GLib.Object
{
	private string channel;
	private string item;
	
	public HistoryItem (string channel, string item)
	{
		this.channel = channel;
		this.item = item;
	}
	
	public string get_channel () { return channel; }
	
	public string get_item () { return item; }
}

public class Feedler.History : GLib.Object
{
	private GLib.List<Feedler.HistoryItem> items;
	private uint current;
	
	construct
	{
		this.items = new GLib.List<Feedler.HistoryItem> ();
		this.current = 0;
	}
	
	public void add (string channel, string item)
	{
		if (current == items.length ())
		{
			stderr.printf ("simply add");
			this.items.append (new Feedler.HistoryItem (channel, item));
		}
		else
		{
			stderr.printf ("extended add");
			unowned GLib.List<Feedler.HistoryItem> unused = this.items.nth (current);
			this.items.remove_link (unused.next);
			this.items.append (new Feedler.HistoryItem (channel, item));
		}
		this.current = items.length ();
		stderr.printf ("add current: %u", current);
	}
	
	public void remove_double ()
	{
		unowned GLib.List<Feedler.HistoryItem> unused = this.items.last ();
		this.items.remove_link (unused);
		--current;	
	}
	
	public bool next (out string side_path, out string? view_path)
	{
		if (current == items.length ())
		{
			//stderr.printf ("Current false: %u\n", current);
			side_path = null;
			view_path = null;
			return false;
		}
		else
		{
			//stderr.printf ("Current: %u\n", current);
			unowned Feedler.HistoryItem item = items.nth_data (current);
			++current;
			side_path = item.get_channel ();
			view_path = item.get_item ();
			return true;
		}
	}
	
	public bool prev (out string side_path, out string? view_path)
	{
		if (current <= 1)
		{
			//stderr.printf ("Current: %u\n", current);
			side_path = null;
			view_path = null;
			return false;
		}
		else
		{
			//stderr.printf ("Current: %u\n", current);
			unowned Feedler.HistoryItem item = items.nth_data (current-2);
			--current;
			side_path = item.get_channel ();
			view_path = item.get_item ();
			return true;
		}
	}
}
