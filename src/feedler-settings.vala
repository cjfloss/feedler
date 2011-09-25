/**
 * feedler-settings.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Settings : Granite.Services.Settings
{
	public int width { get; set; }
    public int height { get; set; }
    public int hpane_width { get; set; }

    public Settings ()
    {
		base ("apps.feedler");
    }
}
