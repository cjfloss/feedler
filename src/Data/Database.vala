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
        internal GLib.List<weak Objects.Item> tmp;

        construct {
            user_data_dir = GLib.Environment.get_user_data_dir () + "/feedler";

            GLib.DirUtils.create (user_data_dir, 0755);
            GLib.DirUtils.create (user_data_dir + "/fav", 0755);

            this.data = new GLib.List<Objects.Folder> ();

            this.db_path = user_data_dir + "/feedler.db";
            this.open ();
        }

        public void open (int flags = Sqlite.OPEN_READWRITE) throws FileError {
            if (Sqlite.OK != Sqlite.Database.open_v2 (db_path, out db, flags)) {
                this.db = null;
                throw new FileError.ACCES ("Can't open database: " + db.errmsg ());
            } else {
                info ("Database connection success at %s! :)", this.db_path);
            }
        }

        public bool is_created () {
            return this.db == null ? false : true;
        }

        public void create () {
            try {
                this.open (Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE);
            } catch (FileError e) {
                error (e.message);
            }

            var stmt = DB.prepare (db, PRAGMA_VERSION_GET);

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

        private void create_tables () {
            debug ("Creating Tables…");
            assert (this.db != null);

            assert (db.exec (CREATE_FOLDERS_TABLE) == Sqlite.OK);
            assert (db.exec (CREATE_CHANNELS_TABLE) == Sqlite.OK);
            assert (db.exec (CREATE_ITEMS_TABLE) == Sqlite.OK);

            assert (db.exec (PRAGMA_VERSION_SET) == Sqlite.OK);
            assert (db.exec (PRAGMA_DISABLE_SYNCHRONOUS) == Sqlite.OK);
        }

        public bool begin () {
            return (bool) db.exec (BEGIN_TRANSACTION);
        }

        public bool commit () {
            return (bool) db.exec (COMMIT_TRANSACTION);
        }

        public bool roolback () {
            return (bool) db.exec (ROLLBACK_TRANSACTION);
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
            var stmt = DB.prepare (db, SELECT_MAX_ID);
            DB.set_string (stmt, ":table", table);

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

            var stmt = DB.prepare (db, SELECT_ALL_FOLDERS);

            while (stmt.step () == Sqlite.ROW) {
                fo = new Objects.Folder ();
                fo.id = DB.get_int (stmt,"id");
                fo.name = DB.get_string (stmt, "name");
                fo.channels = new GLib.List <Objects.Channel?> ();
                debug ("Folder: " + fo.name);

                var stmt_c = DB.prepare (db, SELECT_CHANNELS_FROM_FOLDER);
                DB.set_int (stmt_c, ":id", fo.id);

                while (stmt_c.step () == Sqlite.ROW) {
                    ch = new Objects.Channel ();
                    ch.id = DB.get_int (stmt_c,"id");
                    ch.title = DB.get_string (stmt_c, "title");
                    ch.source = DB.get_string (stmt_c, "source");
                    ch.link = DB.get_string (stmt_c, "link");
                    ch.folder = fo;
                    ch.items = new GLib.List <Objects.Item?> ();
                    debug ("Channel: " + ch.title);

                    var stmt_i = DB.prepare (db, SELECT_ITEMS_FROM_CHANNEL);
                    DB.set_int (stmt_i, ":id", ch.id);

                    while (stmt_i.step () == Sqlite.ROW) {
                        it = new Objects.Item ();
                        it.id = DB.get_int (stmt_i, "id");
                        it.title = DB.get_string (stmt_i, "title");
                        it.source = DB.get_string (stmt_i, "source");
                        it.author = DB.get_string (stmt_i, "author");
                        it.description = DB.get_string (stmt_i, "description");
                        it.time = DB.get_int (stmt_i, "time");
                        it.read = (bool) DB.get_int (stmt_i, "read");
                        it.starred = (bool) DB.get_int (stmt_i, "starred");
                        it.channel = ch;
                        debug ("Item: " + it.title);

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
                    if (title == c.title) {
                        return c;
                    }
                }

            return null;
        }

        public unowned Objects.Channel ? get_channel_from_source (string source) {
            foreach (unowned Objects.Folder f in this.data)
                foreach (unowned Objects.Channel c in f.channels) {
                    if (source == c.source) {
                        return c;
                    }
                }

            return null;
        }

        public unowned GLib.List<Objects.Item> get_items (Objects.State state = Objects.State.ALL) {
            this.tmp = new GLib.List < weak Objects.Item > ();
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
            foreach (Objects.Folder f in this.data)
                foreach (Objects.Channel c in f.channels)
                    if (c.title == title) {
                        return c.source;
                    }

            return null;
        }

        public void mark_all () {
            this.db.exec (MARK_ALL_AS_READ);

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

            var stmt = DB.prepare (db, MARK_CHANNEL_AS_READ);
            DB.set_int (stmt, ":read", 1);
            DB.set_int (stmt, ":channel_id", c.id);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed mark channel as read - %d: %s",this.db.errcode (), this.db.errmsg ());
            }

            foreach (Objects.Item i in c.items) {
                if (!i.read) {
                    i.read = true;
                }
            }
        }

        public void mark_item (int item, bool mark) {
            var stmt = DB.prepare (db, MARK_ITEM_AS_READ);
            DB.set_int (stmt, ":read", (int) mark);
            DB.set_int (stmt, ":id", item);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed mark item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
        }

        public void star_item (int item, bool star) {
            var stmt = DB.prepare (db, MARK_ITEM_AS_STARRED);
            DB.set_int (stmt, ":starred", (int) star);
            DB.set_int (stmt, ":id", item);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed star item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
        }

        public void rename_channel (string old_name, string new_name) {
            var stmt = DB.prepare (db, RENAME_CHANNEL);
            DB.set_string (stmt, ":old_name", old_name);
            DB.set_string (stmt, ":new_name", new_name);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to rename channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
        }

        public void remove_channel (string name) {
            var c = this.get_channel (name);
            var stmt = DB.prepare (db, DELETE_CHANNEL);
            DB.set_int (stmt, ":id", c.id);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to delete channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }

            stmt = DB.prepare (db, DELETE_ITEMS_FROM_CHANNEL);
            DB.set_int (stmt, ":id", c.id);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to delete item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            c.folder.channels.remove (c);
        }

        public void insert_folder (Serializer.Folder folder) {
            var stmt = DB.prepare (db, INSERT_FOLDER);
            DB.set_string (stmt, ":name", folder.name);

            if (stmt.step () != Sqlite.DONE) {
                this.roolback ();
                error ("Failed to insert folder - %d: %s",this.db.errcode (), this.db.errmsg ());
            }

            int id = (int) this.db.last_insert_rowid ();

            Objects.Folder ff = new Objects.Folder.with_data (id, folder.name);
            this.data.append (ff);
        }

        public unowned Objects.Channel insert_channel (int folder, Serializer.Channel schannel) {
            var stmt = DB.prepare (db, INSERT_CHANNEL);
            DB.set_string (stmt, ":title", schannel.title);
            DB.set_string (stmt, ":source", schannel.source);
            DB.set_string (stmt, ":link", schannel.link);
            DB.set_int (stmt, ":folder", folder);

            if (stmt.step () != Sqlite.DONE) {
                this.roolback ();
                error ("Failed to insert channel - %d: %s",this.db.errcode (), this.db.errmsg ());
            }

            int id = (int) this.db.last_insert_rowid ();

            unowned Objects.Folder f = this.get_folder_from_id (folder);
            Objects.Channel c = new Objects.Channel.with_data (id, schannel.title, schannel.link, schannel.source, f);
            f.channels.append (c);

            return this.get_channel (schannel.title);
        }

        public int insert_item (int channel, Serializer.Item item) {
            var stmt = DB.prepare (db, INSERT_ITEM);
            DB.set_string (stmt, ":title", item.title);
            DB.set_string (stmt, ":source", item.source);
            DB.set_string (stmt, ":desc", item.description);
            DB.set_string (stmt, ":author", item.author);
            DB.set_int (stmt, ":time", item.time);
            DB.set_int (stmt, ":read", 0);
            DB.set_int (stmt, ":starred", 0);
            DB.set_int (stmt, ":channel", channel);

            if (stmt.step () != Sqlite.DONE) {
                error ("Failed to insert item - %d: %s",this.db.errcode (), this.db.errmsg ());
            }
            return (int) this.db.last_insert_rowid ();
        }

        /*public string export_to_opml () {
            //Gee.Map<int, Xml.Node*> folder_node = new Gee.HashMap<int, Xml.Node*> ();
            Xml.Doc* doc = new Xml.Doc ("1.0");
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
            foreach (Objects.Folder folder in this.folders) {
                Xml.Node* outline = new Xml.Node (null, "outline");
                outline->new_prop ("title", folder.name);
                outline->new_prop ("type", "folder");

                folder_node.set (folder.id, outline);
                body->add_child (outline);
            }

            foreach (Objects.Channel channel in this.channels) {
                Xml.Node* outline = new Xml.Node (null, "outline");
                outline->new_prop ("text", channel.title);
                outline->new_prop ("type", "rss");
                outline->new_prop ("xmlUrl", channel.source);
                outline->new_prop ("htmlUrl", channel.link);
                if (channel.folder > 0) {
                    Xml.Node* folder = folder_node.get (channel.folder);
                    folder->add_child (outline);
                } else {
                    body->add_child (outline);
                }
            }
            opml->add_child (body);

            string xmlstr;
            int n;
            doc->dump_memory (out xmlstr, out n);
            return xmlstr;
        }

        private string created_time () {
            string currentLocale = GLib.Intl.setlocale (GLib.LocaleCategory.TIME, null);
            GLib.Intl.setlocale (GLib.LocaleCategory.TIME, "C");
            string date = GLib.Time.gm (time_t ()).format ("%a, %d %b %Y %H:%M:%S %z");
            GLib.Intl.setlocale (GLib.LocaleCategory.TIME, currentLocale);
            return date;
        }*/
    }
}
