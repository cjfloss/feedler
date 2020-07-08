/**
 * view-list.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
using Feedler;

public class FeedStore : GLib.Object {
    public int id { get; set; }
    public string subject { get; set; }
    public string date { get; set; }
    public string source { get; set; }
    public string text { get; set; }
    public string author { get; set; }
    public bool read { get; set; }
    public bool starred { get; set; }

    public FeedStore (Objects.Item item, string time_format) {
        this.id = item.id;
        this.subject = item.title;
        this.date = time_format;
        this.source = item.source;
        this.text = item.description;
        this.author = item.author;
        this.read = item.read;
        this.starred = item.starred;
    }
}

public class Feedler.ViewList : Feedler.View {
    /* List with feeds and searching */
    internal Gtk.TreeView tree;
    private Gtk.ListStore store;
    private Feedler.ViewCell cell;
    private Feedler.MenuView viewmenu;
    private Gtk.TreeModelFilter filter;
    private string filter_text;
    private FeedStore selected;
    private Gtk.TreeIter selected_iter;
    /* Browse description of current feed */
    private WebKit.WebView browser;
    private Gtk.ScrolledWindow scroll_list;
    private Gtk.ScrolledWindow scroll_web;
    internal Gtk.Paned pane;

    construct {
        this.store = new Gtk.ListStore (1, typeof (FeedStore));
        this.cell = new Feedler.ViewCell ();
        this.filter = new Gtk.TreeModelFilter (store, null);
        this.filter.set_visible_func (this.search_filter);
        this.tree = new Gtk.TreeView.with_model (filter);
        this.tree.headers_visible = false;
        this.tree.enable_search = false;
        this.tree.get_selection ().set_mode (Gtk.SelectionMode.SINGLE);
        this.tree.button_press_event.connect (click_item);
        this.tree.row_activated.connect (browse_page);
        this.filter_text = "";

        var column = new Gtk.TreeViewColumn.with_attributes ("FeedStore", cell, null);
        column.set_sizing (Gtk.TreeViewColumnSizing.FIXED);
        column.set_cell_data_func (cell, render_cell);
        this.tree.insert_column (column, -1);

        this.viewmenu = new Feedler.MenuView ();
        this.viewmenu.disp.activate.connect (load_item);
        this.viewmenu.open.activate.connect (browse_page);
        this.viewmenu.copy.activate.connect (copy_url);
        this.viewmenu.read.activate.connect (read_item);
        this.viewmenu.unre.activate.connect (read_item);
        this.viewmenu.star.activate.connect (star_item);
        this.viewmenu.unst.activate.connect (star_item);
        this.viewmenu.show_all ();

        this.scroll_list = new Gtk.ScrolledWindow (null, null);
        this.scroll_list.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        this.scroll_list.add (tree);

        this.browser = new WebKit.WebView ();
        this.browser.settings = this.settings;

        this.scroll_web = new Gtk.ScrolledWindow (null, null);
        this.scroll_web.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        this.scroll_web.add (browser);

        this.pane = new Gtk.Paned (Gtk.Orientation.VERTICAL);
        this.pane.set_position (225);

        this.pane.pack1 (scroll_list, true, false);
        this.pane.pack2 (scroll_web, true, false);
        this.add (pane);
    }

    public override void clear () {
        this.store.clear ();
        this.tree.model = null;
        this.load_article ("");
    }

    public override void add_feed (Objects.Item item, string time_format) {
        Gtk.TreeIter feed_iter;
        this.store.prepend (out feed_iter);
        this.store.set (feed_iter, 0, new FeedStore (item, time_format));
    }

    public override void load_feeds () {
        this.tree.model = filter;
    }

    public override void refilter (string text) {
        this.filter_text = text;
        this.filter.refilter ();
    }

    public override bool contract () {
        try {
            if (this.selected != null) {
                var path = GLib.Environment.get_tmp_dir () + "/feedler.html";
                GLib.StringBuilder item = new GLib.StringBuilder (generate_style ("rgb(77,77,77)", "rgb(113,113,113)", "rgb(77,77,77)", "rgb(0,136,205)"));
                item.append ("<div class='item'><span class='title'>" + selected.subject + "</span><br/>");
                item.append ("<span class='time'>" + selected.date + ", by " + selected.author + "</span><br/>");
                item.append ("<span class='content'>" + selected.text + "</span></div><br/>");

                GLib.File file = GLib.File.new_for_path (path);
                uint8[] data = item.data;
                string s;
                file.replace_contents (data, null, false, 0, out s);
                return true;
            }

            // TODO else infobar message: Please select first one item oraz change view to get all items.
        } catch (GLib.Error e) {
            warning ("Cannot create temp file.");
        }

        return false;
    }

    private void load_article (string content) {
        warning ("Feedler.ViewList.load_article ()");
        this.browser.load_html (content, null);
    }

    private void browse_page () {
        warning ("Feedler.ViewList.browse_page ()");

        try {
            GLib.Process.spawn_command_line_async ("xdg-open " + selected.source);

            if (!selected.read) {
                selected.read = true;
                this.store.set_value (selected_iter, 0, selected);
                this.item_marked (selected.id, Objects.State.READ);
            }
        } catch (GLib.Error e) {
            warning ("ERROR: " + e.message);
        }
    }

    private void copy_url () {
        warning ("Feedler.ViewList.copy_url ()");

        try {
            Gtk.Clipboard clipboard = Gtk.Clipboard.get_for_display (this.get_display (), Gdk.SELECTION_CLIPBOARD);
            clipboard.set_text (selected.source, -1);
        } catch (GLib.Error e) {
            warning ("ERROR: " + e.message);
        }
    }

    private void load_item () {
        warning ("Feedler.ViewList.load_item ()");

        if (selected != null) {
            string content = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>%s</title>
  <style>
    body {
      margin: 2rem;
      border-radius: 8px;
    }
    
    header {
      padding: 1rem;
      border-bottom: 0.1rem solid hsl(0, 80%, 10%);
    }
    
    #top {
        display: flex;
        justify-content: space-between;
    }
    
    .author {
        display: flex;
        flex-direction: column;
        margin-bottom: 1rem;
    }
    
    .title {
        display: flex;
        flex-direction: column;
    }
    
    span#title {
        font-size: 1.5rem;
        margin-bottom: 0.5rem;
    }
    
    article {
        padding: 0.5rem 1rem;
    }
    
    img {
        max-width:100%;
        height:auto;
    }
  </style>
