/**
 * feedler-view-web.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */
 
public class Feedler.ViewWeb : Feedler.View
{
	private WebKit.WebView browser;
	private Gtk.ScrolledWindow scroll_web;
	private GLib.StringBuilder content;

	construct
	{
		this.browser = new WebKit.WebView ();
		this.browser.settings.auto_resize_window = false;
		this.browser.settings.default_font_size = 9;
		
		this.scroll_web = new Gtk.ScrolledWindow (null, null);
		this.scroll_web.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
		this.scroll_web.add (browser);
		this.add (scroll_web);
		
		this.content = new GLib.StringBuilder ();
	}
		
	public override void clear ()
	{
		this.content.assign (generate_style ("rgb(77,77,77)", "rgb(113,113,113)", "rgb(77,77,77)", "rgb(0,136,205)"));
		this.item_selected ("");
		this.item_readed (-1);
	}
	
	public override void add_feed (string feed_time, string feed_name, string feed_source, string feed_text, string feed_author, bool feed_unreaded)
	{
		this.content.prepend (generate_item (feed_name, feed_time, feed_text));
		this.browser.load_string (content.str, "text/html", "UTF-8", "");
		//FIXME load after add all feeds in channel
	}
	
	public override void load_article (string content)
	{
		stderr.printf ("Feedler.ViewWeb.load_article ()");
	}
	
	public override void refilter (string text)
	{
		this.browser.search_text (text, true, true, true);
	}
	
	public override void select (Gtk.TreePath path)
	{
		stderr.printf ("Feedler.ViewWeb.select ()");
	}
	
	private string generate_item (string title, string time, string description)
	{
		GLib.StringBuilder item = new GLib.StringBuilder ();
		item.append ("<div class='item'><span class='title'>"+title+"</span><br/>");
		item.append ("<span class='time'>"+time+"</span><br/>");
		item.append ("<span class='content'>"+description+"</span></div><br/>");
		
		return item.str;
	}
	private string generate_style (string title_color, string time_color, string content_color, string link_color)
	{
		return "<style>	.item{width:100%; float:left; margin-bottom:15px;} .title{color:"+title_color+"; font-size:16px; font-weight:bold;} .time{color:"+time_color+";font-size:9px;} .content{color:"+content_color+";} a,a:link,a:visited{color:"+link_color+"; text-decoration:none;} a:hover{text-decoration:underline;}</style>";
	}
}
