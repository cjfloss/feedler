/**
 * database.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @author Cleiton Floss <cleitonfloss@gmail.com>
 * @see COPYING
 */

namespace Feedler {
    public class Database : Object {
        private Sqlite.Database db;
        private string db_path;
        private int db_version;
        private string user_data_dir;
        internal GLib.List<Objects.Folder> data;
        internal GLib.List<unowned Objects.Item> tmp;
        private string errmsg;

        construct {
            user_data_dir = GLib.Environment.get_user_data_dir () + "/feedler";

            GLib.DirUtils.create (user_data_dir, 0755);
            GLib.DirUtils.create (user_data_dir + "/fav", 0755);

            this.data = new GLib.List<Objects.Folder> ();

            this.db_path = user_data_dir + "/feedler.db";
            this.open ();
        }

        public void open () {
            if (Sqlite.OK != Sqlite.Database.open_v2 (db_path, out db, Sqlite.OPEN_READWRITE)) {
                this.db = null;
                warning ("Failed to open database: %d - %s", db.errcode (), db.errmsg ());
            }
        }

        public bool is_created () {
            return this.db == null ? false : true;
        }

        public void create () {
            if (Sqlite.OK != Sqlite.Database.open_v2 (db_path, out db, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE)) {
                error ("Failed to open database: %d - %s", db.errcode (), db.errmsg ());
            }

            var stmt = DBHelper.prepare (db, "PRAGMA user_version;");

	        if (stmt.step () != Sqlite.ROW) {
		        error ("Failed to get db version: %d - %s", db.errcode (), db.errmsg ());
	        }

            db_version = stmt.column_int (0);
            debug ("DATABASE_USER_VERSION: " + db_version.to_string ());

            switch (db_version) {
                case 0:
                    create_tables ();
                    break;
                case 1: //update database
                    break;
            }
        }

        private int create_tables () {
            assert (this.db != null);
            debug ("create_tables");

            this.begin ();
            assert (db.exec (CREATE_FOLDERS_TABLE, null, out errmsg) == Sqlite.OK);
            debug ("Creating table folders");

            assert (db.exec (CREATE_CHANNELS_TABLE, null, out errmsg) == Sqlite.OK);
            debug ("Creating table channels");

            assert (db.exec (CREATE_ITEMS_TABLE, null, out errmsg) == Sqlite.OK);
            debug ("Creating table items");
            this.commit ();

            assert (db.exec ("PRAGMA user_version = 1;", null, out errmsg) == Sqlite.OK);
            debug ("user_version is 1");

            assert ( db.exec ("PRAGMA synchronous = OFF;", null, out errmsg) == Sqlite.OK);
            debug ("synchronous is OFF");

            return 1;//TODO error cases
        }

        public bool begin () {
            return (bool) db.exec ("BEGIN TRANSACTION;");
        }

        public bool commit () {
            return (bool) db.exec ("COMMIT;");
        }

        public string[] ? get_folder_uris (int id) {
            string[] uri = new string[0];
            /*foreach (var c in this.data.channels)
                if (c.folder == id)
                    uri += c.source;*/
            return uri;
        }

        public unowned Objects.Item ? get_item (int channel, int id) {
            /*foreach (unowned Objects.Channel ch in this.data.channels)
                if (ch.id == channel)
                    foreach (unowned Objects.Item it in ch.items)
                        if (id == it.id)
                            return it;*/
            return null;
        }

        public int select_max (string table = "folders") {
            var stmt = DBHelper.prepare (db, "SELECT MAX(id) FROM :table;");
            DBHelper.set_string (stmt, ":table", table);

            if (stmt.step () != Sqlite.DONE) {
                critical ("Failed to select_max - %d: %s",this.db.errcode (), this.db.errmsg ());
                return -1;
            }

            return stmt.column_int (0);
        }




