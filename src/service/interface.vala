/**
 * interface.vala
 * 
 * @author Daniel Kur <Daniel.M.Kur@gmail.com>
 * @see COPYING
 */

[DBus (name = "org.example.Feedler")]
interface FeedlerClient : Object
{
    public abstract int ping (string msg) throws IOError;
    public abstract void stop () throws IOError;
}

interface Backend : Object
{
    public abstract int ping (string msg) throws IOError;
    public abstract void stop () throws IOError;
}
