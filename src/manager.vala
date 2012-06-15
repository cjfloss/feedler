/**
 * manager.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Manager : GLib.Object
{
	internal int count;
	private int news;
	private int connections;
	private double fraction;
	private double proceed;
	private Feedler.Dock dockbar;
	private Feedler.Indicator indicator;
	private Feedler.Window window;
	private Gee.LinkedList<Serializer.Channel?> q;

	public Manager (Feedler.Window win)
	{
		this.dockbar = new Feedler.Dock ();
		this.indicator = new Feedler.Indicator ();
		this.window = win;
		this.q = new Gee.LinkedList<Serializer.Channel?> ();
	}

	public void queue (Serializer.Channel channel)
	{
		this.q.add (channel);
		try
		{
			GLib.Thread.create<void*> (this.updated_func, false);
			//GLib.Thread<void*> t = new GLib.Thread<void*> ("thread", this.updated_func);
		}
		catch (GLib.ThreadError e)
		{
			stderr.printf ("Cannot run threads.\n");
		}
	}

	public void add (int news)
	{
		this.count += news;
		this.news += news;
	}

	public void unread (int diff = 0)
	{
		this.count += diff;
		this.dockbar.counter (count);
		this.indicator.counter (count);
		this.window.stat.counter (count);
	}

	public void start (string text, int conn = 1)
	{
		this.window.toolbar.progress.show_bar (text);
		this.connections = conn;
		this.fraction = 1.0 / (connections * 2.0);
		this.news = 0;
		this.proceed = 0.0;
	}

	public void progress ()
	{
		this.proceed += fraction;
		this.window.toolbar.progress.proceed (proceed);
		this.dockbar.proceed (proceed);
	}

	public bool end (string? msg = null)
	{
		this.connections--;
		this.progress ();
		if (connections == 0)
        {
            this.window.toolbar.progress.hide_bar ();
			this.unread ();
			return true;
        }
		return false;
	}

	public void error ()
	{
		this.connections = 0;
        this.window.toolbar.progress.hide_bar ();
		this.dockbar.proceed (1.0);
	}

	private void* updated_func ()
	{
		stderr.printf ("updated_func\n");
		Serializer.Channel channel = this.q.poll_head ();
		this.progress ();
        Model.Channel ch = this.window.db.from_source (channel.source);
        GLib.List<Serializer.Item?> reverse = new GLib.List<Serializer.Item?> ();
		string last = ch.last_item_title ();
        foreach (var i in channel.items)
        {
            if (last == i.title)
                break;
            reverse.append (i);
        }
        reverse.reverse ();
        this.window.db.begin ();
        foreach (var i in reverse)
        {
            int id = this.window.db.insert_serialized_item (ch.id, i);
            Model.Item it = {id, i.title, i.source, i.author, i.description, i.time, Model.State.UNREAD, ch.id};
            ch.items.append (it);
        }
        this.window.db.commit ();

		if (reverse.length () > 0)
		{
			this.add ((int)reverse.length ());
			this.window.side.add_unread (ch.id, (int)reverse.length ());
			if (this.window.selection_tree () == ch.id)
				this.window.load_channel ();
		}
		else
			this.window.side.set_mode (ch.id, 1);
		if (this.end ())
			this.window.notification ("%i %s".printf (news, news > 1 ? _("new feeds") : _("new feed")));
		return null;
	}
}
