/**
 * settings.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public enum Feedler.WindowState { NORMAL=0, MAXIMIZED=1, FULLSCREEN=2; }

public class Feedler.State : Granite.Services.Settings
{
	public int window_width { get; set; }
	public int window_height { get; set; }
	public int sidebar_width { get; set; }
	public WindowState window_state { get; set; }

	public State ()
	{
		base ("org.elementary.feedler.state");
	}
}

public class Feedler.Settings : Granite.Services.Settings
{
	public bool enable_image { get; set; }
	public bool enable_script { get; set; }
	public bool enable_java { get; set; }
	public bool enable_plugin { get; set; }
	public bool shrink_image { get; set; }

    public Settings ()
    {
		base ("org.elementary.feedler.settings");
    }
}

public class Feedler.Service : Granite.Services.Settings
{
	public bool auto_update { get; set; }
	public int update_time { get; set; }
	public string[] uri { get; set; }

	public Service ()
	{
		base ("org.elementary.feedler.service");
	}
}
