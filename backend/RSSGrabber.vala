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

using GLib;
using Rss;

/* 

These are the parser item attributes:

attr : use : example

guid : article URL : http://www.omgubuntu.co.uk/2011/01/global-menu-support-for-firefox-in-ubuntu-11-04-gets-going/
title : article title : LibreOffice RC 3 now available
link : rss provider URL to article : http://feedproxy.google.com/~r/d0od/~3/m7A55RofYK4/
description : sneak/info about article : <a href="http://www.omgubuntu.co.uk/2011/01/ubuntu-developers-talk-unity-and-why-its-going-to-rock-in-natty-video/"><img align="left" hspace="5" width="150" src="http://blip.tv/file/get/Ubuntudevelopers-barthvadar336.m4v.jpg" class="alignleft wp-post-image tfe" alt="Video thumbnail. Click to play" title="Click to play" /></a>Ubuntu community manager Jono Bacon discuss Unity, the new desktop environment for Ubuntu with David Barth, one of the key developers behind the interface on everyone&#8217;s lips. The 20 minute video gives Unity fans an informative look at how it came to be and where it&#8217;s heading during the Natty development cycle. Amongst other things [...]
author : URL of site being RSS'd : omgubuntu.co.uk
author_uri : URL of site being RSS'd : omgubuntu.co.uk
author_email : ?
contributor : ?
contributor_uri : ?
contributor_email : ?
comments : number of comments : 34
pub_date : date of article publication : Fri, 14 Jan 2011 17:03:12 PST
source : ?
source_url : ?
*/


public class Grabber {

    Parser parser;

	public Grabber () {
    
        this.parser = new Parser ();
    }
    
    public Gee.ArrayList<Gee.HashMap> parse_feed (string xml) {
    this.parser.load_from_data (xml, xml.length);
    var doc = this.parser.get_document ();
    var feed = new Gee.ArrayList<Gee.HashMap> ();
    foreach (Item item in doc.get_items ()) {
        var article = new Gee.HashMap<string, string> ();
        article["title"] = item.title;
        article["date"] = item.pub_date;
        article["description"] = item.description;
        article["guid"] = item.guid;
        feed.add(article);
	    }
        return feed;
	}
}






