namespace Feedler.Objects {
    public class Folder {
        public int id;
        public string name;
        public GLib.List<Channel> channels;

        public Folder.with_data (int id, string name) {
            this.id = id;
            this.name = name;
        }

        public Channel? channel (string title) {
            foreach (Channel c in this.channels) {
                if (title == c.title) {
                    return c;
                }
            }
            return null;
        }
    }
}