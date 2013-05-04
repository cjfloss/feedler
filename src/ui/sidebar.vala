/**
 * sidebar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.SidebarItem : Granite.Widgets.SourceList.Item
{
	private Gtk.Menu menu;
	//internal Gtk.MenuItem update;
	internal Gtk.MenuItem mark;
	internal Gtk.MenuItem rename;
	internal Gtk.MenuItem remove;
	internal Gtk.MenuItem edit;

	public SidebarItem (string name, GLib.Icon icon, uint badge = 0, bool menu = false)
	{
		base (name);
		this.editable = true;
		this.icon = icon;
		this.badge = (badge > 0) ? badge.to_string () : null;
		if (menu)
		{
			this.menu = new Gtk.Menu ();
			//this.update = new Gtk.MenuItem.with_label (_("Update"));
			this.mark = new Gtk.MenuItem.with_label (_("Mark as read"));
			this.rename = new Gtk.MenuItem.with_label (_("Rename"));
			this.remove = new Gtk.MenuItem.with_label (_("Remove"));
			this.edit = new Gtk.MenuItem.with_label (_("Edit"));
			//this.menu.append (update);
			this.menu.append (mark);
			this.menu.append (rename);
			this.menu.append (remove);
			this.menu.append (edit);		
			this.menu.show_all ();
		}
	}
	
	public override Gtk.Menu? get_context_menu () {
		if (menu != null) {
			if (menu.get_attach_widget () != null)
				menu.detach ();
			return menu;
		}
		return null;
	}
}

public class Feedler.Sidebar : Granite.Widgets.SourceList
{
	internal Feedler.SidebarItem all;
	internal Feedler.SidebarItem unread;
	internal Feedler.SidebarItem star;

	public Sidebar ()
	{
		if (!Feedler.SETTING.hide_header)
			this.init ();
	}

	private void init ()
	{
		this.all = new Feedler.SidebarItem (_("All items"), Feedler.Icons.ALL);
		this.root.add (all);

		this.unread = new Feedler.SidebarItem (_("Unread items"), Feedler.Icons.UNREAD);
		this.root.add (unread);

		this.star = new Feedler.SidebarItem (_("Starred items"), Feedler.Icons.STAR);
		this.root.add (star);
	}
}

 
/*public class ChannelStore : GLib.Object
{
	public int id { get; set; }
	public string channel { get; set; }
	public int unread { get; set; }
	public int mode { get; set; }
	
	public ChannelStore (int id, string channel, int unread, int mode)
	{
		this.id = id;
		this.channel = channel;
		this.unread = unread;
		this.mode = mode; //0-Folder;1-Channel;2-ERROR
	}
}

public class Feedler.Sidebar : Gtk.TreeView
{
	internal Gtk.TreeStore store;
	private Feedler.SidebarCell scell;
	private Gee.AbstractMap<int, Gtk.TreeIter?> folders;
	private Gee.AbstractMap<int, Gtk.TreeIter?> channels;
	
	construct
	{
		this.store = new Gtk.TreeStore (1, typeof (ChannelStore));
		this.scell = new Feedler.SidebarCell ();
		this.name = "SidebarContent";
		this.get_style_context ().add_class ("sidebar");
		this.headers_visible = false;
		this.enable_search = false;
		this.model = store;
		//this.reorderable = true;	   

		var column = new Gtk.TreeViewColumn.with_attributes ("ChannelStore", scell, null);
		column.set_sizing (Gtk.TreeViewColumnSizing.FIXED);
		column.set_cell_data_func (scell, render_scell);
		this.insert_column (column, -1); 
		this.folders = new Gee.HashMap<int, Gtk.TreeIter?> ();
		this.channels = new Gee.HashMap<int, Gtk.TreeIter?> ();
	}

	public void add_folder (Model.Folder f)
	{
		this.add_folder_ (f.id, f.name, f.parent);
	}

	public void add_folder_ (int id, string name, int folder)
	{
		Gtk.TreeIter folder_iter;
		if (folder > 0)
			this.store.append (out folder_iter, this.folders.get (folder));
		else
			this.store.append (out folder_iter, null);
		this.store.set_value (folder_iter, 0, new ChannelStore (id, name, 0, 0));
		this.folders.set (id, folder_iter);
	}

	public void add_channel (int id, string name, int folder, int unread = 0)
	{
		Gtk.TreeIter channel_iter;
		if (folder > 0)
			this.store.append (out channel_iter, this.folders.get (folder));
		else
			this.store.append (out channel_iter, null);
		this.store.set_value (channel_iter, 0, new ChannelStore (id, name, unread, 1));
		this.channels.set (id, channel_iter);
	}

	public void remove_folder (int id)
	{
		Gtk.TreeIter folder_iter = folders.get (id);
		this.store.remove (folder_iter);
		this.folders.unset (id);
	}
	
	public void remove_channel (int id)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		this.store.remove (channel_iter);
		this.channels.unset (id);
	}

	public void update_channel (int id, string name, int folder)
	{
		this.remove_channel (id);
		this.add_channel (id, name, folder);
	}

	public void update_folder (int id, string name)
	{
		Gtk.TreeIter iter = folders.get (id);
		ChannelStore store;
		this.model.get (iter, 0, out store);
		store.channel = name;
		this.store.set_value (iter, 0, store);
	}

	public void mark_channel (int id)
	{
		Gtk.TreeIter iter = channels.get (id);
		ChannelStore channel;
		this.model.get (iter, 0, out channel);
		channel.unread = 0;
		this.store.set_value (iter, 0, channel);
	}

	public void mark_folder (int id)
	{
		Gtk.TreeIter iter_f = folders.get (id);
		Gtk.TreeIter iter_c;
		ChannelStore channel;
		if (model.iter_children (out iter_c, iter_f))
		{
			do
			{
				this.model.get (iter_c, 0, out channel);
				channel.unread = 0;
				this.store.set_value (iter_c, 0, channel);
			}
			while (model.iter_next (ref iter_c));
		}
	}
	
	public void add_unread (int id, int unread)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread += unread;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void dec_unread (int id, int num = -1)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread += num;
		if (channel.unread < 0)
			channel.unread = 0;
		this.store.set_value (channel_iter, 0, channel);
	}

	public void set_mode (int id, int mode)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.mode = mode;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void select_channel (int id)
	{
		Gtk.TreeIter channel_iter = channels.get (id);
		this.get_selection ().select_iter (channel_iter);
	}
	
	public void select_path (Gtk.TreePath path)
	{
		this.get_selection ().select_path (path);
	}
	
	private void render_scell (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter)
	{
		ChannelStore channel;
		var renderer = cell as Feedler.SidebarCell;
		model.get (iter, 0, out channel);
		
		renderer.id = channel.id;
		renderer.channel = channel.channel;
		renderer.unread = channel.unread;
		renderer.type = (Feedler.SidebarCell.Type)channel.mode;
	}
}*/
