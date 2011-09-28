/**
 * feedler-datatype.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.Folder
{
	public string name;
	public string parent;
}

public class Feedler.Channel
{
	public signal void updated (int channel_id, int unreaded);
	public signal void faviconed (int channel_id);
	
	public static Soup.Session session;
	public int id;
	public string title;
	public string source;
	public string homepage;
	public string folder;
	public string type;
	public int unreaded;
	public unowned GLib.List<Feedler.Item?> items;
	
	static construct
	{
		session = new Soup.SessionAsync ();
		session.timeout = 5;
	}

	public void add_item (Feedler.Item item)
	{
		this.items.append (item);
	}
	
	public void update ()
	{
		Soup.Message msg = new Soup.Message("GET", source);
        session.queue_message (msg, update_func);
	}
	
	public void favicon ()
	{
		stderr.printf ("http://getfavicon.appspot.com/%s\n", homepage);
		Soup.Message msg = new Soup.Message("GET", "http://getfavicon.appspot.com/"+homepage);
        session.queue_message (msg, favicon_func);
	}
	
	public void update_func (Soup.Session session, Soup.Message message)
	{
		string rss = (string) message.response_body.data;
		int unreaded = 0;

		if (rss != null)
		{
			string last;
			if (this.items.length () > 0)
				last = this.items.last ().data.title;
			else
				last = "";
			unowned Xml.Doc doc = Xml.Parser.parse_memory (rss, rss.length);
			Feedler.Parser parser = new Feedler.Parser ();
			unowned GLib.List<Feedler.Item?> rss_items = parser.parse_type (this.type, doc);
			GLib.List<Feedler.Item?> new_items = new GLib.List<Feedler.Item?> ();
			foreach (Feedler.Item it in rss_items)
			{
				if (it.title != last)
				{
					new_items.prepend (it);
					unreaded++;
				}
				else
					break;
			}
			foreach (Feedler.Item it in new_items)
				this.items.append (it);
			this.unreaded = unreaded;
			this.updated (id, unreaded);
		}
		else
			this.updated (id, -1);
	}
	
	public void favicon_func (Soup.Session session, Soup.Message message)
	{
		try
		{
			var loader = new Gdk.PixbufLoader.with_type ("ico");
			loader.write (message.response_body.data);
			loader.close ();
			var pix = loader.get_pixbuf ();
			if (pix.get_height () != 16)
				pix.scale_simple (16, 16, Gdk.InterpType.BILINEAR).save (GLib.Environment.get_user_data_dir () + "/feedler/fav/" + title + ".png", "png");
			else
				pix.save (GLib.Environment.get_user_data_dir () + "/feedler/fav/" + title + ".png", "png");
		}
		catch (GLib.Error e)
		{
			stderr.printf ("Feedler.Channel.favicon (): I cannot get favicon for %s\n", this.homepage);
		}
	}
}

public enum State
{
	READED,
	UNREADED,
	BOOKMARKED
}

public class Feedler.Item
{
	public string title;
	public string source;
	public string author;
	public string description;
	public int time;
	public State state;
}
