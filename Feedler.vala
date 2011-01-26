/*
### BEGIN LICENSE
# Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License version 3, as published 
# by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranties of 
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
# PURPOSE.  See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program.  If not, see <http://www.gnu.org/licenses/>.
### END LICENSE
*/

using Gtk;

public class Feedler : Window {
   
    // Fields
    Toolbar toolbar;
    TreeView sidebar_treeview;
    TreeView browser_treeview;
//    ScrolledWindow browser_sw;
    ContentPane content_pane;
    ScrolledWindow treeview_sw;
    Gee.HashMap<string, Gee.HashMap<string, string>> results;
    AppMenu app_menu;
    VBox vbox;
    HPaned main_pane;
    VPaned browser_pane;

    public Feedler () {
        
        // The window poperties

        this.title = "Feedler";
        this.icon_name = "news-feed";
        this.window_position = WindowPosition.CENTER;
        this.set_default_size (800, 600);
        this.type_hint = Gdk.WindowTypeHint.NORMAL;
        
        // Initialize fields
        toolbar = new Toolbar ();
        vbox = new VBox (false, 0);
        main_pane = new HPaned ();
        main_pane.name = "SidebarHandleLeft";
        browser_pane = new VPaned ();
        content_pane = new ContentPane ();
        treeview_sw = new ScrolledWindow (null, null);

        // Set up local variables for the toolbutton items
        var add_button = new ToolButton.from_stock (Gtk.Stock.ADD);
        var remove_button = new ToolButton.from_stock (Gtk.Stock.DELETE);
        var spacing = new ToolItem ();
        spacing.set_expand (true); 
        this.toolbar.add (add_button);
        this.toolbar.add (remove_button);
        this.toolbar.add (spacing);

        this.main_pane.add2 (browser_pane);

        this.treeview_sw.set_policy (PolicyType.AUTOMATIC, PolicyType.AUTOMATIC);
        this.browser_pane.pack1 (treeview_sw, true, false);
        this.browser_pane.pack2 (content_pane, true, false);

        this.vbox.pack_start (this.toolbar, false, true, 0);
        this.vbox.pack_start (this.main_pane, true, true, 0);
        setup_appmenu ();
        setup_sidebar_treeview ();
        setup_browser_treeview ();
        this.app_menu.grab_focus ();
        this.add (this.vbox);

    }
    
    private void setup_appmenu () {
        var menu = new Menu ();
	    this.app_menu = new AppMenu.from_stock(Gtk.Stock.PROPERTIES, IconSize.MENU, "Menu", menu);
	    
	    MenuItem go_help = new MenuItem.with_label ("Get Help Online...");
	    MenuItem go_translate = new MenuItem.with_label ("Translate This Application...");
	    MenuItem go_report = new MenuItem.with_label ("Report a Problem...");
	    MenuItem about = new MenuItem.with_label ("About");
	    menu.append (go_help);
        menu.append (go_translate);
        menu.append (go_report);
	    menu.append (about);
	    menu.insert(new SeparatorMenuItem(), 3);
	    
	    about.activate.connect (about_dialog);
	    go_help.activate.connect (launch_help);
	    go_translate.activate.connect (launch_translate);
	    go_report.activate.connect (launch_report);
	            
	    this.toolbar.add (this.app_menu);
    }
    
    private void setup_sidebar_treeview () {
        this.sidebar_treeview = new TreeView ();
        var treestore = new TreeStore (2, typeof (string), typeof (string));
        string[] c = {"Open Source", "Steve Jobs", "Technology"};
        string[] l = {"OMG! Ubuntu", "WebUpd8", "Elementary News"};
        this.sidebar_treeview.set_model(treestore);
        this.sidebar_treeview.name = "SidebarContent";
        this.sidebar_treeview.set_headers_visible (false);
        this.sidebar_treeview.insert_column_with_attributes (-1, null, new CellRendererText (), "markup", 0, null);
        foreach (string cat in c) {
            TreeIter root;
            treestore.append (out root, null);
            treestore.set (root, 0, "<b>"+cat+"</b>", -1);
            foreach (string str in l) {
                TreeIter child;
                treestore.append (out child, root);
                treestore.set (child, 0, str, -1);
            }
        }
        this.sidebar_treeview.expand_all ();
        this.main_pane.add1 (this.sidebar_treeview);
    }
    
