/**
 * feedler-sidebar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class ChannelStore : GLib.Object
{
	public int id;
    public string channel { set; get; }
    public int unreaded { set; get; }
    public int mode { set; get; }
    
    public ChannelStore (int id, string channel, int unreaded, int mode)
    {
		this.id = id;
		this.channel = channel;
		this.unreaded = unreaded;
		this.mode = mode;
	}
}

public class Feedler.Sidebar : Gtk.TreeView
{
	private Gtk.TreeStore store;
	private Feedler.SidebarCell scell;
	internal GLib.HashTable<string, Gtk.TreeIter?> iter_map;
	internal GLib.List<Gtk.TreeIter?> subs_map;
	
	construct
	{
		this.store = new Gtk.TreeStore (1, typeof (ChannelStore));
		this.scell = new Feedler.SidebarCell ();
		this.name = "SidebarContent";
		this.headers_visible = false;
		this.enable_search = false;
        this.model = store;
        //this.reorderable = true;       

        var column = new Gtk.TreeViewColumn.with_attributes ("ChannelStore", scell, null);
		column.set_sizing (Gtk.TreeViewColumnSizing.FIXED);
		column.set_cell_data_func (scell, render_scell);
		this.insert_column (column, -1); 

		this.iter_map = new GLib.HashTable<string, Gtk.TreeIter?> (GLib.str_hash, GLib.str_equal);
		this.subs_map = new GLib.List<Gtk.TreeIter?> ();
	}
	
	public void add_folder (string folder_name)
	{
		Gtk.TreeIter folder_iter;
		this.store.append (out folder_iter, null);
        this.store.set (folder_iter, 0, new ChannelStore (-1, folder_name, 0, 0), -1);
        this.iter_map.insert (folder_name, folder_iter);
	}
	
	public void add_folder_to_folder (string folder_name, string parent_folder)
	{       
        unowned Gtk.TreeIter parent_iter = iter_map.lookup (parent_folder);
		Gtk.TreeIter folder_iter;
		this.store.append (out folder_iter, parent_iter);
        this.store.set (folder_iter, 0, new ChannelStore (-1, folder_name, 0, 0), -1);
        this.iter_map.insert (folder_name, folder_iter);
	}
	
	public void remove_folder (string folder_name)
	{
		unowned Gtk.TreeIter folder_iter = iter_map.lookup (folder_name);
		this.store.remove (folder_iter);
		this.iter_map.remove (folder_name);
	}
	
	public void add_channel (int channel_id, string channel_name)
	{
		Gtk.TreeIter channel_iter;		
		this.store.append (out channel_iter, null);		
        this.store.set (channel_iter, 0, new ChannelStore (channel_id, channel_name, 0, 1), -1);
        this.subs_map.append (channel_iter);
	}
	
	public void add_channel_to_folder (string folder_name, int channel_id, string channel_name)
	{
		unowned Gtk.TreeIter folder_iter = iter_map.lookup (folder_name);
		Gtk.TreeIter channel_iter;
		this.store.append (out channel_iter, folder_iter);	
        this.store.set (channel_iter, 0, new ChannelStore (channel_id, channel_name, 0, 1), -1);
        this.subs_map.append (channel_iter);
	}

	public void mark_readed (int channel_id)
	{
		unowned Gtk.TreeIter channel_iter = subs_map.nth_data (channel_id-1);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unreaded = 0;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void set_unreaded_iter (Gtk.TreeIter channel_iter, int unreaded)
	{
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unreaded = unreaded;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void add_unreaded (int channel_id, int unreaded)
	{
		unowned Gtk.TreeIter channel_iter = subs_map.nth_data (channel_id-1);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unreaded += unreaded;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void dec_unreaded (Gtk.TreeIter channel_iter)
	{
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unreaded--;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	private void render_scell (Gtk.CellLayout layout, Gtk.CellRenderer cell, Gtk.TreeModel model, Gtk.TreeIter iter)
	{
		ChannelStore channel;
		var renderer = cell as Feedler.SidebarCell;
		model.get (iter, 0, out channel);
		
		renderer.channel = channel.channel;
		renderer.unreaded = channel.unreaded;
		renderer.type = (Feedler.SidebarCell.Type)channel.mode;
	}
}