        public unowned GLib.List <Objects.Folder?> select_data () {
            assert (db != null);
            Objects.Folder fo = null;
            Objects.Channel ch = null;
            Objects.Item it = null;

            var stmt = DBHelper.prepare (db, "SELECT * FROM folders;");

            while (stmt.step () == Sqlite.ROW) {
                print ("FOLDER\n");
                fo = new Objects.Folder ();
                fo.id = DBHelper.get_int (stmt,"id");
                fo.name = DBHelper.get_string (stmt, "name");
                fo.channels = new GLib.List <Objects.Channel?> ();

                var stmt_c = DBHelper.prepare (db, "SELECT * FROM channels WHERE folder = :id;");
                DBHelper.set_int (stmt_c, ":id", fo.id);

                while (stmt_c.step () == Sqlite.ROW) {
                    print ("CHANNEL\n");
                    ch = new Objects.Channel ();
                    ch.id = DBHelper.get_int (stmt_c,"id");
                    ch.title = DBHelper.get_string (stmt_c, "title");
                    ch.source = DBHelper.get_string (stmt_c, "source");
                    ch.link = DBHelper.get_string (stmt_c, "link");
                    ch.folder = fo;
                    ch.items = new GLib.List <Objects.Item?> ();

                    var stmt_i = DBHelper.prepare (db, "SELECT * FROM items WHERE channel = :id;");
                    DBHelper.set_int (stmt_i, ":id", ch.id);

                    while (stmt_i.step () == Sqlite.ROW) {
                        print ("ITEM\n");
                        it = new Objects.Item ();
                        it.id = DBHelper.get_int (stmt_i, "id");
                        it.title = DBHelper.get_string (stmt_i, "title");
                        it.source = DBHelper.get_string (stmt_i, "source");
                        it.author = DBHelper.get_string (stmt_i, "author");
                        it.description = DBHelper.get_string (stmt_i, "description");
                        it.time = DBHelper.get_int (stmt_i, "time");
                        it.read = (bool) DBHelper.get_int (stmt_i, "read");
                        it.starred = (bool) DBHelper.get_int (stmt_i, "starred");
                        it.channel = ch;

                        if (!it.read) {
                            ch.unread++;
                        }
                        ch.items.append (it);
                    }
                    fo.channels.append (ch);
                }
                this.data.append (fo);
                assert (this.data != null);
            }
            return this.data;
        }

        public unowned Objects.Folder ? get_folder (string name) {
            foreach (unowned Objects.Folder f in this.data)
                if (name == f.name) {
                    return f;
                }

            return null;
        }

        public unowned Objects.Folder ? get_folder_from_id (int id) {
            foreach (unowned Objects.Folder f in this.data)
                if (id == f.id) {
                    return f;
                }

            return null;
        }

        public unowned Objects.Channel ? get_channel (string title) {
            foreach (unowned Objects.Folder f in this.data)
                foreach (unowned Objects.Channel c in f.channels) {
                    print (title + " -- " + c.title);
                    if (title == c.title) {
                        return c;
                    }
                }

            return null;
        }

        public unowned Objects.Channel ? get_channel_from_source (string source) {
            foreach (unowned Objects.Folder f in this.data)
                foreach (unowned Objects.Channel c in f.channels) {
                    print (source + " -- " + c.source);
                    if (source == c.source) {
                        return c;
                    }
                }

            return null;
        }

        public unowned GLib.List<Objects.Item> get_items (Objects.State state = Objects.State.ALL) {
            this.tmp = new GLib.List < Objects.Item ? > ();
            GLib.CompareFunc < Objects.Item ? > timecmp = (a, b) => {
                return (int)(a.time > b.time) - (int)(a.time < b.time);
            };

            if (state == Objects.State.ALL) {
                foreach (Objects.Folder f in this.data)
                    foreach (Objects.Channel c in f.channels)
                        foreach (Objects.Item i in c.items) {
                            tmp.insert_sorted (i, timecmp);
                        }
            } else if (state == Objects.State.UNREAD) {
                foreach (Objects.Folder f in this.data)
                    foreach (Objects.Channel c in f.channels)
                        foreach (Objects.Item i in c.items)
                            if (!i.read) {
                                tmp.insert_sorted (i, timecmp);
                            }
            } else if (state == Objects.State.STARRED) {
                foreach (Objects.Folder f in this.data)
                    foreach (Objects.Channel c in f.channels)
                        foreach (Objects.Item i in c.items)
                            if (i.starred) {
                                tmp.insert_sorted (i, timecmp);
                            }
            }

            return tmp;
        }

