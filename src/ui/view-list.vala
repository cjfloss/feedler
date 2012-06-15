/**
 * view-list.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class FeedStore : GLib.Object
{
    public int id { get; set; }
    public string subject { get; set; }
    public string date { get; set; }
    public string source { get; set; }
    public string text { get; set; }
    public string author { get; set; }
    public bool unread { get; set; }
	
	public FeedStore (Model.Item item, string time_format)
	{
        this.id = item.id;
		this.subject = item.title;
		this.date = time_format;		
		this.source = item.source;
		this.text = item.description;
		this.author = item.author;
		if (item.state == Model.State.UNREAD)
			this.unread = true;
		else
			this.unread = false;
	}
}

public class Feedler.ViewList : Feedler.View
{
	/* List with feeds and searching */
	internal Gtk.TreeView tree;
	private Gtk.ListStore store;
	private Feedler.ViewCell cell;
	private Feedler.MenuView viewmenu;
	private Gtk.TreeModelFilter filter;
	private string filter_text;
	private string cache;
	/* Browse description of current feed */
	private WebKit.WebView browser;
	private Gtk.ScrolledWindow scroll_list;
	private Gtk.ScrolledWindow scroll_web;
	private Gtk.Paned pane;

	construct
	{
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
		this.viewmenu.read.activate.connect (mark_item);
		this.viewmenu.unre.activate.connect (mark_item);
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
		this.pane.set_position (240);
		
		this.pane.add1 (scroll_list);
		this.pane.add2 (scroll_web);
		this.add (pane);
	}
	
	public override void clear ()
	{
		this.store.clear ();
	}
	
	public override void add_feed (Model.Item item, string time_format)
	{
		Gtk.TreeIter feed_iter;
		this.store.prepend (out feed_iter);
        this.store.set_value (feed_iter, 0, new FeedStore (item, time_format));
	}
	
	public override void load_feeds ()
	{
	}
	
	public override void refilter (string text)
	{
		this.filter_text = text;
		this.filter.refilter ();
	}
	
	public override void select (Gtk.TreePath path)
	{
		stderr.printf ("Feedler.ViewList.select ()\n");
		this.tree.get_selection ().select_path (path);
		this.load_item ();
	}

    public override void change ()
    {
        if (this.pane.get_orientation () == Gtk.Orientation.VERTICAL)
            this.pane.set_orientation (Gtk.Orientation.HORIZONTAL);
        else
            this.pane.set_orientation (Gtk.Orientation.VERTICAL);
    }

	public override bool contract ()
	{
		try
		{
			Gtk.TreeIter iter;
			FeedStore feed = this.selected_item (out iter);
			if (feed != null)
			{
				var path = GLib.Environment.get_tmp_dir () + "/feedler.html";
				GLib.StringBuilder item = new GLib.StringBuilder (generate_style ("rgb(77,77,77)", "rgb(113,113,113)", "rgb(77,77,77)", "rgb(0,136,205)"));
				item.append ("<div class='item'><span class='title'>"+feed.subject+"</span><br/>");
				item.append ("<span class='time'>"+feed.date+", by "+feed.author+"</span><br/>");
				item.append ("<span class='content'>"+feed.text+"</span></div><br/>");
				GLib.FileUtils.set_contents (path, item.str);
				return true;
			}
		}
		catch (GLib.Error e)
		{
			stderr.printf ("Cannot create temp file.\n");
		}
		return false;
	}

    public override Feedler.Views type ()
    {
        return Feedler.Views.LIST;
    }
	
	private void load_article (string content)
	{
		this.browser.load_string (content, "text/html", "UTF-8", "");
	}
	
	private void browse_page () 
	{
		stderr.printf ("Feedler.ViewList.browse_page ()\n");
		try
		{
			Gtk.TreeIter iter;
			FeedStore? feed = this.selected_item (out iter);
			GLib.Process.spawn_command_line_async ("xdg-open " + feed.source);
			if (feed.unread)
			{
				feed.unread = false;
				this.store.set_value (iter, 0, feed);
				this.item_marked (feed.id, feed.unread);
			}
			if (feed.source != this.cache)
				this.item_selected (this.tree.model.get_path (iter).to_string ());
			this.cache = feed.source;
		}
		catch (GLib.Error e)
		{
			stderr.printf ("ERROR: %s\n", e.message);
		}
	}
	
	private void load_item ()
	{
		stderr.printf ("Feedler.ViewList.load_item ()\n");
		Gtk.TreeIter iter;
		FeedStore feed = this.selected_item (out iter);
		if (feed != null)
		{
			this.tree.model.get (iter, 0, out feed);
			this.load_article (feed.text);
			if (feed.unread)
			{
				feed.unread = false;
				this.store.set_value (iter, 0, feed);
				this.item_marked (feed.id, feed.unread);
			}
			if (feed.source != this.cache)
				this.item_selected (this.tree.model.get_path (iter).to_string ());
			this.cache = feed.source;
		}
	}

	private void mark_item ()
	{
		Gtk.TreeIter iter;
		FeedStore feed = this.selected_item (out iter);
		if (feed != null)
		{
			this.tree.model.get (iter, 0, out feed);
			feed.unread = !feed.unread;
			this.store.set (iter, 0, feed);
			this.item_marked (feed.id, feed.unread);
		}
	}

	private FeedStore? selected_item (out Gtk.TreeIter iter)
	{
		FeedStore feed = null;
		Gtk.TreeModel model;
		if (this.tree.get_selection ().get_selected (out model, out iter))
			this.tree.model.get (iter, 0, out feed);
		return feed;
	}
	
	private bool search_filter (Gtk.TreeModel model, Gtk.TreeIter iter)
	{
		FeedStore feed;
		model.get (iter, 0, out feed);

		if (filter_text == "")
			return true;
			
		if (filter_text in feed.subject)
			return true;
		else
			return false;
	}
	
	private void render_cell (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter)
	{
		FeedStore feed;
		var renderer = cell as Feedler.ViewCell;
		model.get (iter, 0, out feed);
		if (feed != null)
		{
			renderer.subject = feed.subject;
			renderer.date = feed.date;
			renderer.author = feed.author;
			renderer.channel = feed.source;
			renderer.unread = feed.unread;
		}
	}

	private bool click_item (Gdk.EventButton e)
	{
		Gtk.TreePath path;
		Gtk.TreeViewColumn column;
		int cell_x, cell_y;
		if (this.tree.get_path_at_pos ((int) e.x, (int) e.y, out path, out column, out cell_x, out cell_y))
		{
			this.tree.get_selection ().select_path (path);
			if (e.button == 1)
				this.load_item ();
			else if (e.button == 3)
			{
				Gtk.TreeIter iter;
				FeedStore feed = this.selected_item (out iter);
				this.viewmenu.select_mark (feed.unread);
				this.viewmenu.popup (null, null, null, e.button, e.time);
			}
			return true;
		}
		return false;
	}
}
