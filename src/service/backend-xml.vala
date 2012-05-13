/**
 * backend-xml.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class BackendXml : Backend
{
    private Channel* channel;
    private GLib.List<Item?>** items;

    public override bool parse_channel (string data, ref Channel channel)
    {
        unowned Xml.Doc doc = Xml.Parser.parse_memory (data, data.length);
        if (!is_valid (doc))
            return false;
        
        this.channel = &channel;
        unowned Xml.Node root = doc.get_root_element ();
        switch (root.name)
		{
            case "rss":
                rss_channel (root);  break;
            case "feed":
                atom_channel (root); break;
		}
        this.channel = null;
        return true;
    }

    public override bool parse_items (string data, ref GLib.List<Item?> items)
    {
        unowned Xml.Doc doc = Xml.Parser.parse_memory (data, data.length);
        if (!is_valid (doc))
            return false;
        
        this.items = &items;
        unowned Xml.Node root = doc.get_root_element ();
        switch (root.name)
		{
            case "rss":
                rss (root);  break;
            case "feed":
                atom (root); break;
		}
        this.items = null;
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

    private bool is_valid (Xml.Doc doc)
    {
        if (doc == null)
        {
            stderr.printf ("Failed to read the source data.\n");
            return false;
        }

        unowned Xml.Node root = doc.get_root_element ();
        if (root.name != "rss" && root.name != "feed")
        {
            stderr.printf ("Undefined type of feeds.\n");
            return false;
        }
        return true;
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
		//this.channel.type = Type.RSS;
		for (Xml.Node* iter = ch->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;

            if (iter->name == "title")
				this.channel->title = iter->get_content ();
			else if (iter->name == "link")
				this.channel->link = iter->get_content ();
            else
                rss_channel (iter);
        }
	}

    private void rss_item (Xml.Node* iitem)
    {
		Item item = Item ();
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
        //item.state = State.UNREADED;
        if (item.author == null)
			item.author = "Anonymous";
		if (item.time == 0)
			item.time = (int)time_t ();
        items[0]->append (item);
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
		//this.channel.type = Type.ATOM;
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
                
            if (iter->name == "title")
				this.channel->title = iter->get_content ();
			else if (iter->name == "link" && iter->get_prop ("rel") == "alternate")
				this.channel->link = iter->get_prop ("href");
            else
                atom_channel (iter);	
        }
	}

    private void atom_item (Xml.Node* iitem)
    {
		Item item = Item ();
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
        //item.state = State.UNREADED;
		if (item.time == 0)
			item.time = (int)time_t ();
        items[0]->append (item);
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
