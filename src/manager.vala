/**
 * manager.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Manager : GLib.Object
{
	public uint count {get; set; default = 0;}

	private Feedler.Statusbar statusbar;
	private Feedler.Dock dockbar;
	private Feedler.Indicator indicator;

	public Manager ()
	{
		
	}

	public void unread (int diff)
	{
		this.count += diff;
		//this.dockbar.counter (count);
		//this.indicator.counter (count);
		Feedler.DOCK.counter (count);
		Feedler.INDICATOR.counter (count);
	}

	public void manage ()
	{
		this.unread (0);
	}
}
