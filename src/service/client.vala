/**
 * client.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

void main ()
{
    /* Needed only if your client is listening to signals; you can omit it otherwise */
    var loop = new MainLoop();

    /* Important: keep demo variable out of try/catch scope not lose signals! */
    FeedlerClient demo = null;

    try
    {
        demo = Bus.get_proxy_sync (BusType.SESSION, "org.example.Feedler",
                                                    "/org/example/feedler");

        demo.updated.connect ((channel, unreaded) =>
        {
            stdout.printf ("Channel: %i with %i unreaded items\n", channel, unreaded);
        });
        demo.update ("http://elementaryos.org/journal/rss.xml");        
        demo.update ("http://elementaryluna.blogspot.com/feeds/posts/default");
        //demo.update_all ();

        GLib.Timeout.add_seconds (10, () =>
        {
            demo.stop();
            stderr.printf ("Sending stop call.\n");
            loop.quit ();
            return false;
        });
    }
    catch (GLib.IOError e)
    {
        stderr.printf ("%s\n", e.message);
    }
    loop.run ();
}