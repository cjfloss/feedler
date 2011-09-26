/**
 * feedler-datatype.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
internal class Feedler.Folder
{
	internal string name;
	internal string parent;
}

internal class Feedler.Channel
{
	internal signal void updated (int channel_id, int unreaded);
	internal signal void faviconed (int channel_id);
	
	internal static Soup.Session session = new Soup.SessionAsync ();
	internal int id;
	internal string title;
	internal string source;
	internal string homepage;
	internal string folder;
	internal string type;
	internal int unreaded;
	internal unowned GLib.List<Feedler.Item?> items;

	internal void add_item (Feedler.Item item)
	{
		this.items.append (item);
	}
	
	internal void update ()
	{
		Soup.Message msg = new Soup.Message("GET", source);
        session.queue_message (msg, update_func);
	}
	
	internal void favicon ()
	{
		stderr.printf ("http://getfavicon.appspot.com/%s\n", homepage);
		Soup.Message msg = new Soup.Message("GET", "http://getfavicon.appspot.com/"+homepage);
        session.queue_message (msg, favicon_func);
	}
	
	internal void update_func (Soup.Session session, Soup.Message message)
	{
		string rss = (string) message.response_body.data;
		int unreaded = 0;

		stderr.printf ("%s:\n", this.title);
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
				//stderr.printf ("%s - %s\n", it.title, it.author);
				//this.items.append (it);
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
	
	internal void favicon_func (Soup.Session session, Soup.Message message)
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

internal enum State
{
	READED,
	UNREADED,
	BOOKMARKED
}

internal class Feedler.Item
{
	internal string title;
	internal string source;
	internal string author;
	internal string description;
	internal int publish_time;
	internal State state;
}