        public unowned Objects.Item ? get_item_from_tmp (int id) {
            foreach (unowned Objects.Item i in this.tmp)
                if (i.id == id) {
                    return i;
                }

            return null;
        }

        public string[] ? get_channels_uri () {
            uint i = 0;

            foreach (Objects.Folder f in this.data) {
                i += f.channels.length ();
            }

            string[] uri = new string[i];

            foreach (Objects.Folder f in this.data)
                foreach (Objects.Channel c in f.channels) {
                    uri[--i] = c.source;
                }

            return uri;
        }

        public string ? get_channel_uri (string title) {
            uint i = 0;

            foreach (Objects.Folder f in this.data)
                foreach (Objects.Channel c in f.channels)
                    if (c.title == title) {
                        return c.source;
                    }

            return null;
        }

        public void mark_all () {
            //TODO try/catch
            //TODO separate sql from objects
            this.begin ();
            this.db.exec ("UPDATE items SET read = 1 WHERE read = 0;", null, out errmsg);
            debug ("ERROR: " + errmsg);
            this.commit ();

            foreach (Objects.Folder f in this.data) {
                foreach (Objects.Channel c in f.channels) {
                    foreach (Objects.Item i in c.items) {
                        if (!i.read) {
                            i.read = true;
                        }
                    }
                }
            }

        }

        public void mark_channel (string title) {
            var c = this.get_channel (title);

            var stmt = DBHelper.prepare (db, "UPDATE items SET read = :read WHERE channel = :channel_id AND read = 0;");
            DBHelper.set_int (stmt, ":read", 1);
            DBHelper.set_int (stmt, ":channel_id", c.id);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to rename channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();

            foreach (Objects.Item i in c.items) {
                if (!i.read) {
                    i.read = true;
                }
            }
        }

        public void mark_item (int item, bool mark) {
            var stmt = DBHelper.prepare (db, "UPDATE items SET read = :read WHERE id = :id;");
            DBHelper.set_int (stmt, ":read", (int) mark);
            DBHelper.set_int (stmt, ":id", item);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to rename channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();
        }

        public void star_item (int item, bool star) {
            var stmt = DBHelper.prepare (db, "UPDATE items SET starred = :starred WHERE id = :id;");
            DBHelper.set_int (stmt, ":starred", (int) star);
            DBHelper.set_int (stmt, ":id", item);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to rename channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();
        }

        public void rename_channel (string old_name, string new_name) {
            var stmt = DBHelper.prepare (db, "UPDATE channels SET title = :new_name WHERE title = :old_name;");
            DBHelper.set_string (stmt, ":old_name", old_name);
            DBHelper.set_string (stmt, ":new_name", new_name);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to rename channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();
        }

