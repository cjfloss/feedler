/**
 * database.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Database : GLib.Object
{
	private SQLHeavy.Database db;
	private SQLHeavy.Transaction transaction;
	private SQLHeavy.Query query;
	private string location;
	
	construct
	{
		this.location = GLib.Environment.get_user_data_dir () + "/feedler/feedler.db";
        this.open ();
	}

    public bool open ()
    {
        try
		{
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.WRITE);
			return true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot find database.\n");
			return false;
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
			db.execute ("CREATE TABLE channels (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`link` TEXT,`folder` INT);");
			db.execute ("CREATE TABLE items (`id` INTEGER PRIMARY KEY,`title` TEXT,`source` TEXT,`author` TEXT,`description` TEXT,`time` INT,`state` INT,`channel` INT);");
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot create new database.\n");
		}
	}

    public bool begin ()
    {
        try
		{
			this.transaction = db.begin_transaction ();
            return true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot begin transaction.\n");
			return false;
		}
    }

    public bool commit ()
    {
        try
		{
			this.transaction.commit ();
            return true;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot commit transaction.\n");
			return false;
		}
    }

    public int select_parent (string name)
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT `id` FROM `folders` WHERE `name`=:name;");
            query.set_string (":name", name);
			for (SQLHeavy.QueryResult results = query.execute (); !results.finished; results.next ())
                return results.fetch_int (0);
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot select parent folder for %s.\n", name);
		}
        return 0;
	}

    public int select_channel (string uri)
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT `id` FROM `channels` WHERE `source`=:uri;");
            query.set_string (":uri", uri);
			for (SQLHeavy.QueryResult results = query.execute (); !results.finished; results.next ())
                return results.fetch_int (0);
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot select channel for %s.\n", uri);
		}
        return 0;
	}

    public string[]? select_channels_uri ()
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT `source` FROM `channels`;");
            SQLHeavy.QueryResult results = query.execute ();
            string[] uri = new string[0];
			for (; !results.finished; results.next ())
                uri += results.fetch_string (0);
            return uri;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot select channels uri.\n");
		}
        return null;
	}

    public int insert_folder (Model.Folder folder, bool autocommit = false)
	{
		try
        {
			this.transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
			query.set_string (":name", folder.name);
			query.set_int (":parent", folder.parent);
            int id = (int)query.execute_insert ();
            if (autocommit)
    			this.transaction.commit ();
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert folder %s.", folder.name);
            return 0;
		}
	}

    public int insert_channel (Model.Channel channel, bool autocommit = false)
	{
		try
        {
            this.transaction = db.begin_transaction ();
            query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `link`, `folder`) VALUES (:title, :source, :link, :folder);");
			query.set_string (":title", channel.title);
			query.set_string (":source", channel.source);
			query.set_string (":link", channel.link);
			query.set_int (":folder", channel.folder);
            int id = (int)query.execute_insert ();
            if (autocommit)
    			this.transaction.commit ();
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert channel %s.", channel.title);
            return 0;
		}
	}

    public void insert_item (Model.Item item, bool autocommit = false)
	{
        try
        {
			//this.transaction = db.begin_transaction ();
		    query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :time, :state, :channel);");
			query.set_string (":title", item.title);
			query.set_string (":source", item.source);
			query.set_string (":author", item.author);
			query.set_string (":description", item.description);
			query.set_int (":time", item.time);
			query.set_int (":state", (int)item.state);
			query.set_int (":channel", item.channel);
			query.execute ();
            if (autocommit)
    			this.transaction.commit ();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert items %s.\n", item.title);
		}
	}
}

