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
	internal Feedler.Toolbar toolbar;
	private Feedler.Sidebar side;
	private Feedler.Statusbar stat;
	private Feedler.MenuSide sidemenu;
	private Feedler.History history;
	private weak Feedler.View view;
	private Gtk.Paned pane;
	private Gtk.Box content;
	private Gtk.ScrolledWindow scroll_side;
	private Feedler.CardLayout layout;
    private Feedler.Client client;
    private int connections;
    private int unread;
	
	construct
	{
        try
        {
            client = Bus.get_proxy_sync (BusType.SESSION, "org.example.Feedler",
                                                        "/org/example/feedler");
            client.imported.connect (imported_cb);            
            client.updated.connect (updated_cb);
            this.dialog (client.ping (), Gtk.MessageType.INFO);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
		this.settings = new Feedler.Settings ();
		this.db = new Feedler.Database ();
		this.layout = new Feedler.CardLayout ();
		this.destroy.connect (destroy_app);
		this.set_default_size (settings.width, settings.height);
		this.set_size_request (820, 520);
		this.content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);	
		this.ui_toolbar ();
        this.ui_layout ();
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
        this.content.pack_start (toolbar, false, false, 0);
        
        this.toolbar.back.clicked.connect (history_prev);
        this.toolbar.forward.clicked.connect (history_next);
        this.toolbar.update.clicked.connect (update_all);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.column.clicked.connect (change_column);
        this.toolbar.search.activate.connect (search_list); 
        
        this.toolbar.import_feeds.activate.connect (import_file);
        this.toolbar.export_feeds.activate.connect (export_file);
        this.toolbar.preferences.activate.connect (config);
        this.toolbar.sidebar_visible.toggled.connect (sidebar_update);
        this.toolbar.fullscreen_mode.toggled.connect (fullscreen_mode);
	}
    
    private void ui_layout ()
    {
        this.side = new Feedler.Sidebar ();
		this.side.button_press_event.connect (context_menu);
		this.scroll_side = new Gtk.ScrolledWindow (null, null);
		this.scroll_side.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		this.scroll_side.add (side);

        this.pane = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);
		this.pane.get_style_context().add_class("sidebar-pane-separator");
        this.content.pack_start (pane, true);
        this.pane.add2 (layout);
    }

	private void ui_workspace ()
	{
		this.toolbar.mode.selected = 0;
        this.pane.set_position (settings.hpane_width);
        this.pane.add1 (scroll_side);
		
		this.sidemenu = new Feedler.MenuSide ();
		this.sidemenu.add_sub.activate.connect (create_subscription);
		this.sidemenu.upd.activate.connect (update_subscription);
		this.sidemenu.mark.activate.connect (mark_subscription);
		this.sidemenu.rem.activate.connect (remove_subscription);
		this.sidemenu.edit.activate.connect (edit_subscription);
		this.sidemenu.show_all ();		
        
        this.layout.init_views ();
        //this.layout.list.item_readed.connect (mark_channel);
        //this.layout.web.item_readed.connect (mark_channel);
		this.view = (Feedler.View)layout.get_nth_page (0);
		this.view.item_selected.connect (history_add);
		this.view.item_browsed.connect (history_remove);

        this.stat = new Feedler.Statusbar ();
        this.stat.add_feed.button_press_event.connect (()=>{create_subscription (); return false;});
        this.stat.delete_feed.button_press_event.connect (()=>{remove_subscription (); return false;});
        this.stat.mark_feed.button_press_event.connect (()=>{mark_subscription (); return false;});
        this.content.pack_end (this.stat, false, true, 0);
	}
	
	private void ui_feeds ()
	{
		this.ui_workspace (); 
        
        foreach (Model.Folder f in this.db.select_folders ())
        {
            this.side.add_folder (f);
        }

        foreach (Model.Channel c in this.db.select_channels ())
		{
            this.side.add_channel (c.id, c.title, c.folder);
		}
		
		this.side.expand_all ();
		this.side.cursor_changed.connect (load_channel);
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
		//this.ui_workspace ();
        this.ui_feeds ();
	}

    private void dialog (string msg, Gtk.MessageType msg_type = Gtk.MessageType.INFO)
    {
         var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           msg_type, Gtk.ButtonsType.OK, msg);
         info.run ();
         info.destroy ();
    }
	
	protected void destroy_app ()
	{
        Gtk.Allocation alloc;
        get_allocation(out alloc);
        settings.width = alloc.width;
        settings.height = alloc.height;
        settings.hpane_width = this.pane.position;
		
		Gtk.main_quit ();
	}
	
	protected void catch_activated (int index)
	{
        stderr.printf ("\n%i\n", this.pane.get_position ());
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

    private ChannelStore? selected_item ()
	{
		Gtk.TreeModel model;
		Gtk.TreeIter iter;
		Gtk.TreeSelection selection = this.side.get_selection ();
		
		if (selection.get_selected (out model, out iter))
		{
			ChannelStore channel;
			model.get (iter, 0, out channel);
			return channel;
		}
		else
			return null;
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
		
	protected void update_all ()
	{
        try
        {
            string[] uris = this.db.get_uris ();
            this.connections = uris.length;
            this.client.update_all (uris);
            this.toolbar.progress.clear ();
            this.toolbar.progressbar (1.0 / this.db.channels.length (), "Updating");
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
	}

    protected void imported_cb (Serializer.Folder[] folders)
	{
        int count = 0;
        this.db.begin ();
        foreach (var f in folders)
        {
            this.toolbar.progressbar (1.0 / folders.length, "Importing " + f.name);
            int fid = this.db.insert_serialized_folder (f);
            Model.Folder fo = {fid, f.name, 0};
            this.side.add_folder (fo);
            this.db.folders.append (fo);
            count += f.channels.length;
            foreach (var c in f.channels)
            {
                int cid = this.db.insert_serialized_channel (fid, c);
                this.side.add_channel (cid, c.title, fid);
                Model.Channel ch = new Model.Channel.with_data (cid, c.title, c.link, c.source, fid);
                this.db.channels.append (ch);
            }
        }
        this.db.commit ();
        this.client.notification (_("Imported %i channels in %i folders.").printf (count, folders.length));
	}
	
	protected void updated_cb (Serializer.Channel channel)
	{
        //stderr.printf ("updated_cb\n");
        Model.Channel ch = this.db.from_source (channel.source);
        this.toolbar.progressbar (1.0 / this.db.channels.length (), "Updating " + ch.title);
        GLib.List<Serializer.Item?> reverse = new GLib.List<Serializer.Item?> ();
        string last;
        if (ch.items.length () > 0)
            last = ch.items.last ().data.title;
        else
            last = "";
        foreach (var i in channel.items)
        {
            if (last == i.title)
                break;
            reverse.append (i);
        }
        reverse.reverse ();
        this.db.begin ();
        foreach (var i in reverse)
        {
            int id = this.db.insert_serialized_item (ch.id, i);
            Model.Item it = {id, i.title, i.source, i.author, i.description, i.time, Model.State.UNREAD, ch.id};
            ch.items.append (it);
        }
        this.db.commit ();
        this.connections--;
        this.unread += (int)reverse.length ();
		if (unread > 0)
		{
			this.side.add_unread (ch.id, (int)reverse.length ());			
			if (this.selection_tree () == ch.id)
				this.load_channel ();
		}
		else
			this.side.set_empty (ch.id);
        if (connections == 0)
        {
            this.client.notification (_("%i new feeds.").printf (unread));
            this.stat.set_unread (unread);
            this.unread = 0;
        }
	}
	
	protected void favicon_all ()
	{
		this.toolbar.progressbar (1.0 / this.db.channels.length (), "Faviconing");
		foreach (Model.Channel ch in this.db.channels)
		{
			//ch.favicon ();
		}
	}
	
	protected void faviconed_channel (int channel, bool state)
	{
		Model.Channel ch = this.db.channels.nth_data (channel);
		this.toolbar.progressbar (1.0 / this.db.channels.length (), "Favicon for "+ch.title);		
		if (state)
			this.side.set_empty (ch.id);
		else
			this.side.set_error (ch.id);
	}
		
	protected void mark_all ()
	{
		stderr.printf ("Feedler.App.mark_all ()\n");
		foreach (Model.Channel ch in this.db.channels)
		{
			foreach (Model.Item it in ch.items)
			{
				if (it.state == Model.State.UNREAD)
				{
					it.state = Model.State.READ;
					//ch.unread--;
				}
				//else if (ch.unread > 0)
				//	continue;
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
			Model.Channel ch = this.db.get_channel (id);
			if (item_id == -1)
			{
				this.side.mark_readed (ch.id);
				foreach (Model.Item it in ch.items)
				{
					if (it.state == Model.State.UNREAD)
					{
						it.state = Model.State.READ;
                        this.db.mark_item (it.id);
					}
					else
						break;
				}
			}
			else
			{
				this.side.dec_unread (ch.id);
                this.db.mark_item (item_id);
                Model.Item it = ch.get_item (item_id);
				it.state = Model.State.READ;
			}
		}
	}
	
	protected void change_mode (Gtk.Widget widget)
	{
		stderr.printf ("Feedler.App.change_mode ()\n");
		this.layout.set_current_page (this.toolbar.mode.selected);
		this.view = (Feedler.View)layout.get_nth_page (this.toolbar.mode.selected);
        if (this.view.to_type () == 2)
            this.toolbar.column.set_sensitive (false);
        else
            this.toolbar.column.set_sensitive (true);
		this.load_channel ();
	}

    protected void change_column ()
	{
        if (this.view.to_type () == 1)
            this.view.change ();
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
		stderr.printf ("Feedler.App.load_channel (%i)\n", channel_id);
		this.view.clear ();
		GLib.Time current_time = GLib.Time.local (time_t ());
		foreach (Model.Item item in this.db.get_channel (channel_id).items)
		{
//stderr.printf ("Stan: %s-%i", item.title, item.state);
			GLib.Time feed_time = GLib.Time.local (item.time);
            if (feed_time.day_of_year + 6 < current_time.day_of_year)
                this.view.add_feed (item, feed_time.format ("%d %B %Y"));
			else
                this.view.add_feed (item, feed_time.format ("%A %R"));
		}
		this.view.load_feeds ();
	}
	
	protected void import (string filename)
	{
        try
        {
            this.client.import (filename);
            if (!this.db.is_created ())
                this.db.create ();
            this.ui_welcome_to_workspace ();
            this.toolbar.progressbar (0.1, "Importing subscriptions");
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
	}
	
	protected void export (string filename)
	{
		//TODO
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
			this.sidemenu.popup (null, null, null, e.button, e.time);
			return true;
		}
		return false;
	}
/* **************************************************************************** */
    private void create_subscription ()
    {
        Feedler.CreateSubs subs = new Feedler.CreateSubs ();
		subs.set_transient_for (this);
        subs.created.connect (created_cb);
		foreach (Model.Folder folder in this.db.folders)
		    subs.add_folder (folder.name);
        subs.show_all ();
	}

    private void created_cb (int folder, string url)
    {
        //TODO create subs
    }

    private void update_subscription ()
    {
        ChannelStore ch = this.selected_item ();
        if (ch != null)
        {
            try
            {
                Model.Channel c = this.db.get_channel (ch.id);
                this.client.update (c.source);
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
            }
        }
	}

    private void mark_subscription ()
    {
        var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                          Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, 
                                          _("Are you sure you want to mark this subscription as read?"));
		int id = this.selection_tree ();
		if (id != -1)
			if (info.run () == Gtk.ResponseType.YES)
			{
				this.side.mark_channel (id);
				this.db.mark_channel (id);
			    //this.load_channel ();
			}
		info.destroy ();
    }
	
    private void remove_subscription ()
    {
        var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                          Gtk.MessageType.QUESTION, Gtk.ButtonsType.YES_NO, 
                                          _("Are you sure you want to delete this subscription?"));
		int id = this.selection_tree ();
		if (id != -1)
			if (info.run () == Gtk.ResponseType.YES)
			{
				this.side.remove_channel (id);
				this.db.remove_channel (id);
			}
		info.destroy ();
    }

    private void edit_subscription ()
    {
        ChannelStore ch = this.selected_item ();
        if (ch != null)
        {
            Feedler.EditSubs subs = new Feedler.EditSubs ();
		    subs.set_transient_for (this);
            subs.edited.connect (edited_cb);
		    foreach (Model.Folder folder in this.db.folders)
			    subs.add_folder (folder.name);
            Model.Channel c = this.db.get_channel (ch.id);
            subs.set_model (c.id, c.title, c.source, c.folder);
            subs.show_all ();
        }
	}

    private void edited_cb (int id, int folder, string channel, string url)
    {
        //TODO edit subs
    }
}
