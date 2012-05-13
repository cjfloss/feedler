/**
 * backend-xml.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class BackendXml : Backend
{
    private GLib.List<Item?>** items;

    public override bool parse (string data, ref GLib.List<Item?> items)
    {
        //items = new GLib.List<Item?> ();
        this.items = &items;
        unowned Xml.Doc doc = Xml.Parser.parse_memory (data, data.length);
        if (doc == null)
        {
            stderr.printf ("Failed to read the source data.\n");
            return false;
        }

        Xml.Node* root = doc.get_root_element ();
		switch (root->name)
		{
			case "rss":
                rss (root);  break;
			case "feed":
                atom (root); break;
			default:
                stderr.printf ("Undefined type of feeds.\n");
                //delete items;
                this.items = null;
                return false;
		}
        this.items = null;
        //delete items;
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
