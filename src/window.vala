/**
 * window.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
//TODO data/icon dodac w cmake
public class Feedler.Window : Gtk.Window
{
	internal Feedler.Database db;
	internal Feedler.Toolbar toolbar;
	internal Feedler.Infobar infobar;
	internal Feedler.Sidebar side;
	internal Feedler.Statusbar stat;
	private weak Feedler.View view;
	private Granite.Widgets.ThinPaned pane;
	private Gtk.Box content;
	private Feedler.Layout layout;
    private Feedler.Client client;
	private Feedler.Manager manager;

	static construct
	{
		new Feedler.Icons ();
	}
	
	construct
	{
        
		this.db = new Feedler.Database ();
		this.manager = new Feedler.Manager (this);
		this.layout = new Feedler.Layout ();
		this.delete_event.connect (destroy_app);
		this.content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);	
        this.ui_layout ();
        this.set_default_size (Feedler.STATE.window_width, Feedler.STATE.window_height);

		if (this.db.is_created ())
			this.ui_feeds ();
		else
			this.ui_welcome ();		
		
		this.add (content);
		this.try_connect ();
	}
	
	internal void try_connect ()
	{
		try
        {
            client = Bus.get_proxy_sync (BusType.SESSION, "org.example.Feedler",
                                                        "/org/example/feedler");
            /*client.iconed.connect (favicon_cb);
			client.added.connect (added_cb);           
            client.updated.connect (updated_cb);*/
			client.imported.connect ((f) =>
			{
				this.manager.import.begin (f, (o, r) =>
				{
					if (this.manager.end ())
						this.notification (_("Imported %i channels in %i folders.").printf (this.manager.news, this.manager.folders.length ()));
					this.load_sidebar ();
					this.manager.news = 0;
        		});
			});
			client.updated.connect ((c) =>
			{
				this.manager.update.begin (c, (o, r) =>
				{
					if (this.manager.end ())
						this.notification ("%i %s".printf (this.manager.news, (this.manager.news > 1) ? _("new feeds") : _("new feed")));
					//this.load_sidebar ();
					//var result = this.manager.update.end (r);
        		});
			});
			stderr.printf ("%s\n", client.ping ());
			//TODO nie widzi w DBus, chyba nie am czegos aktualnego..
			//Serializer.Folder[] data = client.get_data ();
			
			//this.infobar.info (new Feedler.ConnectedTask ());
        }
        catch (GLib.Error e)
        {
			stderr.printf (e.message);
			this.infobar.warning (new Feedler.ReconnectTask (this.try_connect));
        }
	}
    
    private void ui_layout ()
    {
		this.toolbar = new Feedler.Toolbar ();
		this.toolbar.mode.selected = 0;
		this.content.pack_start (toolbar, false, false, 0);	
		this.toolbar.update.clicked.connect (update_subscription);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.mode.selected = Feedler.STATE.view_mode;
        this.toolbar.search.activate.connect (item_search);
		/*this.toolbar.sharemenu.clicked.connect (() =>
		{
			if (this.view.contract ())
				this.toolbar.sharemenu.switch_state (true);
			else
				this.toolbar.sharemenu.switch_state (false);
		});
        this.toolbar.sharemenu.export.activate.connect (_export);*/
        this.toolbar.preferences.activate.connect (config);
        this.toolbar.sidebar_visible.toggled.connect (sidebar_update);
        this.toolbar.fullscreen_mode.toggled.connect (fullscreen_mode);

		this.infobar = new Feedler.Infobar ();        
        this.content.pack_start (infobar, false, false, 0);

		this.side = new Feedler.Sidebar ();
		this.side.item_selected.connect (channel_selected);
		this.pane = new Granite.Widgets.ThinPaned ();
		this.pane.expand = true;
        this.content.pack_start (pane, true);
		this.pane.pack2 (layout, true, false);
    }

	private void ui_workspace ()
	{
        this.pane.set_position (Feedler.STATE.sidebar_width);
		this.pane.pack1 (side, true, false);
        this.layout.init_views ();
		this.view = (Feedler.View)layout.get_nth_page (1);
		this.layout.list.item_marked.connect (item_mark);
		//this.layout.web.item_marked.connect (item_mark);

        this.stat = new Feedler.Statusbar ();
		this.stat.add_feed.folder.activate.connect (add_folder);
		this.stat.add_feed.subscription.activate.connect (add_subscription);
		this.stat.add_feed.import.activate.connect (import_subscription);
		this.stat.mark_feed.button_press_event.connect ((e) =>
		{
			this.all_mark ();
			return false;
		});
		this.stat.next_feed.button_press_event.connect ((e) =>
		{
			this.item_next ();
			return false;
		});
        this.content.pack_end (this.stat, false, true, 0);
		this.show_all ();
	}
	
	private void ui_feeds ()
	{
		this.ui_workspace ();
		this.db.select_data ();
		this.load_sidebar ();
	}
	
	private void ui_welcome ()
	{
		this.toolbar.set_enable (false);
        this.pane.set_position (0);
        this.layout.init_welcome ();
		this.layout.welcome.activated.connect ((i) =>
		{
			switch (i)
			{
				//case 0: this.add_subscription (); break;
				//case 1: this.import_subscription (); break;
				case 0: this.import_subscription (); break;
			}
		});
	}
	
	private void ui_welcome_to_workspace ()
	{
		this.toolbar.set_enable (true);
        this.layout.reinit ();
		this.ui_workspace ();
	}

	private void load_sidebar ()
	{
		//TODO import nowych zrodel moze wymagac przeczyszczenia i reinicjalizacji
		//this.side.root.clear ();
		//this.side.init ();
		int unread = 0;
		foreach (Model.Folder f in this.db.data)
		{
			var folder = new Granite.Widgets.SourceList.ExpandableItem (f.name);
			this.side.root.add (folder);
			foreach (Model.Channel c in f.channels)
			{
				folder.add (create_channel (c));
				unread += c.unread;
			}
		}
		this.side.root.expand_all ();
		this.manager.unread (unread);
	}

	private Feedler.SidebarItem create_channel (Model.Channel c)
	{
		string path = "%s/feedler/fav/%i.png".printf (GLib.Environment.get_user_data_dir (), c.id);
		Feedler.SidebarItem channel = null;				
		if (GLib.FileUtils.test (path, GLib.FileTest.EXISTS))
			channel = new Feedler.SidebarItem (c.title, new GLib.FileIcon (GLib.File.new_for_path (path)), c.unread, true);
		else
			channel = new Feedler.SidebarItem (c.title, Feedler.Icons.RSS, c.unread, true);
		//channel.update.activate.connect ();
		channel.mark.activate.connect (channel_mark);
		channel.rename.activate.connect (channel_rename);
		channel.remove.activate.connect (channel_remove);
		channel.edited.connect (channel_rename_cb);
		//channel.edit.activate.connect ();
		return channel;
	}
	
	/* Events */
	private void change_mode (Gtk.Widget widget)
	{
		if (this.toolbar.mode.selected+1 == Feedler.Views.COLUMN)
			this.view = (Feedler.View)layout.get_nth_page (1);
		else
			this.view = (Feedler.View)layout.get_nth_page (this.toolbar.mode.selected+1);
		
		if (this.side.selected != null)
			this.channel_selected (this.side.selected);
	}

	private void config ()
	{
		Feedler.Preferences pref = new Feedler.Preferences ();
		//pref.update.fav.clicked.connect (_favicon_all);
		pref.run ();
        //pref.update.fav.clicked.disconnect (_favicon_all);
        pref.destroy ();
	}
	
	private void sidebar_update ()
	{
		if (this.toolbar.sidebar_visible.active)
			this.side.show ();
		else
			this.side.hide ();
	}
	
	private void fullscreen_mode ()
	{
		if (this.toolbar.fullscreen_mode.active)
			this.fullscreen ();
		else
			this.unfullscreen ();
	}

	private void channel_rename ()
	{
		this.side.start_editing_item (this.side.selected);
	}

	private void channel_rename_cb (string new_name)
	{
		var c = this.side.selected;
		if (new_name != c.name)
		{
			Model.Channel ch = this.db.get_channel (c.name);
			ch.title = new_name;
			this.infobar.question (new Feedler.RenameTask (this.db, c, ch, c.name));
		}
	}

	private void channel_remove ()
	{
		var c = this.side.selected;
		c.visible = false;
		this.infobar.question (new Feedler.RemoveTask (this.db, c));
	}

	private void channel_mark ()
	{
		var c = this.side.selected;
		int diff = (c.badge != null) ? int.parse (c.badge)*(-1) : 0;
		this.manager.unread (diff);
		c.badge = null;
		this.db.mark_channel (c.name);
	}

	internal void channel_mark_update (string title, int unread)
	{
		var ch = this.side.selected;
		if (ch.name == title)
			this.channel_selected (ch);
		foreach (var f in this.side.root.children)
		{
			var expandable = f as Granite.Widgets.SourceList.ExpandableItem;
            if (expandable != null)
				foreach (var c in expandable.children)
					if (c.name == title)
					{
						c.badge = unread.to_string ();
						return;
					}
		}
	}

	private void all_mark ()
    {
		this.manager.unread (this.manager.count*(-1));
		this.side.unread.badge = null;
		foreach (var f in this.side.root.children)
		{
			var expandable = f as Granite.Widgets.SourceList.ExpandableItem;
            if (expandable != null)
				foreach (var c in expandable.children)
					c.badge = null;
		}
		this.db.mark_all ();
		if (this.side.selected != null)
			this.channel_selected (this.side.selected);
    }

	private void item_mark (int id, Model.State state)
    {
		stderr.printf ("item_mark\n");
		var ch = this.side.selected;
		unowned Model.Channel c = this.db.get_channel (ch.name);
		unowned Model.Item it;
		bool nakurwiacz = true;
		if (c != null)
		{
			it = c.get_item (id);
			//TODO tutaj zrob cos zeby ta dziwka nie wywolywala channel selected
			nakurwiacz = false;
		}
		else
		{
			it = this.db.get_item_from_tmp (id);
			c = it.channel;
		}
		if (state == Model.State.STARRED || state == Model.State.UNSTARRED)
		{
			bool star = (state == Model.State.STARRED) ? true : false;
			it.starred = star;
			this.channel_selected (this.side.selected);
			this.db.star_item (id, star);
			return;
		}

		int diff = 0;
		if (state == Model.State.READ)
			diff--;
		else if (state == Model.State.UNREAD)
			diff++;
		int counter = (ch.badge != null) ? int.parse (ch.badge) + diff : diff;
		if (counter > 0)
			ch.badge = counter.to_string ();
		else
			ch.badge = null;
		this.manager.unread (diff);
		c.unread += diff;
		bool read = (state == Model.State.READ) ? true : false;
		it.read = read;
		this.db.mark_item (id, read);
		if (nakurwiacz)
			this.channel_selected (this.side.selected);
    }

	private void item_search ()
	{
		this.view.refilter (this.toolbar.search.get_text ());
	}

	private void item_next ()
	{
		foreach (var f in this.side.root.children)
		{
			var e = f as Granite.Widgets.SourceList.ExpandableItem;
			foreach (var c in e.children)
				if (c.badge != null && c.badge.strip () != "")
				{
					this.side.selected = c;
					return;
				}
		}
	}

	private void channel_selected (Granite.Widgets.SourceList.Item? channel)
	{
		unowned GLib.List<Model.Item?> items = null;
		if (channel == side.all)
			items = this.db.get_items (Model.State.ALL);
		else if (channel == side.unread)
			items = this.db.get_items (Model.State.UNREAD);
		else if (channel == side.star)
			items = this.db.get_items (Model.State.STARRED);
		else
			items = this.db.get_channel (channel.name).items;
		this.load_view (items);	
	}

	private void load_view (GLib.List<Model.Item?> items)
	{
		stderr.printf ("load_view\n");
		if (items.length () < 1)
		{
			this.layout.display (Feedler.Views.ALERT);
			return;			
		}
		this.layout.display ((Feedler.Views)this.toolbar.mode.selected+1);
	
		this.view.clear ();
		GLib.Time current_time = GLib.Time.local (time_t ());
		foreach (Model.Item item in items)
		{
			GLib.Time feed_time = GLib.Time.local (item.time);
		    if (feed_time.day_of_year + 6 < current_time.day_of_year)
		        this.view.add_feed (item, feed_time.format ("%d %B %Y"));
			else
		        this.view.add_feed (item, feed_time.format ("%A %R"));
		}
		this.view.load_feeds ();
	}

	private void add_folder ()
    {
        Feedler.Folder fol = new Feedler.Folder ();
		fol.set_transient_for (this);
        //fol.saved.connect (create_folder_cb);
        fol.show_all ();
	}

	private void add_subscription ()
    {
        Feedler.Subscription subs = new Feedler.Subscription ();
		subs.set_transient_for (this);
        //subs.saved.connect (create_subs_cb);
		foreach (Model.Folder folder in this.db.data)
		    subs.add_folder (folder.name);
        subs.show_all ();
		//this.stat.add_feed.button_press_event.disconnect (_create_subs);
	}

	private void import_subscription ()
	{
		var file = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN,
                                              Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                              Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		
		Gtk.FileFilter filter_opml = new Gtk.FileFilter ();
		filter_opml.set_filter_name ("Subscriptions");
		filter_opml.add_pattern ("*.opml");
		filter_opml.add_pattern ("*.xml");
		file.add_filter (filter_opml);

		Gtk.FileFilter filter_all = new Gtk.FileFilter ();
		filter_all.set_filter_name ("All files");
		filter_all.add_pattern ("*");
		file.add_filter (filter_all);

        if (file.run () == Gtk.ResponseType.ACCEPT)
        {
			string path = file.get_filename ();
			file.close ();
			this.manager.begin (_("Importing subscriptions"));
            try
            {
                if (!this.db.is_created ())
				{
                    this.db.create ();
	                this.ui_welcome_to_workspace ();
			        this.show_all ();
				}
				this.client.import (path);
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
				this.manager.error ();
            }
        }
        file.destroy ();
	}

	internal void update_subscription ()
	{
        try
        {
            string[] uris = this.db.get_channels_uri ();
			this.manager.begin (_("Updating subscriptions"), uris.length);
            this.client.update_all (uris);
			//this.client.update ("http://iloveubuntu.net/rss.xml");
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
			this.manager.error ();
        }
	}

	private void dialog (string msg, Gtk.MessageType msg_type = Gtk.MessageType.INFO)
    {
         var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           msg_type, Gtk.ButtonsType.OK, msg);
         info.run ();
         info.destroy ();
    }

	private void notification (string msg)
    {
        try
        {
            this.client.notification (msg);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
    }

	private bool destroy_app ()
	{
		if (Feedler.SETTING.hide_close)
		{
			this.hide ();
			return true;
		}
		else
		{
			int width, height;
			get_size (out width, out height);
			Feedler.STATE.window_width = width;
			Feedler.STATE.window_height = height;
			Feedler.STATE.sidebar_width = this.pane.position;
			Feedler.STATE.view_mode = (uint8)this.toolbar.mode.selected;
			return false;
		}
	}
}
/*public class Feedler.Window : Gtk.Window
{
	internal Feedler.Database db;
	internal Feedler.Toolbar toolbar;
	internal Feedler.Infobar infobar;
	//internal Feedler.Sidebar side;
	internal Granite.Widgets.SourceList side;
	internal Feedler.Statusbar stat;
	private Feedler.MenuSide sidemenu;
	private Feedler.History history;
	private weak Feedler.View view;
	//private Gtk.Paned pane;
	private Granite.Widgets.ThinPaned pane;
	private Gtk.Box content;
	private Gtk.ScrolledWindow scroll_side;
	private Feedler.CardLayout layout;
    private Feedler.Client client;
	private Feedler.Manager manager;
	
	construct
	{
        try
        {
            client = Bus.get_proxy_sync (BusType.SESSION, "org.example.Feedler",
                                                        "/org/example/feedler");
            client.iconed.connect (favicon_cb);
			client.added.connect (added_cb);
            client.imported.connect (imported_cb);            
            client.updated.connect (updated_cb);
			stderr.printf ("%s\n", client.ping ());
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
		this.db = new Feedler.Database ();
		this.manager = new Feedler.Manager (this);
		this.layout = new Feedler.CardLayout ();
		this.delete_event.connect (destroy_app);
		this.content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);	
		this.ui_toolbar ();
        this.ui_layout ();
        this.set_default_size (Feedler.STATE.window_width, Feedler.STATE.window_height);

		if (this.db.is_created ())
			this.ui_feeds ();
		else
			this.ui_welcome ();		
		
		this.add (content);
		this.history = new Feedler.History ();
	}
	
	private void ui_toolbar ()
	{
		this.toolbar = new Feedler.Toolbar (); 
		this.infobar = new Feedler.Infobar ();
        this.content.pack_start (toolbar, false, false, 0);
        this.content.pack_start (infobar, false, false, 0);
		this.toolbar.mode.selected = 0;
        this.toolbar.back.clicked.connect (history_prev);
        this.toolbar.forward.clicked.connect (history_next);
        this.toolbar.update.clicked.connect (_update_all);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.column.clicked.connect (change_column);
        this.toolbar.search.activate.connect (search_list);
		this.toolbar.sharemenu.clicked.connect (() =>
		{
			if (this.view.contract ())
				this.toolbar.sharemenu.switch_state (true);
			else
				this.toolbar.sharemenu.switch_state (false);
		}); 
        this.toolbar.sharemenu.export.activate.connect (_export);
        this.toolbar.preferences.activate.connect (config);
        this.toolbar.sidebar_visible.toggled.connect (sidebar_update);
        this.toolbar.fullscreen_mode.toggled.connect (fullscreen_mode);
	}
    
    private void ui_layout ()
    {
		this.side = new Granite.Widgets.SourceList ();
        //this.side = new Feedler.Sidebar ();
		//this.side.button_press_event.connect (context_menu);
		//this.side.cursor_changed.connect (load_channel);
		//this.scroll_side = new Gtk.ScrolledWindow (null, null);
		//this.scroll_side.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		//this.scroll_side.add (side);

        //this.pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		//this.pane.get_style_context().add_class("sidebar-pane-separator");
		this.pane = new Granite.Widgets.ThinPaned ();
		this.pane.expand = true;
        this.content.pack_start (pane, true);
        //this.pane.add2 (layout);
		this.pane.pack2 (layout, true, false);
    }

	private void ui_workspace ()
	{
        this.pane.set_position (Feedler.STATE.sidebar_width);
        //this.pane.add1 (scroll_side);
		this.pane.pack1 (list, true, false);
		
		this.sidemenu = new Feedler.MenuSide ();
		this.sidemenu.add_sub.activate.connect (() => {_create_subs ();});
		this.sidemenu.add_fol.activate.connect (_create_folder);
		this.sidemenu.upd.activate.connect (_update);
		this.sidemenu.mark.activate.connect (_mark);
		this.sidemenu.rem.activate.connect (_remove);
		this.sidemenu.edit.activate.connect (_edit);
		this.sidemenu.show_all ();
        
        this.layout.init_views ();
		this.view = (Feedler.View)layout.get_nth_page (0);
		this.layout.list.item_selected.connect (history_add);
		this.layout.list.item_marked.connect (mark_item);
		this.layout.web.item_marked.connect (mark_item);

        this.stat = new Feedler.Statusbar ();
        //this.stat.add_feed.button_press_event.connect (()=>{_create_subs (); return false;});
		this.stat.add_feed.button_press_event.connect (_create_subs);
        this.stat.delete_feed.button_press_event.connect (()=>{_remove (); return false;});
        this.stat.import_feed.button_press_event.connect (()=>{_import (); return false;});
        this.stat.next_feed.button_press_event.connect (()=>{_next_unread (); return false;});
        this.stat.mark_feed.button_press_event.connect (()=>{_mark_all (); return false;});
        this.content.pack_end (this.stat, false, true, 0);
		
	}
	
	private void ui_feeds ()
	{
		this.ui_workspace ();
		this.side.model = null;
        foreach (var f in this.db.select_folders ())
		{
            //this.side.add_folder (f);
			var folder = new Granite.Widgets.SourceList.ExpandableItem (f.name);
			this.side.root.add (folder);
		}
        foreach (var c in this.db.select_channels ())
		{
            //this.side.add_channel (c.id, c.title, c.folder, c.unread);
			var channel = new Granite.Widgets.SourceList.Item (c.title);
			//channel.badge = (string)c.unread;
			//this.list.root.add (channel);
			this.manager.count += c.unread;
		}
		this.side.model = side.store;
		this.manager.unread ();
		this.side.expand_all ();
	}
	
	private void ui_welcome ()
	{
		this.toolbar.set_enable (false);
        this.pane.set_position (0);
        this.layout.init_welcome ();
		this.layout.welcome.activated.connect (catch_activated);
	}
	
	private void ui_welcome_to_workspace ()
	{
		this.toolbar.set_enable (true);
        this.layout.reinit ();
		this.ui_workspace ();
	}

    internal void notification (string msg)
    {
        try
        {
            this.client.notification (msg);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
    }

    internal void dialog (string msg, Gtk.MessageType msg_type = Gtk.MessageType.INFO)
    {
         var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           msg_type, Gtk.ButtonsType.OK, msg);
         info.run ();
         info.destroy ();
    }
	
	private bool destroy_app ()
	{
		if (Feedler.STATE.hide_close)
		{
			this.hide ();
			return true;
		}
		else
		{
			int width, height;
			get_size (out width, out height);
			Feedler.STATE.window_width = width;
			Feedler.STATE.window_height = height;
			Feedler.STATE.sidebar_width = this.pane.position;
			return false;//Gtk.main_quit ();
		}
	}
	
	protected void catch_activated (int index)
	{
		switch (index)
		{
			case 0: this._create_subs (); break;
			case 1: this._import (); break;
		}
	}
	
	internal int selection_tree ()
	{
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
		{
			ChannelStore channel;
			model.get (iter, 0, out channel);
            if (channel.mode > 0)
			    return channel.id;
		}
		return -1;
	}

    private ChannelStore? selected_item ()
	{
        ChannelStore channel = null;
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
			model.get (iter, 0, out channel);
    	return channel;
	}
	
	protected void history_prev ()
	{
		string side_path = null, view_path = null;
        this.history.prev (out side_path, out view_path);
        this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
        this.load_channel ();
		if (view_path != null)
			this.view.select (new Gtk.TreePath.from_string (view_path));
        this.history_sensitive ();
	}
	
	protected void history_next ()
	{
		string side_path = null, view_path = null;
        this.history.next (out side_path, out view_path);
        this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
        this.load_channel ();
		if (view_path != null)
			this.view.select (new Gtk.TreePath.from_string (view_path));
        this.history_sensitive ();
	}
	
	protected void history_add (string item)
	{	
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
		{
			this.history.add (model.get_path (iter).to_string (), item);
            this.history_sensitive ();
		}
	}

    private void history_sensitive ()
    {
        if (history.current >= 1)
            this.toolbar.back.sensitive = true;
        else
            this.toolbar.back.sensitive = false;

        if (history.current < history.items.size - 1)
            this.toolbar.forward.sensitive = true;
        else
            this.toolbar.forward.sensitive = false;
    }

	private void added_cb (Serializer.Channel channel)
	{
        stderr.printf ("add_cb\n");
        Model.Channel ch = this.db.from_source (channel.source);
		ch.link = channel.link;
		this.db.begin ();
		for (int i = channel.items.length-1; i >= 0; i--)
		{
			int id = this.db.insert_serialized_item (ch.id, channel.items[i]);
            Model.Item it = {id, channel.items[i].title, channel.items[i].source, channel.items[i].author, channel.items[i].description, channel.items[i].time, Model.State.UNREAD, ch.id};
            ch.items.append (it);
		}
        this.db.commit ();
		string description = channel.items.length > 1 ? _("new feeds") : _("new feed");
		this.notification ("%i %s".printf (channel.items.length, description));
		this.side.add_unread (ch.id, channel.items.length);
		this.manager.unread (channel.items.length);
	}

    private void imported_cb (Serializer.Folder[] folders)
	{
        int count = 0;
        this.db.begin ();
        foreach (var f in folders)
        {
			this.manager.progress ();
			int fid = 0;
			if (f.name != "body")
			{
	            fid = this.db.insert_serialized_folder (f);
            	Model.Folder fo = {fid, f.name, 0};
            	this.side.add_folder (fo);
            	this.db.folders.append (fo);
			}
            count += f.channels.length;
            foreach (var c in f.channels)
            {
				int cid = this.db.insert_serialized_channel (fid, c);
                this.side.add_channel (cid, c.title, fid);
                Model.Channel ch = new Model.Channel.with_data (cid, c.title, c.link, c.source, fid);
                this.db.channels.append (ch);
            }
			Gtk.main_iteration ();
        }
        this.db.commit ();
		if (manager.end ())
			this.notification (_("Imported %i channels in %i folders.").printf (count, folders.length-1));
	}

	private void updated_cb (Serializer.Channel channel)
	{
		this.manager.queue (channel);
	}

    private void favicon_cb (string uri, uint8[] data)
	{
        this.manager.progress ();
        Model.Channel c = this.db.from_source (uri);
		try
		{
			var loader = new Gdk.PixbufLoader.with_type ("ico");
            loader.set_size (16, 16);
			loader.write (data);
			loader.close ();
			var pix = loader.get_pixbuf ();
            pix.save ("%s/feedler/fav/%i.png".printf (GLib.Environment.get_user_data_dir (), c.id), "png");
            this.side.set_mode (c.id, 1);
		}
		catch (GLib.Error e)
		{
			stderr.printf ("Cannot get favicon for %s\n", uri);
            this.side.set_mode (c.id, 2);
		}
        this.manager.end ();
	}

	private void mark_item (int id, bool state)
    {
		ChannelStore ch = this.selected_item ();
		if (id > 0)
		{
			this.db.mark_item (ch.id, id, state ? Model.State.UNREAD : Model.State.READ);
			this.side.dec_unread (ch.id, state ? 1 : -1);
			this.manager.unread (state ? 1 : -1);
		}
		else
		{
			this.manager.unread (ch.unread * -1);
			this.db.mark_channel (ch.id);
			this.side.mark_channel (ch.id);
		}        
    }
    	
	protected void change_mode (Gtk.Widget widget)
	{
		stderr.printf ("Feedler.App.change_mode ()\n");
		this.layout.set_current_page (this.toolbar.mode.selected);
		this.view = (Feedler.View)layout.get_nth_page (this.toolbar.mode.selected);
        if (this.view.type () == Feedler.Views.WEB)
            this.toolbar.column.set_sensitive (false);
        else
            this.toolbar.column.set_sensitive (true);
		this.load_channel ();
	}

    protected void change_column ()
	{
        if (this.view.type () == Feedler.Views.LIST)
            this.view.change ();
	}
	
	protected void search_list ()
	{
		stderr.printf ("Feedler.App.search_list ()\n");
		this.view.refilter (this.toolbar.search.get_text ());
	}
	
	internal void load_channel ()
	{
		stderr.printf ("Feedler.load_channel ()\n");
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		
		if (this.side.get_selection ().get_selected (out model, out iter))
		{
			ChannelStore channel;
			model.get (iter, 0, out channel);
            if (channel.mode > 0)
			{
				this.view.clear ();
				GLib.Time current_time = GLib.Time.local (time_t ());
				foreach (Model.Item item in this.db.get_channel (channel.id).items)
				{
					GLib.Time feed_time = GLib.Time.local (item.time);
				    if (feed_time.day_of_year + 6 < current_time.day_of_year)
				        this.view.add_feed (item, feed_time.format ("%d %B %Y"));
					else
				        this.view.add_feed (item, feed_time.format ("%A %R"));
				}
				this.view.load_feeds ();
			}
			else
			{
				Gtk.TreePath? path = model.get_path (iter);
				if (this.side.is_row_expanded (path))
					this.side.collapse_row (path);
				else
					this.side.expand_row (path, false);
			}
		}
	}
	
	protected void config ()
	{
		Feedler.Preferences pref = new Feedler.Preferences ();
		pref.update.fav.clicked.connect (_favicon_all);
		pref.run ();
        pref.update.fav.clicked.disconnect (_favicon_all);
        pref.destroy ();
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
		int cell_x, cell_y;
		if (this.side.get_path_at_pos ((int) e.x, (int) e.y, out path, out column, out cell_x, out cell_y))
		{
			this.side.select_path (path);
			this.sidemenu.popup (null, null, null, e.button, e.time);
			this.load_channel ();
			return true;
		}
		return false;
	}
// 
    internal void _update_all ()
	{
        try
        {
            string[] uris = this.db.get_uris ();
			this.manager.start (_("Updating subscriptions"), uris.length);
            this.client.update_all (uris);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
			this.manager.error ();
        }
	}

    private void _update ()
    {
        ChannelStore ch = this.selected_item ();
        if (ch != null)
        {
            try
            {
                if (ch.mode == 1)
                {
				    Model.Channel c = this.db.get_channel (ch.id);
					this.manager.start (_("Updating %s").printf (c.title));
                    this.client.update (c.source);
			    }
                else
                {
                    string[] uris = this.db.get_folder_uris (ch.id);
					this.manager.start (_("Updating subscriptions"), uris.length);
                    this.client.update_all (uris);
			    }
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
	            this.manager.error ();
            }
        }
	}

    private void _favicon_all ()
	{
        try
        {
            string[] uris = this.db.get_uris ();
			this.manager.start (_("Downloading favicons"), uris.length);
            this.client.favicon_all (uris);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
            this.manager.error ();
        }
	}

    private void _favicon ()
	{
        try
        {
            int id = this.selection_tree ();
   			this.manager.start (_("Downloading favicons"));
            this.client.favicon (this.db.get_channel (id).source);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
            this.manager.error ();
        }
	}

    private void _import ()
	{
		var file = new Gtk.FileChooserDialog ("Open File", this, Gtk.FileChooserAction.OPEN,
                                              Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                              Gtk.Stock.OPEN, Gtk.ResponseType.ACCEPT);
		
		Gtk.FileFilter filter_opml = new Gtk.FileFilter ();
		filter_opml.set_filter_name ("Subscriptions");
		filter_opml.add_pattern ("*.opml");
		filter_opml.add_pattern ("*.xml");
		file.add_filter (filter_opml);

		Gtk.FileFilter filter_all = new Gtk.FileFilter ();
		filter_all.set_filter_name ("All files");
		filter_all.add_pattern ("*");
		file.add_filter (filter_all);

        if (file.run () == Gtk.ResponseType.ACCEPT)
        {
            try
            {
                this.client.import (file.get_filename ());
                if (!this.db.is_created ())
				{
                    this.db.create ();
	                this.ui_welcome_to_workspace ();
			        this.show_all ();
				}
				this.manager.start (_("Importing subscriptions"));
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
				this.manager.error ();
            }
        }
        file.destroy ();
	}

	private void _export ()
	{
		var file = new Gtk.FileChooserDialog ("Save File", this, Gtk.FileChooserAction.SAVE,
                                              Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                              Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        if (file.run () == Gtk.ResponseType.ACCEPT)
		{
			try
			{
                uint8[] data = this.db.export_to_opml ().data;
                string s;
                file.get_file ().replace_contents (data, null, false, 0, out s);
			}
			catch (GLib.Error e)
			{
				stderr.printf ("Cannot create opml file %s\n", file.get_filename ());
			}
		}
        file.destroy ();
	}

    private void _create_folder ()
    {
        Feedler.Folder fol = new Feedler.Folder ();
		fol.set_transient_for (this);
        fol.saved.connect (create_folder_cb);
        fol.show_all ();
	}

	private bool _create_subs ()
    {
        Feedler.Subscription subs = new Feedler.Subscription ();
		subs.set_transient_for (this);
        subs.saved.connect (create_subs_cb);
		foreach (Model.Folder folder in this.db.folders)
		    subs.add_folder (folder.name);
        subs.show_all ();
		this.stat.add_feed.button_press_event.disconnect (_create_subs);
		return false;
	}

    private void _mark ()
    {
        var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                          Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, 
                                          _("Are you sure you want to mark as read?"));
        ChannelStore ch = this.selected_item ();
        if (ch != null)
            if (info.run () == Gtk.ResponseType.YES)
				if (ch.mode == 1)
                {
					this.manager.unread (ch.unread * -1);
				    this.side.mark_channel (ch.id);
				    this.db.mark_channel (ch.id);
			    }
                else
                {
				    this.side.mark_folder (ch.id);
				    this.db.mark_folder (ch.id);
			    }
		info.destroy ();
    }

	private void _mark_all ()
    {
        var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                          Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, 
                                          _("Are you sure you want to mark as read?"));
		if (info.run () == Gtk.ResponseType.YES)
		{
			foreach (Model.Channel c in this.db.channels)
			{
			   	this.side.mark_channel (c.id);
			}
			this.manager.count = 0;
			this.manager.unread ();
			//this.load_channel ();
			this.db.mark_all ();
		}
		info.destroy ();
    }
	
    private void _remove ()
    {
        var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                          Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, 
                                          _("Are you sure you want to delete?"));
        ChannelStore ch = this.selected_item ();
        if (ch != null)
            if (info.run () == Gtk.ResponseType.YES)
			    if (ch.mode == 1)
                {
				    this.side.remove_channel (ch.id);
				    this.db.remove_channel (ch.id);
			    }
                else
                {
				    this.side.remove_folder (ch.id);
				    this.db.remove_folder (ch.id);
			    }
		info.destroy ();
    }

    private void _edit ()
    {
        ChannelStore ch = this.selected_item ();
        if (ch != null)
            if (ch.mode == 1)
            {
			    Feedler.Subscription subs = new Feedler.Subscription ();
		        subs.set_transient_for (this);
                subs.saved.connect (edit_subs_cb);
                subs.favicon.clicked.connect (this._favicon);
		        foreach (Model.Folder folder in this.db.folders)
			        subs.add_folder (folder.name);
                Model.Channel c = this.db.get_channel (ch.id);
                subs.set_model (c.id, c.title, c.source, c.folder);
                subs.show_all ();
			}
            else
            {
                Feedler.Folder fol = new Feedler.Folder ();
		        fol.set_transient_for (this);
                fol.saved.connect (edit_folder_cb);
                Model.Folder f = this.db.get_folder (ch.id);
                fol.set_model (f.id, f.name);
                fol.show_all ();
			}
	}

	private void _next_unread ()
	{	
		stderr.printf ("Feedler.App.next_unread ()\n");
		foreach (Model.Channel ch in this.db.channels)
		{
			if (ch.unread > 0)
			{
				this.side.select_channel (ch.id);
				this.load_channel ();
				break;
			}
		}
	}

    private void create_subs_cb (int id, int folder, string title, string url)
    {
		this.stat.add_feed.button_press_event.connect (_create_subs);
		if (id == -1 && folder == -1)
			return;
		try
		{
			if (!this.db.is_created ())
			{
		    	this.db.create ();
			    this.ui_welcome_to_workspace ();
				this.show_all ();
			}
		    int i = this.db.add_channel (title, url, folder);
		    this.side.add_channel (i, title, folder);
			this.client.add (url);
		}
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
    }

    private void create_folder_cb (int id, string title)
    {
        int i = this.db.add_folder (title);
        this.side.add_folder_ (i, title, 0);
    }

    private void edit_subs_cb (int id, int folder, string title, string url)
    {
        this.side.update_channel (id, title, folder);
        this.db.update_channel (id, folder, title, url);
    }

    private void edit_folder_cb (int id, string name)
    {
        this.side.update_folder (id, name);
        this.db.update_folder (id, name);
    }
}
*/
