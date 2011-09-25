/**
 * feedler-parser.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.Parser : GLib.Object
{
	public enum ChannelType
	{
		RSS,
		ATOM,
		PIE
	}
	
	public GLib.List<Feedler.Item?> items;
	
	public unowned GLib.List<Feedler.Item?> parse_doc (ChannelType type, Xml.Doc* doc)
	{		
		items = new GLib.List<Feedler.Item?> ();
		switch (type)
		{
			case ChannelType.RSS:
			parse_rss (doc);
			break;
		}
		return items;
	}
	
	public unowned GLib.List<Feedler.Item?> parse_doc_type (string type, Xml.Doc* doc)
	{		
		items = new GLib.List<Feedler.Item?> ();
		switch (type)
		{
			case "rss":
			parse_rss (doc);
			break;
		}
		//items.reverse ();
		return items;
	}
	
	public void parse_rss (Xml.Doc* doc)
	{
		Xml.Node* root = doc->get_root_element ();
		parse_rss_channel (root);
	}
	
	private void parse_rss_channel (Xml.Node* channel)
	{
		for (Xml.Node* iter = channel->children; iter != null; iter = iter->next)
		{
            if (iter->type != Xml.ElementType.ELEMENT_NODE)
                continue;
            
            if (iter->name == "item")
				parse_rss_item (iter);
            else
				parse_rss_channel (iter);
        }
	}
    
    private void parse_rss_item (Xml.Node* iitem)
    {
		Feedler.Item item = new Feedler.Item ();
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
				item.publish_time = (int)string_to_time_t (iter->get_content ());
        }
        item.state = State.UNREADED;
        if (item.author == null)
			item.author = "Anonymous";
		if (item.publish_time == 0)
			item.publish_time = (int)time_t ();
        items.append (item);
	}
	
	private time_t string_to_time_t (string date)
	{
		Soup.Date time = new Soup.Date.from_string (date);
		return (time_t)time.to_time_t ();
	}
}
