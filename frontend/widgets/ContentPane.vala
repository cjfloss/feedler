/*
### BEGIN LICENSE
# Copyright (C) 2011 Avi Romanoff <aviromanoff@gmail.com>
# This program is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License version 3, as published 
# by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful, but 
# WITHOUT ANY WARRANTY; without even the implied warranties of 
# MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR 
# PURPOSE.  See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along 
# with this program.  If not, see <http://www.gnu.org/licenses/>.
### END LICENSE
*/

public class ContentPane : Gtk.ScrolledWindow {

    Gtk.TextView textview;
    Gtk.TextTagTable tagtable;
    Gtk.TextBuffer textbuffer;

    public ContentPane () {
    
    setup_tag_table ();
    this.textbuffer = new Gtk.TextBuffer (this.tagtable);
    this.textview = new Gtk.TextView ();
    this.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
    this.textview.set_buffer (this.textbuffer);
    var end_iter = Gtk.TextIter ();
    this.textbuffer.get_end_iter (out end_iter);
    this.textview.set_cursor_visible (false);
    this.textbuffer.insert_with_tags (end_iter, "Into the Night", 1);
    this.add (this.textview);
    
    }
    
    private void setup_tag_table () {
    this.tagtable = new Gtk.TextTagTable ();
    
    var title_tag = new Gtk.TextTag ("title");
    title_tag.set_property ("weight", Pango.Weight.BOLD);
    title_tag.set_property ("scale", Pango.Scale.LARGE);
    this.tagtable.add (title_tag);
    
    }

}


