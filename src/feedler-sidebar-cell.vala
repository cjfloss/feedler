/**
 * feedler-view-cell.vala
 * 
 * Based on the work of Lucas Baudin <xapantu@gmail.com>
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.SidebarCell : Gtk.CellRenderer
{
	public static string location = GLib.Environment.get_user_data_dir () + "/feedler/fav/";
	
	public enum Type
	{
		FOLDER,
		CHANNEL,
		ERROR
	}
	public string channel { set; get; }
	public int unreaded { set; get; }
	public Type type;
	
	double height_centered;


/**
 *  Custom function to draw rounded rectangle with max radius
 */
static void custom_rounded (Cairo.Context cr, double x, double y, double w, double h)
{
	double radius = GLib.Math.fmin (w/2.0, h/2.0);

	cr.move_to (x+radius, y);
	cr.arc (x+w-radius, y+radius, radius, GLib.Math.PI*1.5, GLib.Math.PI*2);
	cr.arc (x+w-radius, y+h-radius, radius, 0, GLib.Math.PI*0.5);
	cr.arc (x+radius,   y+h-radius, radius, GLib.Math.PI*0.5, GLib.Math.PI);	
	cr.arc (x+radius,   y+radius,   radius, GLib.Math.PI, GLib.Math.PI*1.5);
}


    /**
     * Get the width of the layout, in pixel.
     *
     * @param layout a valid pango layout
     * @return the width of the layout.
     **/
    static double get_layout_width (Pango.Layout layout)
    {
        Pango.Rectangle rect = Pango.Rectangle ();
        layout.get_extents (out rect, null);
        return Pango.units_to_double (rect.width);
    }

    /**
     * Get the height of the layout, in pixel.
     *
     * @param layout a valid pango layout
     * @return the height of the layout.
     **/
    static double get_layout_height (Pango.Layout layout)
    {
        Pango.Rectangle rect = Pango.Rectangle();
        layout.get_extents(out rect, null);
        return Pango.units_to_double(rect.height);
    }

    /**
     * Function called by gtk to determine the size request of the cell.
     **/
    public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height)
    {
        height = (int)get_height (widget);
        width = 250; /* Hardcoded, maybe it should be configurable */
    }

    /**
     * Utility function to get the system link color, which is a Gdk.Color,
     * we convert it to Gdk.RGBA to use it easily with cairo.
     *
     * @param style a valid StyleContext, we'll extract the Gdk.Color of the
     * link from it.
     *
     * @return a Gdk.RGBA, which contains the link color
     **/
    static Gdk.RGBA get_link_color (Gtk.StyleContext style) {
        Gdk.Color? link_color_ = Gdk.Color();
        Value g_value = Value (typeof (Gdk.Color));
        style.get_style_property ("link-color", g_value);
        link_color_ = (Gdk.Color?)g_value.get_boxed ();
        
        if (link_color_ == null)
            Gdk.Color.parse ("#00e", out link_color_);
        Gdk.RGBA link_color = gdk_color_to_rgba (link_color_);
        return link_color;
    }

    static Gdk.RGBA gdk_color_to_rgba (Gdk.Color? color)
    {
        Gdk.RGBA link_color = Gdk.RGBA ();
        return_val_if_fail (color != null, link_color);
        link_color.red = ((double)color.red) / 0xFFFF;
        link_color.green = ((double)color.green) / 0xFFFF;
        link_color.blue = ((double)color.blue) / 0xFFFF;
        link_color.alpha = 1.0;
        return link_color;
    }

    /**
     * Function called by gtk to draw the cell content.
     **/
    public override void render (Cairo.Context cr, Gtk.Widget widget,
                                 Gdk.Rectangle background_area, Gdk.Rectangle area,
                                 Gtk.CellRendererState flags) {
        Pango.Layout? layout = null;
        Gtk.StyleContext style = widget.get_style_context();
        Gdk.RGBA link_color = get_link_color(style);
        Gdk.RGBA color_normal = style.get_color((flags & Gtk.CellRendererState.FOCUSED) > 0 ? Gtk.StateFlags.SELECTED : Gtk.StateFlags.NORMAL);
        Gdk.RGBA color_insensitive = style.get_color(Gtk.StateFlags.INSENSITIVE);
        color_insensitive.alpha = 0.5;

        /* Compute font size */
        Pango.FontDescription font_medium = widget.get_pango_context ().get_font_description ();
        //Pango.FontDescription old_desc = font_medium;
        font_medium.set_size(Pango.units_from_double (Pango.units_to_double (font_medium.get_size()) - 2));
        Pango.FontDescription font_bold = widget.get_pango_context ().get_font_description ();
        font_bold.set_weight (Pango.Weight.BOLD);
		
		double margin = 5.0;
		double unread_width = 0.0;
		height_centered = area.y + area.height / 2 - 11 + margin;
		
        /* Unreaded */
        if (unreaded > 0)
        {
            layout = widget.create_pango_layout (unreaded.to_string ());
            double rect_width = get_layout_width (layout) + margin * 2;
            double rect_height = get_layout_height (layout) + margin * 2;
            unread_width = rect_width + 5;
            /* Background */
            custom_rounded (cr, area.x + area.width - rect_width - 5,
                         height_centered - 3, // or -4
                         rect_width, rect_height);
            Gdk.cairo_set_source_rgba (cr, link_color);
            //Gdk.cairo_set_source_rgba (cr, color_insensitive);
            cr.fill ();
            /* Real text */
            cr.move_to (area.x + area.width - get_layout_width (layout) - margin - 5,
                        height_centered - 3);
            Gdk.cairo_set_source_rgba (cr, {1, 1, 1, 1});
            Pango.cairo_show_layout (cr, layout);
		}
		
		/* Channel */
        layout = widget.create_pango_layout (channel);
        if (type == Type.FOLDER)
        {
			layout.set_font_description (font_bold);
			cr.move_to (area.x + 5, height_centered - 3);
		}
		else
			cr.move_to (area.x + 12, height_centered - 3);
        layout.set_ellipsize (Pango.EllipsizeMode.END);
        layout.set_width (Pango.units_from_double (area.width - unread_width - 5));
        Gdk.cairo_set_source_rgba (cr, color_normal);
        Pango.cairo_show_layout (cr, layout);
        
        /* Icon */
        if (type == Type.ERROR)
        {
			weak Gdk.Pixbuf pix = new Gtk.Invisible ().render_icon_pixbuf (Gtk.Stock.CANCEL, Gtk.IconSize.MENU);
			Gdk.cairo_set_source_pixbuf (cr, pix, area.x - 8, height_centered - 2);
			cr.paint ();
		}
        else if (type == Type.CHANNEL && GLib.FileUtils.test (location+channel+".png", GLib.FileTest.EXISTS))
		{
			cr.set_source_surface (new Cairo.ImageSurface.from_png (location+channel+".png"),
								area.x - 8, height_centered - 2);
			cr.paint ();
		}
		//layout.set_font_description (old_desc); /* Restore the old font, it could cause some strange behavior */
    }

    double get_height (Gtk.Widget widget) {
        /* Why "|" ? Because it is the highest char I found… */
        //Pango.Layout layout = widget.create_pango_layout ("|");
        //double y = get_layout_height (layout) + 5;
        //sender_height = y;
/*
        layout = widget.create_pango_layout ("|");
        Pango.FontDescription font_medium = widget.get_pango_context ().get_font_description ();
        Pango.FontDescription old_desc = font_medium;
        font_medium.set_size (Pango.units_from_double (
                              Pango.units_to_double (font_medium.get_size ()) - 2));
        layout.set_font_description (font_medium);

        y += get_layout_height (layout) + 5;
        subject_height = get_layout_height (layout) + 5;
*/

        //layout = widget.create_pango_layout ("|");
        //layout.set_font_description (font_medium);
        //y += get_layout_height (layout) + 5;
        //layout.set_font_description (old_desc);

        //return y;
        return 22;
    }
}
