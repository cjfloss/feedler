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

using WebKit;

public class ContentPane : Gtk.VBox {

    WebView browser_webview;
    Gtk.Label website_label = new Gtk.Label (null);

    public ContentPane () {
    
        Gtk.ScrolledWindow main_sw = new Gtk.ScrolledWindow (null, null);
        this.browser_webview = new WebView ();
        main_sw.set_policy (Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC);
        this.browser_webview.settings.auto_resize_window = false;
        this.website_label.use_markup = true;
        main_sw.add (this.browser_webview);
        this.pack_end (this.website_label, false);
        this.pack_start (main_sw);
        
    }
    
    public void load_article (string content, string website_label) {
    
        this.website_label.set_markup("<a href=\""+website_label+"\">"+website_label+"</a>");
        this.browser_webview.load_string (content, "text/html", "UTF-8", "");
    
    }
}