    private void on_browser_treeview_selection () { 
        var selection = this.browser_treeview.get_selection ();
        var model = this.browser_treeview.get_model ();
        var treeiter = TreeIter ();
        selection.get_selected(out model, out treeiter);
        var val = GLib.Value (typeof (string));
        model.get_value (treeiter, 0, out val);
        this.content_pane.load_article (results[(string)val]["description"], results[(string)val]["url"]);
        this.content_pane.show ();
    }
    
    private void setup_browser_treeview () {
        this.browser_treeview = new TreeView ();
        var treestore = new TreeStore (2, typeof (string), typeof (string));
        var gb = new Grabber ();
        var ff = new FeedFetcher ();
        string xml = ff.grab_xml ("http://feeds.feedburner.com/webupd8?format=xml");
        this.results = gb.parse_feed (xml);
        this.browser_treeview.set_model (treestore);
        this.browser_treeview.headers_visible = true;
        var title_column = new Gtk.TreeViewColumn.with_attributes ("Title", new CellRendererText (), "text", 0, null);
        title_column.resizable = true;
        title_column.max_width = 500;
        
        var date_column = new Gtk.TreeViewColumn.with_attributes ("Date", new CellRendererText (), "text", 1, null);
        title_column.resizable = true;
        date_column.max_width = 20;
        this.browser_treeview.insert_column (title_column, -1); 
        this.browser_treeview.insert_column (date_column, -1); 
        foreach (string result in results.keys) {
            TreeIter root;
            treestore.append (out root, null);
            treestore.set (root, 0, result, -1);
            treestore.set (root, 1, results[result]["date"], -1);
        }
        this.browser_treeview.columns_autosize ();
        this.browser_treeview.get_selection ().changed.connect (on_browser_treeview_selection);
//        this.content_pane.load_article (results[0]["description"]);
        this.treeview_sw.add (this.browser_treeview);
    }
    
    private void launch_help () {
        try {
            GLib.Process.spawn_async ("/usr/bin/", {"x-www-browser", "https://answers.launchpad.net/purple"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
        } catch {
            stderr.printf ("Unable to open link\n");
        }
    }
    
    private void launch_translate () {
        try {
            GLib.Process.spawn_async ("/usr/bin/", {"x-www-browser", "https://translations.launchpad.net/purple"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
        } catch {
            stderr.printf ("Unable to open link\n");
        }
    }
    
    private void launch_report () {
        try {
            GLib.Process.spawn_async ("/usr/bin/", {"x-www-browser", "https://bugs.launchpad.net/purple"}, null, GLib.SpawnFlags.STDERR_TO_DEV_NULL, null, null);
        } catch {
            stderr.printf ("Unable to open link\n");
        }
    }
    // Create the About Dialog
	private void about_dialog () {
        string[] authors = { "Avi Romanoff <aviromanoff@gmail.com>"};
        Gtk.show_about_dialog (this,
            "program-name", GLib.Environment.get_application_name (),
            //"version", Config.PACKAGE_VERSION, //FIXME: setup package version
            "copyright", "Copyright (C) 2011 Avi Romanoff", //_("Copyright (C) ThisYear Your Name"), //TODO: set up i18n
            "authors", authors,
            "logo-icon-name", "news-feed",
            //"translator-credits", _("translator-credits"), //TODO: DOES NOT COMPUTE
            null);
    }
    
    public static int main (string[] args) {
        // Startup GTK and pass args by reference
        Gtk.init (ref args);

        var window = new Feedler ();
        window.destroy.connect (Gtk.main_quit);
        window.show_all ();
        window.content_pane.hide ();
        window.app_menu.grab_focus (); // Better thaan giving focus elsewhere
        Gtk.main ();
        return 0;
    }
    
}
