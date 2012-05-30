/**
 * dock.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Dock : GLib.Object
{
	private Unity.LauncherEntry dock;
	private int counter;

	construct
	{
		this.dock = Unity.LauncherEntry.get_for_desktop_id ("feedler.desktop");
		this.counter = 0;
	    this.dock.count_visible = false;
	}

	public void add_unread (int i)
	{
		this.counter += i;
		this.dock.count = counter;
	    this.dock.count_visible = true;
	}

	public void step_unread (int i)
	{
		this.counter += i;
		this.dock.count = counter;
		if (counter <= 0)
			this.dock.count_visible = false;
	}
}
