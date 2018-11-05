namespace Feedler.Objects {
    public class Channel {
        public int id;
        public string title;
        public string link;
        public string source;
        public unowned Folder folder;
        public int unread;
        public GLib.List<Item> items;

        public Channel.with_data (int id, string title, string link, string source, Folder? folder) {
            //if (folder == null) then channels go to root
            this.id = id;
            this.title = title;
            this.link = link;
            this.source = source;
            this.folder = folder;
        }

        public unowned Item ? item (string title) {
            foreach (unowned Item i in this.items) {
                if (title == i.title) {
                    return i;
                }
            }
            return null;
        }

        public unowned Item ? get_item (int id) {
            foreach (unowned Item item in this.items) {
                if (id == item.id) {
                    return item;
                }
            }
            return null;
        }

        public string last_item_title () {
            if (this.items.length () > 0) {
                return this.items.last ().data.title;
            }

            return "";
        }
    }
}
