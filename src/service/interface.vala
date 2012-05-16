/**
 * interface.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

/**
 * Update callback return:
 * 0> - error,
 * 0  - no new feed,
 * 0< - number of new feeds.
 */
[DBus (name = "org.example.Feedler")]
interface Feedler.Client : Object
{
    public abstract void update (string uri) throws IOError;
    public abstract void update_all () throws IOError;
    public abstract string test () throws IOError;
    public abstract void stop () throws IOError;
  	public signal void updated (int channel, int unreaded);
}
