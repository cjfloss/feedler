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

	private Feedler.Dock dockbar;
	private Feedler.Indicator indicator;
	private Feedler.Statusbar statusbar;
	private Feedler.Toolbar toolbar;

	public Manager (Feedler.Statusbar? stat, Feedler.Toolbar? tool = null)
	{
		this.dockbar = new Feedler.Dock ();
		this.indicator = new Feedler.Indicator ();
		this.statusbar = stat;
		this.toolbar = tool;
	}

	public void add (int news)
	{
		this.count += news;
		this.news += news;
	}

	public void unread (int diff = 0)
	{
		this.count += diff;
		this.news = 0;
		this.dockbar.counter (count);
		this.indicator.counter (count);
		this.statusbar.counter (count);
	}

	public void start (string text, int conn = 1)
	{
		this.toolbar.progress.show_bar (text);
		this.connections = conn;
		this.fraction = 1.0 / (connections * 2.0);
	}

	public void progress ()
	{
		this.toolbar.progress.proceed (fraction);
		this.dockbar.proceed (fraction);
	}

	public void end ()
	{
		this.connections--;
		this.progress ();
		if (connections == 0)
        {
            this.toolbar.progress.hide_bar ();
            //string description = this.news > 1 ? _("new feeds") : _("new feed");
            //this.notification ("%i %s".printf (this.news, description));
			this.unread ();
        }
	}

	public void error ()
	{
		this.connections = 0;
        this.toolbar.progress.hide_bar ();
		this.dockbar.proceed (1.0);
	}
}
