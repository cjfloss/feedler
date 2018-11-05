namespace Feedler.Objects {
    public class Item {
        public int id;
        public string title;
        public string source;
        public string author;
        public string description;
        public int time;
        public bool read;
        public bool starred;
        public unowned Channel channel;

        public Item.with_data (int id, string title, string source, string author, string description, int time, Channel channel) {
            this.id = id;
            this.title = title;
            this.source = source;
            this.author = author;
            this.description = description;
            this.time = time;
            this.read = false;
            this.starred = false;
            this.channel = channel;
        }
    }
}