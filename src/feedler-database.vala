/**
 * feedler-database.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.Database : GLib.Object
{
	private SQLHeavy.Database db;
	private SQLHeavy.Transaction transaction;
	private SQLHeavy.Query query;
	private string location;
	internal bool created;
	internal GLib.List<Model.Channel?> channels;
	internal GLib.List<Model.Folder?> folders;
	
	construct
	{
		this.location = GLib.Environment.get_user_data_dir () + "/feedler/feedler.db";
		this.channels = new GLib.List<Model.Channel?> ();
		this.folders = new GLib.List<Model.Folder?> ();

		try
		{
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE);
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot find database.\n");
			this.created = false;
		}
	}
	
	public unowned GLib.List<Model.Folder?> get_folders ()
	{
		return folders;
	}
	
	public unowned GLib.List<Model.Channel?> get_channels ()
	{
		return channels;
	}

    public Model.Channel? get_channel (int id)
	{
        foreach (Model.Channel channel in this.channels)
        {
            if (id == channel.id)
                return channel;
        }
		return null;
	}

    public void update_channel (int id, int folder, string channel,  string url)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `channels` SET `title`=:channel, `source`=:url, `folder`=:folder WHERE `id`=:id;");
			query.set_string (":channel", channel);
            query.set_string (":url", url);
			query.set_int (":folder", folder);
            query.set_int (":id", id);
			query.execute ();
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot update channel %s with id %i.", channel, id);
		}
    }
	
	public void create ()
	{
        try
        {
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler", 0755);
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler/fav", 0755);
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
			db.execute ("CREATE TABLE folders (`id` INTEGER PRIMARY KEY,`name` TEXT,`parent` INT);");
			db.execute ("CREATE TABLE channels (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`homepage` TEXT,`folder` INT);");
			db.execute ("CREATE TABLE items (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`author` TEXT,`description` TEXT,`time` INT,`state` INT,`channel` INT);");
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot create new database.\n");
			stderr.printf (location);
		}
	}
	
	public void remove_subscription (int channel_id, int db_id)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("DELETE FROM `channels` WHERE `id` = :id;");
			query.set_int (":id", db_id);
			query.execute_async ();
			query = transaction.prepare ("DELETE FROM `items` WHERE `channel` = :ch;");
			query.set_int (":ch", db_id-1);
			query.execute_async ();
			this.channels.remove (this.channels.nth_data (channel_id));
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot remove subscription.\n");
		}
	}
	
	public unowned GLib.List<Model.Folder?> select_folders ()
	{
        try
        {
			int count = 0;
			query = new SQLHeavy.Query (db, "SELECT * FROM `folders`;");
			for (SQLHeavy.QueryResult results = query.execute(); !results.finished; results.next())
			{
				Model.Folder fo = Model.Folder ();
				fo.id = results.fetch_int (0);
				fo.name = results.fetch_string (1);
				fo.parent = results.fetch_int (2);
				this.folders.append (fo);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot select all folders.\n");
		}
		return folders;
	}
	
	public unowned GLib.List<Model.Channel?> select_channels ()
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT * FROM `channels`;");
			for (var results = query.execute (); !results.finished; results.next ())
			{
				Model.Channel ch = new Model.Channel ();
				ch.id = results.fetch_int (0);
				ch.title = results.fetch_string (1);
				ch.source = results.fetch_string (2);
				ch.link = results.fetch_string (3);
				ch.folder = results.fetch_int (4);
                ch.items = new GLib.List<Model.Item?> ();
				
				var q = new SQLHeavy.Query (db, "SELECT * FROM `items` WHERE `channel`=:id;");//TODO order by date??
                q.set_int (":id", ch.id);
				for (var r = q.execute (); !r.finished; r.next ())
				{
					Model.Item it = Model.Item ();
                    it.id = r.fetch_int (0);
					it.title = r.fetch_string (1);
					it.source = r.fetch_string (2);
					it.author = r.fetch_string (3);
					it.description = r.fetch_string (4);
					it.time = r.fetch_int (5);
					it.state = (Model.State)r.fetch_int (6);
                    stderr.printf ("%s\n", it.title);
					ch.items.append (it);				
				}
				this.channels.append (ch);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot select all channels.\n");
		}
		return channels;
	}
}
