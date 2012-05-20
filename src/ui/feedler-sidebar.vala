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
    public int unread { set; get; }
    public int mode { set; get; }
    
    public ChannelStore (int id, string channel, int unread, int mode)
    {
		this.id = id;
		this.channel = channel;
		this.unread = unread;
		this.mode = mode; //0-Folder;1-Channel
	}
}

public class Feedler.Sidebar : Gtk.TreeView
{
	private Gtk.TreeStore store;
	private Feedler.SidebarCell scell;
    private Gee.HashMap<int, Gtk.TreeIter?> folders;
    private Gee.HashMap<int, Gtk.TreeIter?> channels;
	
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
        Gtk.TreeIter folder_iter;
        if (f.parent > 0)
            this.store.append (out folder_iter, this.folders.get (f.parent));
        else
            this.store.append (out folder_iter, null);
        this.store.set (folder_iter, 0, new ChannelStore (f.id, f.name, 0, 0), -1);
        this.folders.set (f.id, folder_iter);
    }

    public void add_channel (int id, string name, int folder)
	{
		Gtk.TreeIter channel_iter;
        if (folder > 0)
            this.store.append (out channel_iter, this.folders.get (folder));
        else
            this.store.append (out channel_iter, null);
        this.store.set (channel_iter, 0, new ChannelStore (id, name, 0, 1), -1);
        this.channels.set (id, channel_iter);
	}

	public void remove_folder (int folder_id)
	{
		Gtk.TreeIter folder_iter = folders.get (folder_id);
		this.store.remove (folder_iter);
		this.folders.unset (folder_id);
	}
	
	public void remove_channel (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		this.store.remove (channel_iter);
		this.channels.unset (channel_id);
		for (int i = this.channels.size-1; i > channel_id; i--)
		{
			ChannelStore channel;
			Gtk.TreeIter ch_iter = channels.get (i);
			this.model.get (ch_iter, 0, out channel);
			--channel.id;
			this.store.set_value (ch_iter, 0, channel);
		}
	}

	public void mark_readed (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread = 0;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void add_unread (int channel_id, int unread)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread += unread;
		channel.mode = 1;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void dec_unread (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.unread--;
		this.store.set_value (channel_iter, 0, channel);
	}

    public void set_channel_name (int channel_id, string name)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.channel = name;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void set_error (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.mode = 2;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void set_empty (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
		ChannelStore channel;
		this.model.get (channel_iter, 0, out channel);
		channel.mode = 1;
		this.store.set_value (channel_iter, 0, channel);
	}
	
	public void select_channel (int channel_id)
	{
		Gtk.TreeIter channel_iter = channels.get (channel_id);
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
		
		renderer.channel = channel.channel;
		renderer.unread = channel.unread;
		renderer.type = (Feedler.SidebarCell.Type)channel.mode;
	}
}
