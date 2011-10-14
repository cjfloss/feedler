/**
 * feedler-view-cell.vala
 * 
 * Based on the work of Lucas Baudin <xapantu@gmail.com>
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

public class Feedler.ViewCell : Gtk.CellRenderer
{
    public string subject { set; get; }
    public string author { set; get; }
    public string channel { set; get; }
    public string date { set; get; }
    public bool unreaded { set; get; }

    double sender_height = 0.0;
    double subject_height = 0.0;

    /**
     * Get the width of the layout, in pixel.
     *
     * @param layout a valid pango layout
     * @return the width of the layout.
     **/
    static double get_layout_width (Pango.Layout layout) {
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
    static double get_layout_height (Pango.Layout layout) {
        Pango.Rectangle rect = Pango.Rectangle();
        layout.get_extents(out rect, null);
        return Pango.units_to_double(rect.height);
    }

    /**
     * Function called by gtk to determine the size request of the cell.
     **/
    public override void get_size (Gtk.Widget widget, Gdk.Rectangle? cell_area,
                                   out int x_offset, out int y_offset,
                                   out int width, out int height) {
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

        /* Compute font size */
        Pango.FontDescription font_medium = widget.get_pango_context ().get_font_description ();
        //Pango.FontDescription old_desc = font_medium;
        font_medium.set_size(Pango.units_from_double (Pango.units_to_double (font_medium.get_size()) - 2));

        Pango.FontDescription font_small = widget.get_pango_context().get_font_description ();
        font_small.set_size(Pango.units_from_double (Pango.units_to_double (font_medium.get_size ()) - 1));
        
        Pango.FontDescription font_bold = widget.get_pango_context().get_font_description ();
        font_bold.set_weight (Pango.Weight.BOLD);
        
        //stderr.printf ("link_color: (%f, %f, %f, %f)", link_color.red, link_color.green, link_color.blue, link_color.alpha);
        //stderr.printf ("color_normal: (%f, %f, %f, %f)", color_normal.red, color_normal.green, color_normal.blue, color_normal.alpha);
        //stderr.printf ("color_insensitive: (%f, %f, %f, %f)", color_insensitive.red, color_insensitive.green, color_insensitive.blue, color_insensitive.alpha);

        //Date
        /*
        Gdk.cairo_set_source_rgba (cr,
            (flags & Gtk.CellRendererState.FOCUSED) > 0 ? color_normal  : link_color);
        layout = widget.create_pango_layout (date);
        layout.set_font_description (font_small);
        double date_width = get_layout_width (layout);
        cr.move_to (area.x + area.width - get_layout_width (layout) - 5, area.y);
        Pango.cairo_show_layout (cr, layout);
        */
        double unread_width = 0.0;
       
        //Subject
        layout = widget.create_pango_layout (subject);
        if (unreaded)
			layout.set_font_description (font_bold);
        layout.set_ellipsize (Pango.EllipsizeMode.END);
        //layout.set_width (Pango.units_from_double (area.width - date_width - 5));
        layout.set_width (Pango.units_from_double (area.width - 5));
        cr.move_to (area.x, area.y);
        Gdk.cairo_set_source_rgba (cr, color_normal);
        Pango.cairo_show_layout (cr, layout);
        double y = sender_height;
        
        //Description
        layout = widget.create_pango_layout (date+", by "+author);
        layout.set_ellipsize (Pango.EllipsizeMode.END);
        layout.set_width (Pango.units_from_double (area.width - unread_width));
        cr.move_to (area.x, area.y + y);
        Gdk.cairo_set_source_rgba (cr, color_insensitive);
        layout.set_font_description (font_medium);
        Pango.cairo_show_layout (cr, layout);

        //layout.set_font_description (old_desc); /* Restore the old font, it could cause some strange behavior */
    }

    double get_height (Gtk.Widget widget) {
        /* Why "|" ? Because it is the highest char I found… */
        Pango.Layout layout = widget.create_pango_layout ("|");
        double y = get_layout_height (layout) + 5;
        sender_height = y;

        layout = widget.create_pango_layout ("|");
        Pango.FontDescription font_medium = widget.get_pango_context ().get_font_description ();
        font_medium.set_size (Pango.units_from_double (
                              Pango.units_to_double (font_medium.get_size ()) - 2));
        layout.set_font_description (font_medium);

        y += get_layout_height (layout) + 5;
        subject_height = get_layout_height (layout) + 5;

        //layout = widget.create_pango_layout ("|");
        //layout.set_font_description (font_medium);
        //y += get_layout_height (layout) + 5;
        //layout.set_font_description (old_desc);

        return y;
    }
}
