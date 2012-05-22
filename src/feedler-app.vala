/**
 * feedler-app.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

namespace Feedler
{
    public Feedler.State STATE;
    public Feedler.Settings SETTING;
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
		app_years = "2011-2012";
		application_id = "net.launchpad.Feedler";
		app_icon = "internet-feed-reader";
        app_launcher = "feedler.desktop";
		main_url = "https://launchpad.net/feedler";
		bug_url = "https://bugs.launchpad.net/feedler";
		help_url = "https://answers.launchpad.net/feedler";
		translate_url = "https://translations.launchpad.net/feedler";
		about_authors = {"Daniel Kur <daniel.m.kur@gmail.com>"};
		//about_license_type = Gtk.License.GPL_3_0;
	}

	protected override void activate ()
	{
		if (window != null)
		{
			window.present ();
			return;
		}
		Feedler.STATE = new Feedler.State ();
		Feedler.SETTING = new Feedler.Settings ();
		window = new Feedler.Window ();
        window.title = "Feedler";
		window.icon_name = "internet-feed-reader";
		window.set_application (this);
		window.show_all ();
		window.toolbar.about_program.activate.connect (() => {show_about (window);});
	}
	
	public static int main (string[] args)
	{
		var app = new Feedler.App ();
		return app.run (args);
	}
}
