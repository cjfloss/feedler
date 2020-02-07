/**
 * serializer.vala
 *
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
using Feedler;

public struct Serializer.Folder {
    public string name;
    public Serializer.Channel[] ? channels;

    public Folder.from_model (Objects.Folder model, bool full = false) {
        this.name = model.name;
        this.channels = new Serializer.Channel[model.channels.length ()];
        int i = 0;

        foreach (var c in model.channels) {
            this.channels[i++] = Serializer.Channel.from_model (c, full);
        }
    }
}

public struct Serializer.Channel {
    public string title;
    public string link;
    public string source;
    public Serializer.Item[] ? items;

    public Channel.from_model (Feedler.Objects.Channel model, bool full = true) {
        this.title = model.title;
        this.link = model.link ?? "";
        this.source = model.source ?? "";

        //this.items = null;
        if (full) {
            int i = 0;
            this.items = new Serializer.Item[model.items.length ()];

            foreach (var item in model.items) {
                this.items[i++] = Serializer.Item.from_model (item);
            }
        }
    }

    public Channel.no_data () {
        this.title = "";
        this.link = "";
        this.source = "";
    }
}

public struct Serializer.Item {
    public string title;
    public string source;
    public string author;
    public string description;
    public int time;

    public Item.from_model (Objects.Item model) {
        this.title = model.title ?? _("No title");
        this.source = model.source;
        this.author = model.author;
        this.description = model.description ?? "";
        this.time = model.time;
    }
}