/**
 * feedler-window.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.Window : Gtk.Window
{
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
            client.iconed.connect (favicon_cb);
            client.imported.connect (imported_cb);            
            client.updated.connect (updated_cb);
            this.dialog (client.ping (), Gtk.MessageType.INFO);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
		this.db = new Feedler.Database ();
		this.layout = new Feedler.CardLayout ();
		this.destroy.connect (destroy_app);
		this.content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);	
		this.ui_toolbar ();
        this.ui_layout ();
        if (Feedler.STATE.window_state == Feedler.WindowState.MAXIMIZED)
			this.maximize ();
        else if (Feedler.STATE.window_state == Feedler.WindowState.FULLSCREEN)
		{
			this.fullscreen ();
			this.toolbar.fullscreen_mode.active = true;
		}
		else
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
        this.content.pack_start (toolbar, false, false, 0);
        
        this.toolbar.back.clicked.connect (history_prev);
        this.toolbar.forward.clicked.connect (history_next);
        this.toolbar.update.clicked.connect (_update_all);
        this.toolbar.mode.mode_changed.connect (change_mode);
        this.toolbar.column.clicked.connect (change_column);
        this.toolbar.search.activate.connect (search_list); 
        
        this.toolbar.import_feeds.activate.connect (_import);
        this.toolbar.export_feeds.activate.connect (_export);
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
        this.pane.set_position (Feedler.STATE.sidebar_width);
        this.pane.add1 (scroll_side);
		
		this.sidemenu = new Feedler.MenuSide ();
		this.sidemenu.add_sub.activate.connect (_create_subs);
		this.sidemenu.add_fol.activate.connect (_create_folder);
		this.sidemenu.upd.activate.connect (_update);
		this.sidemenu.mark.activate.connect (_mark);
		this.sidemenu.rem.activate.connect (_remove);
		this.sidemenu.edit.activate.connect (_edit);
		this.sidemenu.show_all ();
        
        this.layout.init_views ();
		this.view = (Feedler.View)layout.get_nth_page (0);
		this.view.item_selected.connect (history_add);
		this.view.item_marked.connect (mark_item);

        this.stat = new Feedler.Statusbar ();
        this.stat.add_feed.button_press_event.connect (()=>{_create_subs (); return false;});
        this.stat.delete_feed.button_press_event.connect (()=>{_remove (); return false;});
        this.stat.mark_feed.button_press_event.connect (()=>{_mark (); return false;});
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
        this.ui_feeds ();
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

    private void dialog (string msg, Gtk.MessageType msg_type = Gtk.MessageType.INFO)
    {
         var info = new Gtk.MessageDialog (this, Gtk.DialogFlags.DESTROY_WITH_PARENT,
                                           msg_type, Gtk.ButtonsType.OK, msg);
         info.run ();
         info.destroy ();
    }
	
	private void destroy_app ()
	{
stderr.printf ("\nSTATE: %i\n", (get_window ().get_state () & Gdk.WindowState.MAXIMIZED));
		if ((get_window ().get_state () & Gdk.WindowState.MAXIMIZED) != 0)
			Feedler.STATE.window_state = Feedler.WindowState.MAXIMIZED;
		else if ((get_window ().get_state () & Gdk.WindowState.FULLSCREEN) != 0)
			Feedler.STATE.window_state = Feedler.WindowState.FULLSCREEN;
		else
		{
			Feedler.STATE.window_state = Feedler.WindowState.NORMAL;
			int width, height;
			get_size (out width, out height);
			Feedler.STATE.window_width = width;
			Feedler.STATE.window_height = height;
			Feedler.STATE.sidebar_width = this.pane.position;
		}
		Gtk.main_quit ();
	}
	
	protected void catch_activated (int index)
	{
		switch (index)
		{
			case 0: this._import (); break;
			case 1: this._create_subs (); break;
		}
	}
	
	private int selection_tree ()
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
stderr.printf ("PREV\t");
		string side_path = null, view_path = null;
        this.history.prev (out side_path, out view_path);
stderr.printf ("OK: %s :: %s\n", side_path, view_path);
        this.side.get_selection ().select_path (new Gtk.TreePath.from_string (side_path));
        this.load_channel ();
		if (view_path != null)
			this.view.select (new Gtk.TreePath.from_string (view_path));
        this.history_sensitive ();
	}
	
	protected void history_next ()
	{
stderr.printf ("NEXT\t");
		string side_path = null, view_path = null;
        this.history.next (out side_path, out view_path);
stderr.printf ("OK: %s :: %s\n", side_path, view_path);
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

    protected void imported_cb (Serializer.Folder[] folders)
	{
        int count = 0;
        this.db.begin ();
        foreach (var f in folders)
        {
            this.toolbar.progress.pulse (_("Importing %s").printf (f.name), true);
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
        this.toolbar.progress.pulse ("", false);
        this.notification (_("Imported %i channels in %i folders.").printf (count, folders.length));
	}
	
	protected void updated_cb (Serializer.Channel channel)
	{
        //stderr.printf ("updated_cb\n");
        Model.Channel ch = this.db.from_source (channel.source);
        this.toolbar.progress.pulse (_("Updating %s").printf (ch.title), true);
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
			this.side.set_mode (ch.id, 1);
        if (connections == 0)
        {
            this.toolbar.progress.pulse ("", false);
            string description = unread > 1 ? _("new feeds") : _("new feed");
            this.notification ("%i %s".printf (unread, description));
            this.stat.set_unread (unread);
            this.unread = 0;
        }
	}

    private void favicon_cb (string uri, uint8[] data)
	{
        this.connections--;
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
        if (connections == 0)
            this.toolbar.progress.pulse ("", false);
	}

	private void mark_item (int id, bool state)
    {
		int i = this.selection_tree ();
        this.db.mark_item (id, state ? Model.State.UNREAD : Model.State.READ);
		this.side.dec_unread (i, state ? 1 : -1);
		this.db.get_item (i, id).state = state ? Model.State.UNREAD : Model.State.READ;
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
	
	private void load_channel ()
	{
		int id = this.selection_tree ();
		if (id != -1)
		{
			this.view.clear ();
			GLib.Time current_time = GLib.Time.local (time_t ());
			foreach (Model.Item item in this.db.get_channel (id).items)
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
    private void _update_all ()
	{
        try
        {
            this.toolbar.progress.pulse (_("Updating subscriptions"), true);
            string[] uris = this.db.get_uris ();
            this.connections = uris.length;
            this.client.update_all (uris);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
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
                    this.toolbar.progress.pulse (_("Updating %s").printf (c.title), true);
					this.connections++;
                    this.client.update (c.source);
			    }
                else
                {
                    this.toolbar.progress.pulse (_("Updating subscriptions"), true);
                    string[] uris = this.db.get_folder_uris (ch.id);
                    this.connections = uris.length;
                    this.client.update_all (uris);
			    }
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
            }
        }
	}

    private void _favicon_all ()
	{
        try
        {
            this.toolbar.progress.pulse (_("Downloading favicons"), true);
            string[] uris = this.db.get_uris ();
            this.connections = uris.length;
            this.client.favicon_all (uris);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
        }
	}

    private void _favicon ()
	{
        try
        {
            int id = this.selection_tree ();
            this.toolbar.progress.pulse (_("Downloading favicons"), true);
            this.connections++;
            this.client.favicon (this.db.get_channel (id).source);
        }
        catch (GLib.Error e)
        {
            this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
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
                    this.db.create ();
                this.toolbar.progress.pulse (_("Importing subscriptions"), true);
                this.ui_welcome_to_workspace ();
            }
            catch (GLib.Error e)
            {
                this.dialog ("Cannot connect to service!", Gtk.MessageType.ERROR);
            }
        }
        file.destroy ();
        this.show_all ();
	}

	private void _export ()
	{
		var file = new Gtk.FileChooserDialog ("Save File", this, Gtk.FileChooserAction.SAVE,
                                              Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                                              Gtk.Stock.SAVE, Gtk.ResponseType.ACCEPT);
        if (file.run () == Gtk.ResponseType.ACCEPT)
            this.dialog ("Not implemented yet (%s)".printf (file.get_filename ()));
        file.destroy ();
	}

    private void _create_folder ()
    {
        Feedler.Folder fol = new Feedler.Folder ();
		fol.set_transient_for (this);
        fol.saved.connect (create_folder_cb);
        fol.show_all ();
	}

    private void _create_subs ()
    {
        Feedler.Subscription subs = new Feedler.Subscription ();
		subs.set_transient_for (this);
        subs.saved.connect (create_subs_cb);
		foreach (Model.Folder folder in this.db.folders)
		    subs.add_folder (folder.name);
        subs.show_all ();
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

    private void create_subs_cb (int id, int folder, string title, string url)
    {
        int i = this.db.add_channel (title, url, folder);
        this.side.add_channel (i, title, folder);
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
