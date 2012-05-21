/**
 * feedler-view-list.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class FeedStore : GLib.Object
{
    public int id {set; get; }
    public string subject { set; get; }
    public string date { set; get; }
    public string source { set; get; }
    public string text { set; get; }
    public string author { set; get; }
    public bool unread { set; get; }
	
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
	private string cache;
	/* List with feeds and searching */
	private Gtk.TreeView tree;
	private Gtk.ListStore store;
	private Feedler.ViewCell cell;
	private Gtk.TreeModelFilter filter;
	private string filter_text;
	
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
		this.tree.row_activated.connect (browse_page);
		this.tree.cursor_changed.connect (load_item);
		this.filter_text = "";
		
		var column = new Gtk.TreeViewColumn.with_attributes ("FeedStore", cell, null);
		column.set_sizing (Gtk.TreeViewColumnSizing.FIXED);
		column.set_cell_data_func (cell, render_cell);
		this.tree.insert_column (column, -1);
		
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
        this.store.set (feed_iter, 0, new FeedStore (item, time_format), -1);
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

    public override int to_type ()
    {
        return 1;
    }
	
	protected void load_article (string content)
	{
		this.browser.load_string (content, "text/html", "UTF-8", "");
	}
	
	protected void browse_page (Gtk.TreePath path, Gtk.TreeViewColumn column) 
	{
		stderr.printf ("Feedler.ViewList.browse_page ()\n");
		try
		{
			Gtk.TreeIter iter;
			if (this.tree.model.get_iter (out iter, path))
			{
				FeedStore feed;
				this.tree.model.get (iter, 0, out feed);
				
				if (!GLib.Process.spawn_command_line_async ("xdg-open "+feed.source))
					stderr.printf ("ERROR\n");
			}
		}
		catch (GLib.Error e)
		{
			stderr.printf ("ERROR: %s\n", e.message);
		}
	}
	
	protected void load_item ()
	{
		stderr.printf ("Feedler.ViewList.load_item ()\n");
		Gtk.TreeModel model;
		Gtk.TreeIter iter;		
		Gtk.TreeSelection selection = this.tree.get_selection ();
		if (selection.get_selected (out model, out iter))
		{
			FeedStore feed;
			this.tree.model.get (iter, 0, out feed);
			this.load_article (feed.text);
			if (feed.unread)
			{
				feed.unread = false;
				this.store.set (iter, 0, feed);
				this.item_readed (feed.id);
			}
			if (feed.source != this.cache)
				this.item_selected (model.get_path (iter).to_string ());
			this.cache = feed.source;
		}
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
		
		renderer.subject = feed.subject;
		renderer.date = feed.date;
		renderer.author = feed.author;
		renderer.channel = feed.source;
		renderer.unread = feed.unread;
	}
}