</head>

<body>
    <header>
        <div id="top">
            <div class="author">
                <a href="%s" title="Content">%s</a>
                <span>%s</span>
            </div>
            <div>
                <img src="https://ranchero.com/images/nnw_icon_32.png">
            </div>
        </div>
        
        <div class="title">
            <span id="title">%s</span>
            <date>%s</date> 
        </div> 
    </header>
    <article>%s</article>
</body>
</html>"""
            .printf(selected.subject, selected.source, selected.source, selected.author, selected.subject,selected.date, selected.text);
            
            this.load_article (content);

            if (!selected.read) {
                this.selected.read = true;
                this.store.set_value (selected_iter, 0, selected);
                this.item_marked (selected.id, Objects.State.READ);
            }
        }
    }

    private void read_item () {
        warning ("Feedler.ViewList.read_item ()");

        if (selected != null) {
            this.selected.read = !selected.read;
            this.store.set_value (selected_iter, 0, selected);
            this.item_marked (selected.id, selected.read ? Objects.State.READ : Objects.State.UNREAD);
        }
    }

    private void star_item () {
        warning ("Feedler.ViewList.star_item ()");

        if (selected != null) {
            this.selected.starred = !selected.starred;
            this.store.set_value (selected_iter, 0, selected);
            this.item_marked (selected.id, selected.starred ? Objects.State.STARRED : Objects.State.UNSTARRED);
        }
    }

    private FeedStore ? selected_item (out Gtk.TreeIter iter) {
        warning ("Feedler.ViewList.selected_item ()");
        FeedStore feed = null;
        Gtk.TreeModel model;

        if (this.tree.get_selection ().get_selected (out model, out iter)) {
            this.tree.model.get (iter, 0, out feed);
        }

        return feed;
    }

    private bool search_filter (Gtk.TreeModel model, Gtk.TreeIter iter) {
        //warning ("Feedler.ViewList.search_filter ()");
        if (filter_text == "") {
            return true;
        }

        FeedStore feed = null;
        model.get (iter, 0, out feed);

        if (feed == null) {
            return false;
        }

        if (filter_text in feed.subject) {
            return true;
        } else {
            return false;
        }
    }

    private void render_cell (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter) {
        //warning ("Feedler.ViewList.render_cell ()");
        FeedStore feed;
        model.get (iter, 0, out feed);

        if (feed != null) {
            var renderer = cell as Feedler.ViewCell;
            renderer.subject = feed.subject;
            renderer.date = feed.date;
            renderer.author = feed.author;
            renderer.channel = feed.source;
            renderer.unread = !feed.read;
        } else {
            return;
        }
    }

    private bool click_item (Gdk.EventButton e) {
        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        int cell_x, cell_y;

        if (this.tree.get_path_at_pos ((int) e.x, (int) e.y, out path, out column, out cell_x, out cell_y)) {
            this.tree.get_selection ().select_path (path);
            this.selected = this.selected_item (out this.selected_iter);

            if (e.button == 3) {
                this.viewmenu.select_mark (selected.read, selected.starred);
                this.viewmenu.popup_at_pointer (e);
            } else if (e.button == 1) {
                this.load_item ();
            }

            return true;
        }

        return false;
    }
}
