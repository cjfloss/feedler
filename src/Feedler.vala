/**
 * feedler.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

//TODO Offline Mode: Read without requesting images
//
//
//


//TODO JSON Feeds https://jsonfeed.org/version/1
//
//
namespace Feedler {
    internal Feedler.State STATE;
    internal Feedler.Settings SETTING;
    internal Feedler.Service SERVICE;
    internal Feedler.App APP;
}

public class Feedler.App : Granite.Application {
    private Feedler.Window window = null;

    construct {
        build_data_dir = Build.DATADIR;
        build_pkg_data_dir = Build.PKG_DATADIR;
        build_release_name = Build.RELEASE_NAME;
        build_version = Build.VERSION;
        build_version_info = Build.VERSION_INFO;

        program_name = _(Build.APP_NAME);
        exec_name = Build.APP_NAME;

        application_id = Build.APP_NAME;
        app_launcher = Build.APP_NAME + ".desktop";
    }

    public void switch_display () {
        if (window.is_active) {
            this.window.hide ();
        } else {
            this.window.present_with_time ((uint32)GLib.get_monotonic_time ());
        }
    }

    public void update () {
        //this.window._update_all ();
    }

    protected override void activate () {
        if (window != null) {
            window.present_with_time ((uint32)GLib.get_monotonic_time ());
            return;
        }

        Granite.Services.Logger.initialize (Build.APP_NAME);
        Granite.Services.Logger.DisplayLevel = DEBUG ? Granite.Services.LogLevel.DEBUG : Granite.Services.LogLevel.INFO;

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/cjfloss/feedler/application.css");
        Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

        Feedler.STATE = new Feedler.State ();
        Feedler.SETTING = new Feedler.Settings ();
        Feedler.SERVICE = new Feedler.Service ();

        this.window = new Feedler.Window ();
        this.window.title = "Feedler";
        this.window.icon_name = "internet-news-reader";
        this.window.set_application (this);
        this.window.show_all ();

        if (Feedler.SETTING.hide_start) {
            this.window.hide ();
        }
    }

    public static int main (string[] args) {
        Feedler.APP = new Feedler.App ();
        return APP.run (args);
    }
}