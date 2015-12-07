/**
 * feedler.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

namespace Feedler
{
    internal Feedler.State STATE;
    internal Feedler.Settings SETTING;
    internal Feedler.Service SERVICE;
	internal Feedler.App APP;
}

public class Feedler.App : Granite.Application
{
	private Feedler.Window window = null;

	construct
	{
		build_data_dir = Build.DATADIR;
		build_pkg_data_dir = Build.PKGDATADIR;
		build_release_name = Build.RELEASE_NAME;
		build_version = Build.VERSION;
		build_version_info = Build.VERSION_INFO;

		program_name = "Feedler";
		exec_name = "feedler";
		app_copyright = "2011-2015";
		app_years = "2011-2015";
		app_icon = "internet-news-reader";
        	app_launcher = "feedler.desktop";
		application_id = "net.launchpad.Feedler";

		main_url = "https://launchpad.net/feedler";
		bug_url = "https://bugs.launchpad.net/feedler";
		help_url = "https://answers.launchpad.net/feedler";
		translate_url = "https://translations.launchpad.net/feedler";

		about_authors = {"Daniel Kur <daniel.m.kur@gmail.com>"};
		about_documenters = {null};
		about_artists = {null};
		about_comments = "<awesome>\n\t<name=\"Feedler\">\n\t<type=\"RSS Reader\">\n</awesome>";
		about_translators = "Launchpad Translators";
		about_license_type = Gtk.License.LGPL_2_1;
	}

	public void switch_display ()
	{
		if (window.is_active)
            this.window.hide ();
        else
            this.window.present_with_time ((uint32)GLib.get_monotonic_time ());
	}

	public void update ()
	{
		//this.window._update_all ();
	}

	protected override void activate () {
		if (window != null) {
			window.present_with_time ((uint32)GLib.get_monotonic_time ());
            return;
		}
		Feedler.STATE = new Feedler.State ();
		Feedler.SETTING = new Feedler.Settings ();
		Feedler.SERVICE = new Feedler.Service ();

		this.window = new Feedler.Window ();
        this.window.title = "Feedler";
		this.window.icon_name = "internet-news-reader";
		this.window.set_application (this);
		this.window.show_all ();
		if (Feedler.SETTING.hide_start)
			this.window.hide ();
	}
	
	public static int main (string[] args)
	{
		Feedler.APP = new Feedler.App ();
		return APP.run (args);
	}
}
