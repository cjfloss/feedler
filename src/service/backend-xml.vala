/**
 * backend-xml.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class BackendXml : Backend
{
    private Model.Channel** ch;
    private GLib.List<Model.Item?>** its;
    private GLib.List<Model.Folder?>** fls;
    private GLib.List<Model.Channel?>** chs;

    public override bool subscriptions (string data)
    {
        unowned Xml.Doc doc = Xml.Parser.parse_file (data);
        if (!is_valid (doc))
            return false;
        db.create ();
        var channels = new GLib.List<Model.Channel?> ();
        var folders = new GLib.List<Model.Folder?> ();
        this.chs = &channels;
        this.fls = &folders;
        unowned Xml.Node root = doc.get_root_element ();
        if (root.name == "opml")
        {
			unowned Xml.Node head_body = root.children;
			while (head_body != null)
			{
				if (head_body.name == "body")
				{
					opml (head_body);
					break;
				}
				head_body = head_body.next;
			}
            db.begin ();
            foreach (Model.Folder f in (GLib.List<Model.Folder?>)this.fls[0])
                db.insert_folder (f);
            foreach (Model.Channel c in (GLib.List<Model.Channel?>)this.chs[0])
                db.insert_channel (c);
            db.commit ();
		}
        this.chs = null;
        this.fls = null;
        return true;
    }

    public override bool channel (string data)
    {
        unowned Xml.Doc doc = Xml.Parser.parse_memory (data, data.length);
        if (!is_valid (doc))
            return false;
        var channel = new Model.Channel ();
        this.ch = &channel;
        unowned Xml.Node root = doc.get_root_element ();
        switch (root.name)
		{
            case "rss":
                rss_channel (root);  break;
            case "feed":
                atom_channel (root); break;
		}
        this.ch = null;
        return true;
    }

    public override bool items (string data)
    {
        unowned Xml.Doc doc = Xml.Parser.parse_memory (data, data.length);
        if (!is_valid (doc))
            return false;
        var items = new GLib.List<Model.Item?> ();
        this.its = &items;
        unowned Xml.Node root = doc.get_root_element ();
        switch (root.name)
		{
            case "rss":
                rss (root);  break;
            case "feed":
                atom (root); break;
		}
        this.its = null;
        return true;
    }

    public override BACKENDS to_type ()
    {
        return BACKENDS.XML;
    }

    public override string to_string ()
    {
        return "Default XML-based backend.";
    }

    internal override void update_func (Soup.Session session, Soup.Message message)
	{
        stderr.printf ("BackendXML.update_func %s\n", message.uri.to_string (false));
        string xml = (string)message.response_body.flatten ().data;
        GLib.List<Model.Item?> items = new GLib.List<Model.Item?> ();

		if (xml != null && this.items (xml))
		{
            int channel = db.select_channel (message.uri.to_string (false));
            string last = db.select_last_title (channel);
            db.begin ();
            items.reverse ();
            foreach (Model.Item item in items)
            {
                if (last == item.title)
                    break;
                item.channel = channel;
                db.insert_item (item);
                this.service.unreaded++;
            }
            db.commit ();
            
            --this.service.connection;
            this.service.updated (channel, (int)items.length ());
            if (this.service.connection == 0)
            {
                this.service.notification (("%i new feeds").printf (this.service.unreaded)); //TODO gettext
                this.service.unreaded = 0;
            }
		}
	}

    private bool is_valid (Xml.Doc doc)
    {
        if (doc == null)
        {
            stderr.printf ("Failed to read the source data.\n");
            return false;
        }

        unowned Xml.Node root = doc.get_root_element ();
        if (root == null)
        {
            stderr.printf ("Source data is empty.\n");
            return false;
        }
        if (root.name != "rss" && root.name != "feed" && root.name != "opml")
        {
            stderr.printf ("Undefined type of feeds.\n");
            return false;
        }
        return true;
    }

    private void opml (Xml.Node node)
	{
		unowned Xml.Node outline = node.children;
		string type;
		while (outline != null)
		{
			if (outline.name == "outline")
			{
				type = outline.get_prop ("type");
				if (type == "rss" || type == "atom")
					opml_channel (outline);
				else if (type == "folder" || type == null)
				    opml_folder (outline);
				else
				{
					stderr.printf ("Following type is currently not supported: %s.\n", type);
					continue;
				}
			}
			outline = outline.next;
		}		
	}

    private void opml_folder (Xml.Node node)
	{
		Model.Folder f = Model.Folder ();
        f.name = node.get_prop ("text");
        f.parent = 0;
        if (node.parent->name != "body")
            foreach (Model.Folder folder in (GLib.List<Model.Folder?>)this.fls)
			    if (folder.name == node.parent->get_prop ("text"))
                {
				    f.parent = folder.id;
                    break;
                }
        this.fls[0]->append (f);
		opml (node);
	}

    private void opml_channel (Xml.Node node)
	{
		Model.Channel c = new Model.Channel ();
		c.title = node.get_prop ("text");
		c.source = node.get_prop ("xmlUrl");
		c.link = node.get_prop ("htmlUrl");
        c.folder = 0;
        if (node.parent->name != "body")
            foreach (Model.Folder folder in (GLib.List<Model.Folder?>)this.fls[0])
			    if (folder.name == node.parent->get_prop ("text"))
                {
				    c.folder = folder.id;
                    break;
                }
        this.chs[0]->append (c);
	}
    
    private void rss (Xml.Node* channel)
    {
        for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "item")
				rss_item (iter);
            else
				rss (iter);
        }
    }

    private void rss_channel (Xml.Node* ch)
	{
		for (Xml.Node* iter = ch->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "title")
				this.ch[0]->title = iter->get_content ();
			else if (iter->name == "link")
				this.ch[0]->link = iter->get_content ();
            else
                rss_channel (iter);
        }
	}

    private void rss_item (Xml.Node* iitem)
    {
		Model.Item item = Model.Item ();
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "title")
				item.title = iter->get_content ();
			else if (iter->name == "link")
				item.source = iter->get_content ();
			else if (iter->name == "author" || iter->name == "creator")
				item.author = iter->get_content ();
			else if (iter->name == "description" || iter->name == "encoded")
				item.description = iter->get_content ();
			else if (iter->name == "pubDate")
				item.time = (int)string_to_time_t (iter->get_content ());
        }
        item.state = Model.State.UNREADED;
        if (item.author == null)
			item.author = "Anonymous"; //TODO gettext
		if (item.time == 0)
			item.time = (int)time_t ();
        its[0]->append (item);
	}
    
    private void atom (Xml.Node* channel)
	{
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "entry")
				atom_item (iter);
            else
				atom (iter);
        }
	}

    private void atom_channel (Xml.Node* channel)
	{
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
                
            if (iter->name == "title")
				this.ch[0]->title = iter->get_content ();
			else if (iter->name == "link" && iter->get_prop ("rel") == "alternate")
				this.ch[0]->link = iter->get_prop ("href");
            else
                atom_channel (iter);	
        }
	}

    private void atom_item (Xml.Node* iitem)
    {
		Model.Item item = Model.Item ();
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "title")
				item.title = iter->get_content ();
			else if (iter->name == "link" && iter->get_prop ("rel") == "alternate")
				item.source = iter->get_prop ("href");
			else if (iter->name == "author")
				item.author = atom_author (iter);
			else if (iter->name == "summary")
				item.description = iter->get_content ();
			else if (iter->name == "updated" || iter->name == "published")
				item.time = (int)string_to_time_t (iter->get_content ());
        }
        item.state = Model.State.UNREADED;
		if (item.time == 0)
			item.time = (int)time_t ();
        its[0]->append (item);
	}

    private string atom_author (Xml.Node* iitem)
    {
		string name = "Anonymous";//TODO gettext
		for (Xml.Node* iter = iitem->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "name")
            {
				name = iter->get_content ();
				break;
			}
        }
        return name;
	}
    
    private time_t string_to_time_t (string date)
	{
		Soup.Date time = new Soup.Date.from_string (date);
		return (time_t)time.to_time_t ();
	}
}
