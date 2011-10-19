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
	internal GLib.List<Feedler.Channel?> channels;
	internal GLib.List<Feedler.Folder?> folders;
	
	construct
	{
		this.location = GLib.Environment.get_user_data_dir () + "/feedler/feedler.db";
		this.channels = new GLib.List<Feedler.Channel?> ();
		this.folders = new GLib.List<Feedler.Folder?> ();

		try
		{
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE);
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database: I cannot find database.\n");
			this.created = false;
		}
	}
	
	public unowned GLib.List<Feedler.Folder?> get_folders ()
	{
		return folders;
	}
	
	public unowned GLib.List<Feedler.Channel?> get_channels ()
	{
		return channels;
	}
	
	public void create ()
	{
        try
        {
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler", 0755);
			GLib.DirUtils.create (GLib.Environment.get_user_data_dir () + "/feedler/fav", 0755);
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.READ | SQLHeavy.FileMode.WRITE | SQLHeavy.FileMode.CREATE);
			db.execute ("CREATE TABLE folders (`id` INTEGER PRIMARY KEY,`name` TEXT,`parent` INT);");
			db.execute ("CREATE TABLE channels (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`homepage` TEXT,`folder` INT,`type` INT);");
			db.execute ("CREATE TABLE items (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`author` TEXT,`description` TEXT,`time` INT,`state` INT,`channel` INT);");
			this.created = true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.create (): I cannot create new database.\n");
			stderr.printf (location);
		}
	}
/*	
	private void _insert_folder (string name, int parent)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
			query.set_string (":name", name);
			query.set_int (":parent", parent);
			query.execute ();
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_folder (%s, %s): I cannot insert folder.", name, parent);
		}
	}
	
	public void insert_folder (Feedler.Folder folder)
	{
		this._insert_folder (folder.get_name (), folder.get_parent ());
		this.folders.append (folder); 
	}
*/	
	public void insert_opml (GLib.List<Feedler.Folder> folders, GLib.List<Feedler.Channel> channels)
	{
		try
        {
			transaction = db.begin_transaction ();
			foreach (Feedler.Folder folder in folders)
			{
				query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
				query.set_string (":name", folder.name);
				query.set_int (":parent", folder.parent);
				query.execute ();
				this.folders.append (folder);
			}

			foreach (Feedler.Channel channel in channels)
			{
				query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `homepage`, `folder`, `type`) VALUES (:title, :source, :homepage, :folder, :type);");
				query.set_string (":title", channel.title);
				query.set_string (":source", channel.source);
				query.set_string (":homepage", channel.homepage);
				query.set_int (":folder", channel.folder);
				query.set_int (":type", channel.type);
				channel.id_db =  (int)query.execute_insert ();
				this.channels.append (channel);
			}
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_opml (): I cannot insert data from opml file.");
		}
	}

	public void insert_items (GLib.List<Feedler.Item?> items, int channel_id)
	{
        try
        {
			transaction = db.begin_transaction ();
			foreach (Feedler.Item item in items)
			{			
				query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :time, :state, :channel);");
				query.set_string (":title", item.title);
				query.set_string (":source", item.source);
				query.set_string (":author", item.author);
				query.set_string (":description", item.description);
				query.set_int (":time", item.time);
				//query.set_int (":state", (int)item.state);
				query.set_int (":state", (int)State.READED);
				query.set_int (":channel", channel_id);
				query.execute ();
			}
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_items (): I cannot insert list of items.\n");
		}
	}
	
	public void insert_subscription (ref Feedler.Channel channel)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `homepage`, `folder`, `type`) VALUES (:title, :source, :homepage, :folder, :type);");
			query.set_string (":title", channel.title);
			query.set_string (":source", channel.source);
			query.set_string (":homepage", channel.homepage);
			query.set_int (":folder", channel.folder);
			query.set_int (":type", (int)channel.type);
			channel.id = (int)this.channels.length ();
			channel.id_db =  (int)query.execute_insert ()-1;
			this.channels.append (channel);
			foreach (Feedler.Item item in channel.items)
			{			
				query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :time, :state, :channel);");
				query.set_string (":title", item.title);
				query.set_string (":source", item.source);
				query.set_string (":author", item.author);
				query.set_string (":description", item.description);
				query.set_int (":time", item.time);
				//query.set_int (":state", (int)item.state);
				query.set_int (":state", (int)State.READED);
				query.set_int (":channel", channel.id_db);
				query.execute ();
			}
			transaction.commit();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.insert_subscription (): I cannot insert new subscription.\n");
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
			stderr.printf ("Feedler.Database.remove_subscription (): I cannot remove subscription.\n");
		}
	}
	
	public unowned GLib.List<Feedler.Folder?> select_folders ()
	{
        try
        {
			int count = 0;
			query = new SQLHeavy.Query (db, "SELECT * FROM `folders`;");
			for (SQLHeavy.QueryResult results = query.execute(); !results.finished; results.next())
			{
				Feedler.Folder fo = new Feedler.Folder ();
				fo.id = count++;
				fo.name = results.fetch_string (1);
				fo.parent = results.fetch_int (2);
				this.folders.append (fo);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.select_folders (): I cannot select all folders.\n");
		}
		return folders;
	}
	
	public unowned GLib.List<Feedler.Channel?> select_channels ()
	{
        try
        {
			int count = 0;
			query = new SQLHeavy.Query (db, "SELECT * FROM `channels`;");
			for (var results = query.execute(); !results.finished; results.next())
			{				
				Feedler.Channel ch = new Feedler.Channel ();
				ch.id = count++;
				ch.id_db = results.fetch_int (0);
				ch.title = results.fetch_string (1);
				ch.source = results.fetch_string (2);
				ch.homepage = results.fetch_string (3);
				ch.folder = results.fetch_int (4);
				ch.type = (Type) results.fetch_int (5);
				
				var q = new SQLHeavy.Query (db, "SELECT * FROM `items` WHERE `channel`="+(ch.id_db-1).to_string ()+";");
				for (var r = q.execute (); !r.finished; r.next ())
				{
					Feedler.Item it = new Feedler.Item ();
					it.title = r.fetch_string (1);
					it.source = r.fetch_string (2);
					it.author = r.fetch_string (3);
					it.description = r.fetch_string (4);
					it.time = r.fetch_int (5);
					it.state = (State)r.fetch_int (6);
					ch.add_item (it);				
				}
				this.channels.append (ch);
			}
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Feedler.Database.select_channels (): I cannot select all channels.\n");
		}
		return channels;
	}
}