        public void remove_channel (string name) {
            var c = this.get_channel (name);
            var stmt = DBHelper.prepare (db, "DELETE FROM channels WHERE title = :title;");
            DBHelper.set_string (stmt, ":title", name);

            var stmt2 = DBHelper.prepare (db, "DELETE FROM items WHERE channel = :id;");
            DBHelper.set_int (stmt, ":id", c.id);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to delete channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            if (stmt2.step () != Sqlite.DONE) {
                error ("Failed to delete item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();
            c.folder.channels.remove (c);
        }

        public void insert_folder (Serializer.Folder folder) {
            var stmt = DBHelper.prepare (db, "INSERT INTO folders (name) VALUES (:name);");

            DBHelper.set_string (stmt, ":name", folder.name);

            if (stmt.step () != Sqlite.DONE) {
                //TODO this.roolback ();
                error ("Failed to insert item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }

            int id = (int) this.db.last_insert_rowid ();

            Objects.Folder ff = new Objects.Folder.with_data (id, folder.name);
            this.data.append (ff);
        }

        public unowned Objects.Channel insert_channel (int folder, Serializer.Channel schannel) {
            var stmt = DBHelper.prepare (db, "INSERT INTO channels (title, source, link, folder) VALUES (:title, :source, :link, :folder);");

            DBHelper.set_string (stmt, ":title", schannel.title);
            DBHelper.set_string (stmt, ":source", schannel.source);
            DBHelper.set_string (stmt, ":link", schannel.link);
            DBHelper.set_int (stmt, ":folder", folder);

            this.begin ();
            if (stmt.step () != Sqlite.DONE) {
                //TODO this.roolback ();
                error ("Failed to insert item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            this.commit ();

            int id = (int) this.db.last_insert_rowid ();

            unowned Objects.Folder f = this.get_folder_from_id (folder);
            Objects.Channel c = new Objects.Channel.with_data (id, schannel.title, schannel.link, schannel.source, f);
            f.channels.append (c);

            return this.get_channel (schannel.title);
        }

        public int insert_item (int channel, Serializer.Item item) {
            var stmt = DBHelper.prepare (db, "INSERT INTO items (title, source, description, author, time, read, starred, channel) VALUES (:title, :source, :desc, :author, :time, :read, :starred, :channel);");

            DBHelper.set_string (stmt, ":title", item.title);
            DBHelper.set_string (stmt, ":source", item.source);
            DBHelper.set_string (stmt, ":desc", item.description);
            DBHelper.set_string (stmt, ":author", item.author);
            DBHelper.set_int (stmt, ":time", item.time);
            DBHelper.set_int (stmt, ":read", 0);
            DBHelper.set_int (stmt, ":starred", 0);
            DBHelper.set_int (stmt, ":channel", channel);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to insert item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            return (int) this.db.last_insert_rowid ();
        }

        public string export_to_opml () {
            //Gee.Map<int, Xml.Node*> folder_node = new Gee.HashMap<int, Xml.Node*> ();
            Xml.Doc* doc = new Xml.Doc("1.0");
            /*Xml.Node* opml = doc->new_node (null, "opml", null);
            opml->new_prop ("version", "1.0");
            doc->set_root_element (opml);

            Xml.Node* head = new Xml.Node (null, "head");
            Xml.Node* h_title = doc->new_node (null, "title", "Feedler News Reader");
            Xml.Node* h_date = doc->new_node (null, "dateCreated", created_time ());
            head->add_child (h_title);
            head->add_child (h_date);
            opml->add_child (head);

            Xml.Node* body = new Xml.Node (null, "body");
            foreach (Objects.Folder folder in this.folders)
            {
                Xml.Node* outline = new Xml.Node (null, "outline");
                outline->new_prop ("title", folder.name);
                outline->new_prop ("type", "folder");

                folder_node.set (folder.id, outline);
                body->add_child (outline);
            }
            foreach (Objects.Channel channel in this.channels)
            {
                Xml.Node* outline = new Xml.Node (null, "outline");
                outline->new_prop ("text", channel.title);
                outline->new_prop ("type", "rss");
                outline->new_prop ("xmlUrl", channel.source);
                outline->new_prop ("htmlUrl", channel.link);
                if (channel.folder > 0)
                {
                    Xml.Node* folder = folder_node.get (channel.folder);
                    folder->add_child (outline);
                }
                else
                    body->add_child (outline);
            }
            opml->add_child (body);*/

            string xmlstr;
            int n;
            doc->dump_memory (out xmlstr, out n);
            return xmlstr;
        }

        private string created_time () {
            string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
            GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
            string date = GLib.Time.gm (time_t ()).format ("%a, %d %b %Y %H:%M:%S %z");
            GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
            return date;
        }
    }


    /* SQLite FUNCTIONS*/

}
