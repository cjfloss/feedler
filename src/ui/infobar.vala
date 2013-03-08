/**
 * infobar.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public abstract class Feedler.Task
{
	internal int counter;
	internal string message;

	public abstract void dismiss ();
	public abstract void undo ();
}

public class Feedler.RenameTask : Feedler.Task
{
	private unowned Feedler.Database db;
	private unowned Granite.Widgets.SourceList.Item item;
	private unowned Model.Channel channel;
	private string name;

	public RenameTask (Feedler.Database db, Granite.Widgets.SourceList.Item item, Model.Channel channel, string old_name)
	{
		this.db = db;
		this.item = item;
		this.channel = channel;
		this.counter = 5;
		this.name = old_name;
		this.message = _("Undo rename %s").printf (name);
	}

	public override void dismiss ()
	{
		this.db.rename_channel (name, item.name);
	}

	public override void undo ()
	{
		//Model.Channel c = this.db.get_channel (item.name);
		channel.title = this.name;
		item.name = this.name;
	}
}

public class Feedler.RemoveTask : Feedler.Task
{
	private unowned Feedler.Database db;
	private unowned Granite.Widgets.SourceList.Item item;

	public RemoveTask (Feedler.Database db, Granite.Widgets.SourceList.Item item)
	{
		this.db = db;
		this.item = item;
		this.counter = 5;
		this.message = _("Undo delete %s").printf (item.name);
	}

	public override void dismiss ()
	{
		var i = this.item.parent;
		this.db.remove_channel (item.name);
		i.remove (this.item);		
	}

	public override void undo ()
	{
		this.item.visible = true;
	}
}

public class Feedler.MarkAllTask : Feedler.Task
{
	private unowned Feedler.Database db;
	private unowned Feedler.Sidebar side;
	private unowned Feedler.Manager manager;

	public MarkAllTask (Feedler.Database db, Feedler.Sidebar side, Feedler.Manager manager)
	{
		this.db = db;
		this.side = side;
		this.manager = manager;
		this.counter = 5;
		this.message = _("Undo mark all items as read");
	}

	public override void dismiss ()
	{
		this.db.mark_all ();
	}

	public override void undo ()
	{
		int unread = 0;
		foreach (var f in this.side.root.children)
		{
			var expandable = f as Granite.Widgets.SourceList.ExpandableItem;
            if (expandable != null)
				foreach (var c in expandable.children)
				{
					var m = this.db.get_channel (c.name);
					c.badge = (m.unread > 0) ? m.unread.to_string () : null;
					unread += m.unread;
				}
		}
		this.manager.unread (unread);
	}
}

public class Feedler.Infobar : Gtk.InfoBar
{
	private Feedler.Task task;
	private Gtk.Label label;
	private Gtk.Label time;
	private Gtk.Button undo;
	
	public Infobar ()
	{
		this.set_message_type (Gtk.MessageType.QUESTION);

		this.label = new Gtk.Label ("");
		this.label.set_line_wrap (true);
		this.label.halign = Gtk.Align.START;
		this.label.use_markup = true;

		this.time = new Gtk.Label (null);
		this.time.halign = Gtk.Align.END;
		this.time.set_sensitive (false);

		this.undo = new Gtk.Button.with_label (("   ") + _("Undo") + ("   "));
		this.undo.clicked.connect (undone);
		
		var expander = new Gtk.Label ("");
		expander.hexpand = true;
		
		((Gtk.Box)get_content_area ()).add (label);
		((Gtk.Box)get_content_area ()).add (expander);
		((Gtk.Box)get_content_area ()).add (time);
		((Gtk.Box)get_content_area ()).add (undo);
		
		this.no_show_all = true;
		this.hide ();
	}

	public void question (Feedler.Task task)
	{
		this.task = task;
		this.label.set_markup (task.message);
		this.time.set_markup (_("<small>Dismiss after %i seconds.</small>").printf (this.task.counter));
		this.no_show_all = false;
		this.show_all ();
		GLib.Timeout.add_seconds (1, () =>
		{
			if (this.task == null)
				return false;
			else if (this.task.counter < 1)
			{
				this.dismiss ();
				return false;
			}
			else
			{
				this.time.set_markup (_("<small>Dismiss after %i seconds.</small>").printf (--this.task.counter));
				return true;
			}

		});
	}

	private void undone ()
	{
		this.task.undo ();
		this.no_show_all = true;
		this.hide ();
		this.task = null;
	}

	private void dismiss ()
	{
		this.task.dismiss ();
		this.no_show_all = true;
		this.hide ();
		this.task = null;
	}
}
