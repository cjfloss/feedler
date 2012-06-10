/**
 * manager.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Manager : GLib.Object
{
	public int count {get; set; default = 0;}
	public int news {get; set; default = 0;}

	private Feedler.Statusbar statusbar;
	//private Feedler.Dock dockbar;
	//private Feedler.Indicator indicator;

	public Manager (Feedler.Statusbar? stat)
	{
		this.statusbar = stat;
	}

	public void add (int news)
	{
		this.count += news;
		this.news += news;
	}

	public void unread (int diff)
	{
		this.count += diff;
		this.news = 0;
		//this.dockbar.counter (count);
		//this.indicator.counter (count);
		this.statusbar.counter (count);
		Feedler.DOCK.counter (count);
		Feedler.INDICATOR.counter (count);
	}

	public void manage ()
	{
		this.unread (0);
	}
}
