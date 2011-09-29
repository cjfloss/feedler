/**
 * feedler-opml.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public errordomain OPMLError
{
	FILE_NOT_FOUND,
	FILE_IS_EMPTY,
	FILE_NOT_CREATED
}

public class Feedler.OPML : GLib.Object
{	
	private GLib.List<Feedler.Channel?> channels;
	private GLib.List<Feedler.Folder?> folders;
	private int ch_count;
	private int fo_count;

	public unowned GLib.List<Feedler.Folder> get_folders ()
	{
		return folders;
	}
	
	public unowned GLib.List<Feedler.Channel> get_channels ()
	{
		return channels;
	}

/* IMPORT */	
	public void import (string path, int folder_size, int channel_size) throws OPMLError
	{
		this.channels = new GLib.List<Feedler.Channel?> ();
		this.folders = new GLib.List<Feedler.Folder?> ();
		this.ch_count = folder_size;
		this.fo_count = folder_size;
				
		Xml.Doc* doc = Xml.Parser.parse_file (path);
        if (doc == null)
			throw new OPMLError.FILE_NOT_FOUND ("File "+path+" not found or permissions missing\n");
        
        Xml.Node* root = doc->get_root_element ();
        if (root == null)
        {
            delete doc;
            throw new OPMLError.FILE_IS_EMPTY ("The xml file "+path+" is empty\n");
        }
                
        if (root->name == "opml")
        {
			Xml.Node* head_body = root->children;
			while (head_body != null)
			{
				if (head_body->name == "body")
				{
					this.parse_body (head_body);
					break;
				}
				head_body = head_body->next;
			}
		}
	}
	
	private void parse_body (Xml.Node* node)
	{
		Xml.Node* outline = node->children;
		string type;
		
		while (outline != null)
		{
			if (outline->name == "outline")
			{
				type = outline->get_prop ("type");
				if (type == "rss")
					this.parse_outline (outline, Type.RSS);
				else if (type == "atom")
					this.parse_outline (outline, Type.ATOM);
				else if (type == "folder" || type == null)
				{
					Feedler.Folder fo = new Feedler.Folder ();
					fo.id = fo_count++;
					fo.name = outline->get_prop ("title");
					fo.parent = -1;
					
					if (outline->parent->name != "body")
						fo.parent = find_folder_id (outline->parent->get_prop ("title"));

					this.folders.append (fo);
					this.parse_body (outline);
				}
				else
				{
					stderr.printf ("Feedler.Opml: This feed's type is currently not supported.");
					continue;
				}
			}
			outline = outline->next;
		}
		
	}
	
	private void parse_outline (Xml.Node* node, Type type)
	{
		Feedler.Channel outline = new Feedler.Channel ();
		outline.id = ch_count++;
		outline.title = node->get_prop ("title");
		outline.source = node->get_prop ("xmlUrl");
		outline.homepage = node->get_prop ("htmlUrl");
		outline.type = type;
		if (node->parent->name != "body")
			outline.folder = find_folder_id (node->parent->get_prop ("title"));
		else
			outline.folder = -1;
		outline.favicon ();
		this.channels.append (outline);
	}
	
	private int find_folder_id (string folder_name)
	{
		foreach (Feedler.Folder folder in folders)
		{
			if (folder.name == folder_name)
				return folder.id;
		}
		return -1;
	}
	
/* EXPORT */
	public void export (string path, GLib.List<Feedler.Folder>* folders, GLib.List<Feedler.Channel>* channels) throws OPMLError
	{
		try
		{
			stderr.printf ("Export opml file to: %s", path);
			GLib.FileUtils.set_contents (path, generate_file (folders, channels));
		}
		catch (GLib.Error e)
		{
			stderr.printf ("%s", e.message);
			throw new OPMLError.FILE_NOT_CREATED ("Cannot create opml file %s\n", path);
		}
	}
	
	private string generate_file (GLib.List<Feedler.Folder>* folders, GLib.List<Feedler.Channel>* channels)
	{
		GLib.List<Xml.Node*> folder_node = new GLib.List<Xml.Node*> ();
        Xml.Doc* doc = new Xml.Doc("1.0");
        Xml.Node* opml = doc->new_node (null, "opml", null);
        opml->new_prop ("version", "1.0");
        doc->set_root_element (opml);
        
        Xml.Node* head = new Xml.Node (null, "head");
        Xml.Node* h_title = doc->new_node (null, "title", "Feedler News Reader");
        Xml.Node* h_date = doc->new_node (null, "dateCreated", created_time ());
        head->add_child (h_title);
        head->add_child (h_date);
        opml->add_child (head);
        
        Xml.Node* body = new Xml.Node (null, "body");
        foreach (Feedler.Folder folder in (GLib.List<Feedler.Folder>)folders)
        {
			Xml.Node* outline = new Xml.Node (null, "outline");
			outline->new_prop ("title", folder.name);
			outline->new_prop ("type", "folder");
			
			folder_node.append (outline);
			body->add_child (outline);
		}
        foreach (Feedler.Channel channel in (GLib.List<Feedler.Channel>)channels)
        {
			Xml.Node* outline = new Xml.Node (null, "outline");
			outline->new_prop ("title", channel.title);
			outline->new_prop ("type", channel.type.to_string ());
			outline->new_prop ("xmlUrl", channel.source);
			outline->new_prop ("htmlUrl", channel.homepage);
			if (channel.folder != -1)
			{
				Xml.Node* folder = folder_node.nth_data (channel.folder);
				folder->add_child (outline);
			}
			else
				body->add_child (outline);
		}
        opml->add_child (body);

        string xmlstr;
        int n;
        // This throws a compiler warning, see bug 547364
        doc->dump_memory(out xmlstr, out n);
        //delete xmldoc; // Don't delete the xmldoc yourself!
 
        return xmlstr;
    }
	
	private string created_time ()
	{
		string currentLocale = GLib.Intl.setlocale(GLib.LocaleCategory.TIME, null);
        GLib.Intl.setlocale(GLib.LocaleCategory.TIME, "C");
		string date = GLib.Time.gm (time_t ()).format ("%a, %d %b %Y %H:%M:%S %z");
		GLib.Intl.setlocale(GLib.LocaleCategory.TIME, currentLocale);
		return date;
	}
}
