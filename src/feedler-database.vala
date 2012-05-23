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
	internal GLib.List<Model.Channel?> channels;
	internal GLib.List<Model.Folder?> folders;
	
	construct
	{
		this.location = GLib.Environment.get_user_data_dir () + "/feedler/feedler.db";
		this.channels = new GLib.List<Model.Channel?> ();
		this.folders = new GLib.List<Model.Folder?> ();
        this.open ();
	}

    public void open ()
    {
        try
		{
			this.db = new SQLHeavy.Database (location, SQLHeavy.FileMode.WRITE);
		}
		catch (SQLHeavy.Error e)
		{
            this.db = null;
			stderr.printf ("Cannot find database.\n");
		}
    }

    public bool is_created ()
    {
        if (this.db != null)
            return true;
        return false;
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
            this.db = null;
			stderr.printf ("Cannot create new database in %s.\n", location);
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
	
	public unowned GLib.List<Model.Folder?> get_folders ()
	{
		return folders;
	}
	
	public unowned GLib.List<Model.Channel?> get_channels ()
	{
		return channels;
	}

    public string[]? get_uris ()
	{
        int i = 0;
        string[] uri = new string[this.channels.length ()];
        foreach (var c in this.channels)
            uri[i++] = c.source;
        return uri;
	}

    public string[]? get_folder_uris (int id)
	{
        string[] uri = new string[0];
        foreach (var c in this.channels)
            if (c.folder == id)
                uri += c.source;
        return uri;
	}

    public Model.Folder? get_folder (int id)
	{
        foreach (Model.Folder folder in this.folders)
            if (id == folder.id)
                return folder;
		return null;
	}

    public Model.Channel? get_channel (int id)
	{
        foreach (Model.Channel channel in this.channels)
            if (id == channel.id)
                return channel;
		return null;
	}

    public Model.Channel? from_source (string source)
	{
        foreach (Model.Channel channel in this.channels)
            if (source == channel.source)
                return channel;
		return null;
	}

    public Model.Item? get_item (int channel, int id)
	{
        Model.Channel ch = this.get_channel (channel);
        foreach (Model.Item item in ch.items)
            if (id == item.id)
                return item;
		return null;
	}

    public int add_folder (string title)
	{
		try
        {
   			this.transaction = db.begin_transaction ();
			query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
			query.set_string (":name", title);
			//query.set_int (":parent", folder.parent);
            int id = (int)query.execute_insert ();
    		this.transaction.commit ();
            Model.Folder f = {id, title, 0};
            this.folders.append (f);
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert folder %s.", title);
            return 0;
		}
	}

    public void update_folder (int id, string title)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `folders` SET `name`=:name WHERE `id`=:id;");
			query.set_string (":name", title);
            query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
            Model.Folder c = this.get_folder (id);
            c.name = title;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot update folder %s with id %i.", title, id);
		}
    }

    public void remove_folder (int id)
	{
        try
        {
			transaction = db.begin_transaction ();
            query = transaction.prepare ("DELETE FROM `folders` WHERE `id` = :id;");
			query.set_int (":id", id);
			query.execute_async ();
			query = transaction.prepare ("DELETE FROM `channels` WHERE `folder` = :id;");
			query.set_int (":id", id);
			query.execute_async ();
			query = transaction.prepare ("DELETE FROM `items` WHERE `channel` IN (SELECT id FROM channels WHERE folder=:id);");
			query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
			this.folders.remove (this.get_folder (id));
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot remove channel.\n");
		}
	}

    public int add_channel (string title, string url, int folder)
	{
		try
        {
    		this.transaction = db.begin_transaction ();
            query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `folder`) VALUES (:title, :source, :folder);");
			query.set_string (":title", title);
			query.set_string (":source", url);
			query.set_int (":folder", folder);
            int id = (int)query.execute_insert ();
            this.transaction.commit ();
            Model.Channel c = new Model.Channel.with_data (id, title, "", url, folder);
            this.channels.append (c);
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert channel %s.", title);
            return 0;
		}
	}

    public void update_channel (int id, int folder, string title,  string url)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `channels` SET `title`=:title, `source`=:url, `folder`=:folder WHERE `id`=:id;");
			query.set_string (":title", title);
            query.set_string (":url", url);
			query.set_int (":folder", folder);
            query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
            Model.Channel c = this.get_channel (id);
            c.folder = folder;
            c.title = title;
            c.source = url;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot update channel %s with id %i.", title, id);
		}
    }
	
	public void remove_channel (int id)
	{
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("DELETE FROM `channels` WHERE `id` = :id;");
			query.set_int (":id", id);
			query.execute_async ();
			query = transaction.prepare ("DELETE FROM `items` WHERE `channel` = :id;");
			query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
			this.channels.remove (this.get_channel (id));
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot remove channel.\n");
		}
	}

    public void mark_folder (int id, Model.State state = Model.State.READ)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `items` SET `state`=:state WHERE `channel` IN (SELECT id FROM channels WHERE folder=:id);");
			query.set_int (":state", (int)state);
            query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
            foreach (var i in this.channels)
                if (i.folder == id)
                    foreach (var j in i.items)
                        j.state = state;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot mark folder %i.", id);
		}
    }

    public void mark_channel (int id, Model.State state = Model.State.READ)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `items` SET `state`=:state WHERE `channel`=:id;");
			query.set_int (":state", (int)state);
            query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
            foreach (var i in this.get_channel (id).items)
                i.state = state;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot mark channel %i.", id);
		}
    }

    public void mark_item (int id, Model.State state = Model.State.READ)
    {
        try
        {
			transaction = db.begin_transaction ();
			query = transaction.prepare ("UPDATE `items` SET `state`=:state WHERE `id`=:id;");
			query.set_int (":state", (int)state);
            query.set_int (":id", id);
			query.execute_async ();
			transaction.commit ();
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot mark item %i.", id);
		}
    }
	
	public unowned GLib.List<Model.Folder?> select_folders ()
	{
        try
        {
			query = new SQLHeavy.Query (db, "SELECT * FROM `folders`;");
			for (var results = query.execute (); !results.finished; results.next ())
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
				
				var q = new SQLHeavy.Query (db, "SELECT * FROM `items` WHERE `channel`=:id;");
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
    
    /*public int insert_folder (Model.Folder folder, bool autocommit = false)
	{
		try
        {
            if (autocommit)
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
            if (autocommit)
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
            if (autocommit)
    			this.transaction = db.begin_transaction ();
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
	}*/

    public int insert_serialized_folder (Serializer.Folder folder)
	{
		try
        {
            query = transaction.prepare ("INSERT INTO `folders` (`name`, `parent`) VALUES (:name, :parent);");
			query.set_string (":name", folder.name);
			//query.set_int (":parent", folder.parent);
            query.set_int (":parent", 0);
		    int id = (int)query.execute_insert ();
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert folder %s.\n", folder.name);
            return 0;
		}
	}

    public int insert_serialized_channel (int folder, Serializer.Channel channel)
	{
        try
        {
            query = transaction.prepare ("INSERT INTO `channels` (`title`, `source`, `link`, `folder`) VALUES (:title, :source, :link, :folder);");
			query.set_string (":title", channel.title);
			query.set_string (":source", channel.source);
			query.set_string (":link", channel.link);
			query.set_int (":folder", folder);
            int id = (int)query.execute_insert ();
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert channel %s.\n", channel.title);
            return 0;
		}
	}

    public int insert_serialized_item (int channel, Serializer.Item item)
	{
        try
        {
		    query = transaction.prepare ("INSERT INTO `items` (`title`, `source`, `description`, `author`, `time`, `state`, `channel`) VALUES (:title, :source, :description, :author, :time, :state, :channel);");
			query.set_string (":title", item.title);
			query.set_string (":source", item.source);
			query.set_string (":author", item.author);
			query.set_string (":description", item.description);
			query.set_int (":time", item.time);
			query.set_int (":state", (int)Model.State.UNREAD);
			query.set_int (":channel", channel);
			int id = (int)query.execute_insert ();
            return id;
		}
		catch (SQLHeavy.Error e)
		{
			stderr.printf ("Cannot insert item %s.\n", item.title);
            return 0;
		}
	}
}
