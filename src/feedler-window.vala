/**
 * feedler-window.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Window : Gtk.Window
{
	private Feedler.Settings settings;
	private Feedler.Database db;
	private Feedler.OPML opml;
	internal Feedler.Toolbar toolbar;
	private Feedler.Sidebar side;
	private Feedler.Statusbar stat;
	private Gtk.Menu context;
	private Feedler.History history;
	private weak Feedler.View view;
	private Gtk.HPaned hpane;
	private Gtk.VBox vbox;
	private Gtk.ScrolledWindow scroll_side;
	private Feedler.CardLayout layout;
	private bool new_feeds;
	
	construct
	{
        //Icons.init ();
		Notify.init ("org.elementary.Feedler");
		this.settings = new Feedler.Settings ();
		this.db = new Feedler.Database ();
		this.opml = new Feedler.OPML ();
		this.layout = new Feedler.CardLayout ();
		this.title = "Feedler";
		this.icon_name = "internet-feed-reader";
		this.destroy.connect (destroy_app);
		this.set_default_size (settings.width, settings.height);
		this.set_size_request (820, 520);
		
		this.vbox = new Gtk.VBox (false, 0);	
		this.ui_toolbar ();
		if (this.db.created)
			this.ui_feeds ();
		else
			this.ui_welcome ();		
			
        this.stat = new Feedler.Statusbar ();
        this.stat.add_feed.button_press_event.connect (this.add_feed_pressed);
        this.stat.delete_feed.button_press_event.connect (this.del_feed_pressed);
        this.stat.edit_feed.button_press_event.connect (this.edit_feed_pressed);
        this.stat.mark_feed.button_press_event.connect (this.mark_feed_pressed);
        //this.stat.set_unreaded (3);

        this.vbox.pack_end (this.stat, false, true, 0);
		this.add (vbox);
		this.history = new Feedler.History ();
	}
	
	private void ui_toolbar ()
	{
		this.toolbar = new Feedler.Toolbar ();   
        this.vbox.pack_start (toolbar, false, false, 0);
        
        this.toolbar.back.clicked.connect (history_prev);
        this.toolbar.forward.clicked.connect (history_next);
        this.toolbar.next.clicked.connect (next_unreaded);
        this.toolbar.update.clicked.connect (update_all);
        //this.toolbar.mark.clicked.connect (mark_all);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.search.activate.connect (search_list); 
        
        this.toolbar.import_feeds.activate.connect (import_file);
        this.toolbar.export_feeds.activate.connect (export_file);
        this.toolbar.preferences.activate.connect (config);
        this.toolbar.sidebar_visible.toggled.connect (sidebar_update);
        this.toolbar.fullscreen_mode.toggled.connect (fullscreen_mode);
	}

	private void ui_workspace ()
	{
		this.toolbar.mode.selected = 0;
		this.side = new Feedler.Sidebar ();
		this.side.button_press_event.connect (context_menu);
		this.scroll_side = new Gtk.ScrolledWindow (null, null);
		this.scroll_side.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		this.scroll_side.add (side);
		
		this.context = new Gtk.Menu ();
		Gtk.MenuItem it_delete = new Gtk.MenuItem.with_label ("Delete");
		//Gtk.MenuItem it_rename = new Gtk.MenuItem.with_label ("Rename");
		//it_rename.set_sensitive (false);
		this.context.append (it_delete);
		//this.context.append (it_rename);
		it_delete.activate.connect (delete_channel);
		this.context.show_all ();
		
		this.hpane = new Gtk.HPaned ();
		this.side.name = "SidebarContent";
        this.side.get_style_context ().add_class ("sidebar");
		this.hpane.get_style_context().add_class("sidebar-pane-separator");
		this.hpane.set_position (settings.hpane_width);
        this.vbox.pack_start (hpane, true);
        this.hpane.add1 (scroll_side);
        this.hpane.add2 (layout);
        
        var vlist = new Feedler.ViewList ();
        var vweb = new Feedler.ViewWeb ();
        vlist.item_readed.connect (mark_channel);
        vweb.item_readed.connect (mark_channel);
		this.layout.append_page (vlist, null);
		this.layout.append_page (vweb, null);
		this.view = (Feedler.View)layout.get_nth_page (0);
		this.view.item_selected.connect (history_add);
		this.view.item_browsed.connect (history_remove);
	}
	
	private void ui_feeds ()
	{
		this.ui_workspace ();        
        foreach (Feedler.Folder folder in this.db.select_folders ())
		{
			if (folder.parent != -1)
				this.side.add_folder_to_folder (folder.id, folder.name, folder.parent);
			else
				this.side.add_folder (folder.id, folder.name);
		}
			
		foreach (Feedler.Channel channel in this.db.select_channels ())
		{
			if (channel.folder != -1)
				this.side.add_channel_to_folder (channel.folder, channel.id, channel.title);
			else
				this.side.add_channel (channel.id, channel.title);
			channel.updated.connect (updated_channel);
			channel.faviconed.connect (faviconed_channel);
		}			
		this.side.expand_all ();
		this.side.cursor_changed.connect (load_channel);
	}
	
	private void ui_welcome ()
	{
		this.toolbar.set_enable (false);
		Granite.Widgets.Welcome welcome = new Granite.Widgets.Welcome ("Get Some Feeds", "Feedler can't seem to find your feeds.");
		welcome.append ("gtk-new", "Import", "Add a subscriptions from OPML file.");
		//welcome.append ("tag-new", "Create", "Add a subscription from URL.");		
		welcome.activated.connect (catch_activated);
		this.vbox.pack_start (welcome, true);
	}
	
	private void ui_welcome_to_workspace ()
	{
		this.toolbar.set_enable (true);
		GLib.List<Gtk.Widget> box = this.vbox.get_children ();
		this.vbox.remove (box.nth_data (box.length ()-1));
		this.ui_workspace ();
	}
	
	protected void destroy_app ()
	{
        Gtk.Allocation alloc;
        get_allocation(out alloc);
        settings.width = alloc.width;
        settings.height = alloc.height;
        settings.hpane_width = this.hpane.position;
		
		Gtk.main_quit ();
	}
	
	protected void catch_activated (int index)
	{
		stderr.printf ("Activated: %i\n", index);
		switch (index)
		{
			case 0: this.import_file (); break;
			//case 1: this.add_subscription (); break;
		}
	}
	
	private int selection_tree ()
	{
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		Gtk.TreeSelection selection = this.side.get_selection ();
		
		if (selection.get_selected (out model, out iter))
		{
			ChannelStore channel;
			model.get (iter, 0, out channel);
			return channel.id;
		}
		else
			return -1;
	}
	
	protected void history_prev ()
	{
		string side_path = null, view_path = null;
		if (this.history.prev (out side_path, out view_path))
		{
			this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
			this.load_channel ();
			if (view_path != null)
			{
				this.view.select (new Gtk.TreePath.from_string (view_path));
			}
		}
	}
	
	protected void history_next ()
	{
		string side_path, view_path;
		if (this.history.next (out side_path, out view_path))
		{
			this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
			this.load_channel ();
			if (view_path != null)
			{
				this.view.select (new Gtk.TreePath.from_string (view_path));
			}
		}
	}
	
	protected void history_add (string item)
	{	
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
		{
			this.history.add (model.get_path (iter).to_string (), item);
		}
	}
	
	protected void history_remove ()
	{	
		this.history.remove_double ();
	}
	
	protected void next_unreaded ()
	{	
		stderr.printf ("Feedler.App.next_unreaded ()\n");
		foreach (Feedler.Channel ch in this.db.channels)
		{
			if (ch.unreaded > 0)
			{
				this.side.select_channel (ch.id);
				this.load_channel ();
				break;
			}
		}
	}
		
	protected void update_all ()
	{
		this.toolbar.progressbar_show ();
		foreach (Feedler.Channel ch in this.db.channels)
		{
			ch.update ();
		}
	}
	
	protected void updated_channel (int channel, int unreaded)
	{
		Feedler.Channel ch = this.db.channels.nth_data (channel);
		this.toolbar.progressbar_text ("Updating "+ch.title);
		
		if (unreaded > 0)
		{
			this.new_feeds = true;
			this.side.add_unreaded (ch.id, unreaded);
			this.db.insert_items (ch.items.nth (ch.items.length () - unreaded), channel);
			
			if (this.selection_tree () == channel)
				this.load_channel ();
		}
		else if (unreaded == -1)
		{
			this.side.set_error (ch.id);
		}
		else
			this.side.set_empty (ch.id);
		if (this.toolbar.progressbar_progress (1.0 / this.db.channels.length ()) && this.new_feeds)
		{
			Notify.Notification notify = new Notify.Notification ("Feedler News Reader", "There are new feeds to read!", "internet-feed-reader");
			notify.show ();
			this.new_feeds = false;
		}
	}
	
	protected void favicon_all ()
	{
		this.toolbar.progressbar_show ();
		foreach (Feedler.Channel ch in this.db.channels)
		{
			ch.favicon ();
		}
	}
	
	protected void faviconed_channel (int channel, bool state)
	{
		Feedler.Channel ch = this.db.channels.nth_data (channel);
		this.toolbar.progressbar_text ("Favicon for "+ch.title);
		this.toolbar.progressbar_progress (1.0 / this.db.channels.length ());		
		if (state)
			this.side.set_empty (ch.id);
		else
			this.side.set_error (ch.id);
	}
		
	protected void mark_all ()
	{
		stderr.printf ("Feedler.App.mark_all ()\n");
		foreach (Feedler.Channel ch in this.db.channels)
		{
			foreach (Feedler.Item it in ch.items)
			{
				if (it.state == State.UNREADED)
				{
					it.state = State.READED;
					ch.unreaded--;
				}
				else if (ch.unreaded > 0)
					continue;
				else
					break;
			}
			this.side.mark_readed (ch.id);
		}
		this.load_channel ();
	}
	
	protected void mark_channel (int item_id)
	{
		stderr.printf ("Feedler.App.mark_channel ()\n");
		int id = this.selection_tree ();
			
		if (id != -1)
		{
			unowned Feedler.Channel ch = this.db.channels.nth_data (id);
			if (item_id == -1)
			{
				this.side.mark_readed (ch.id);
				foreach (Feedler.Item it in ch.items)
				{
					if (it.state == State.UNREADED)
					{
						it.state = State.READED;
						ch.unreaded--;
					}
					else if (ch.unreaded > 0)
						continue;
					else
						break;
				}
			}
			else
			{
				this.side.dec_unreaded (ch.id);
				ch.unreaded--;
				unowned Feedler.Item it = ch.items.nth_data (ch.items.length () - item_id - 1);
				it.state = State.READED;
			}
		}
	}
	
	protected void change_mode (Gtk.Widget widget)
	{
		stderr.printf ("Feedler.App.change_mode ()\n");
		this.layout.set_current_page (this.toolbar.mode.selected);
		this.view = (Feedler.View)layout.get_nth_page (this.toolbar.mode.selected);
		this.load_channel ();
	}
	
	protected void search_list ()
	{
		stderr.printf ("Feedler.App.search_list ()\n");
		this.view.refilter (this.toolbar.search.get_text ());
	}
	
	protected void load_channel ()
	{
		int id = this.selection_tree ();
		if (id != -1)
			this.load_channel_from_id (id);
	}
	
	private void load_channel_from_id (int channel_id)
	{
		stderr.printf ("Feedler.App.load_channel ()\n");
		this.view.clear ();
		string time_format;
		GLib.Time current_time = GLib.Time.local (time_t ());
		foreach (Feedler.Item item in this.db.channels.nth_data (channel_id).items)
		{
			GLib.Time feed_time = GLib.Time.local (item.time);
			if (feed_time.day_of_year + 6 < current_time.day_of_year)
				time_format = feed_time.format ("%d %B %Y");
			else
				time_format = feed_time.format ("%A %R");

			this.view.add_feed (item, time_format);
		}
		this.view.load_feeds ();
	}
	
	protected void import (string filename)
	{
		try
		{
			this.opml.import (filename, (int)this.db.folders.length (), (int)this.db.channels.length ());
			if (!this.db.created)
			{
				this.ui_welcome_to_workspace ();
				this.db.create ();
			}
			
			this.db.insert_opml (this.opml.get_folders (), this.opml.get_channels ());
			
			foreach (Feedler.Folder folder in this.opml.get_folders ())
			{
				if (folder.parent != -1)
					this.side.add_folder_to_folder (folder.id, folder.name, folder.parent);
				else
					this.side.add_folder (folder.id, folder.name);
			}

			foreach (Feedler.Channel channel in this.opml.get_channels ())
			{
				if (channel.folder != -1)
					this.side.add_channel_to_folder (channel.folder, channel.id, channel.title);
				else
					this.side.add_channel (channel.id, channel.title);
			}
			
			foreach (Feedler.Channel channel in this.db.channels.nth (this.db.channels.length () - this.opml.get_channels ().length ()))
			{
				channel.updated.connect (updated_channel);
				channel.faviconed.connect (faviconed_channel);
			}
			this.side.expand_all ();
			this.update_all ();
		}
		catch (GLib.Error error)
		{
			this.ui_welcome ();
			stderr.printf ("ERROR: %s\n", error.message);
		}
	}
	
	protected void export (string filename)
	{
		try
		{
			this.opml.export (filename, this.db.folders, this.db.channels);
		}
		catch (GLib.Error error)
		{
			stderr.printf ("ERROR: %s\n", error.message);
		}
	}
	
	protected void import_file ()
	{
		var file_chooser = new Gtk.FileChooserDialog ("Open File", this,
                                      Gtk.FileChooserAction.OPEN,
                                      Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                      Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		
		Gtk.FileFilter filter_opml = new Gtk.FileFilter ();
		filter_opml.set_filter_name ("Subscriptions");
		filter_opml.add_pattern ("*.opml");
		filter_opml.add_pattern ("*.xml");
		file_chooser.add_filter (filter_opml);

		Gtk.FileFilter filter_all = new Gtk.FileFilter ();
		filter_all.set_filter_name ("All files");
		filter_all.add_pattern ("*");
		file_chooser.add_filter (filter_all);

        if (file_chooser.run () == Gtk.ResponseType.ACCEPT)
            import (file_chooser.get_filename ());
        file_chooser.destroy ();
        this.show_all ();
	}
	
	protected void export_file ()
	{
		var file_chooser = new Gtk.FileChooserDialog ("Save File", this,
                                      Gtk.FileChooserAction.SAVE,
                                      Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                      Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        if (file_chooser.run () == Gtk.ResponseType.ACCEPT)
            export (file_chooser.get_filename ());
        file_chooser.destroy ();
	}

    public virtual bool add_feed_pressed (Gdk.EventButton event)
    {
		if (event.type == Gdk.EventType.BUTTON_PRESS)
        {
			Feedler.CreateSubs subs = new Feedler.CreateSubs ();
		    subs.set_transient_for (this);
            subs.feed_added.connect (add_feed_added);
		    foreach (Feedler.Folder folder in this.db.folders)
			    subs.add_folder (folder.name);
            subs.show_all ();
		}
		return false;
	}

    public virtual bool edit_feed_pressed (Gdk.EventButton event)
    {
		if (event.type == Gdk.EventType.BUTTON_PRESS)
        {
            int id = this.selection_tree ();
            if (id != -1)
            {
			    Feedler.CreateSubs subs = new Feedler.CreateSubs ();
		        subs.set_transient_for (this);
                subs.feed_added.connect (add_feed_added);
		        foreach (Feedler.Folder folder in this.db.folders)
			        subs.add_folder (folder.name);
                subs.show_all ();
            }
            else
            {
                var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "Please first select channel to edit.");
                info.run ();
                info.destroy ();
            }
		}
		return false;
	}

    public virtual bool del_feed_pressed (Gdk.EventButton event)
    {
		if (event.type == Gdk.EventType.BUTTON_PRESS)
        {
            int id = this.selection_tree ();
            if (id != -1)
            {
                Gtk.MessageDialog info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Are you sure you want to delete this channel?");
			    if (info.run () == Gtk.ResponseType.YES)
			    {
				    this.side.remove_channel (id);
				    this.db.remove_subscription (id, this.db.channels.nth_data (id).id_db);
				    for (uint i = this.db.channels.length ()-1; i >= id; i--)
					    this.db.channels.nth_data (i).id--;
			    }
                info.destroy ();
            }
            else
            {
                var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, "Please first select channel to delete.");
                info.run ();
                info.destroy ();
            }
		}
		return false;
	}

    public virtual bool mark_feed_pressed (Gdk.EventButton event)
    {
		if (event.type == Gdk.EventType.BUTTON_PRESS)
        {
			stderr.printf ("Feedler.App.mark_all ()\n");
		    foreach (Feedler.Channel ch in this.db.channels)
		    {
			    foreach (Feedler.Item it in ch.items)
			    {
				    if (it.state == State.UNREADED)
				    {
					    it.state = State.READED;
					    ch.unreaded--;
				    }
				    else if (ch.unreaded > 0)
					    continue;
				    else
					    break;
			    }
			    this.side.mark_readed (ch.id);
		    }
		    this.load_channel ();
		}
		return false;
	}

    public virtual void add_feed_added (int folder, string url)
    {
        this.create_subscription (url, folder);
    }
	
	protected void config ()
	{
		Feedler.Preferences pref = new Feedler.Preferences ();
		pref.favicons.connect (favicon_all);
		if (pref.run () == Gtk.ResponseType.APPLY)
		{
			stderr.printf ("Preferences");
			pref.save ();
        }
        pref.favicons.disconnect (favicon_all);
        pref.destroy ();
	}
	
	protected void create_subscription (string url, int folder)
	{
		stderr.printf ("create_\n");
		Feedler.Channel.last_id = folder;
        Soup.Message msg = new Soup.Message("GET", url);
        Feedler.Channel.session.queue_message (msg, create_subscription_func);
	}
	
	public void create_subscription_func (Soup.Session session, Soup.Message message)
	{
		stderr.printf ("create_func\n");
		string rss = (string) message.response_body.data;
		
		if (rss != null)
		{
			unowned Xml.Doc doc = Xml.Parser.parse_memory (rss, rss.length);
			Feedler.Parser parser = new Feedler.Parser ();
			Feedler.Channel channel = parser.parse_new (doc);
			channel.source = message.get_uri ().to_string (false);
			channel.folder = Feedler.Channel.last_id;
			this.db.insert_subscription (ref channel);
			if (channel.folder != -1)
				this.side.add_channel_to_folder (channel.folder, channel.id, channel.title);
			else
				this.side.add_channel (channel.id, channel.title);
			this.side.select_channel (channel.id);
			this.side.add_unreaded (channel.id, channel.unreaded);
			this.load_channel ();
			channel.favicon ();
		}
	}
	
	protected void sidebar_update ()
	{
		if (this.toolbar.sidebar_visible.active)
			this.scroll_side.show ();
		else
			this.scroll_side.hide ();
	}
	
	protected void fullscreen_mode ()
	{
		if (this.toolbar.fullscreen_mode.active)
			this.fullscreen ();
		else
			this.unfullscreen ();
	}
	
	private bool context_menu (Gdk.EventButton e)
	{
		if (e.button != 3)
			return false;
		Gtk.TreePath path;
		Gtk.TreeViewColumn column;
		int cell_x;
		int cell_y;
		if (this.side.get_path_at_pos ((int) e.x, (int) e.y, out path, out column, out cell_x, out cell_y))
		{
			this.side.select_path (path);
			this.context.popup (null, null, null, e.button, e.time);
			return true;
		}
		return false;
	}
	
	protected void delete_channel ()
	{
		Gtk.MessageDialog info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT, Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, "Are you sure you want to delete this channel?");
		int id = this.selection_tree ();
		if (id != -1)
			if (info.run () == Gtk.ResponseType.YES)
			{
				this.side.remove_channel (id);
				this.db.remove_subscription (id, this.db.channels.nth_data (id).id_db);
				for (uint i = this.db.channels.length ()-1; i >= id; i--)
					this.db.channels.nth_data (i).id--;
			}
		info.destroy ();
	}
}
