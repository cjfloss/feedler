namespace Feedler {
    private const string CREATE_FOLDERS_TABLE = """
        CREATE TABLE folders (
            id INTEGER PRIMARY KEY,
            name TEXT UNIQUE
        );
    """;

    private const string CREATE_CHANNELS_TABLE = """
        CREATE TABLE channels (
            id INTEGER PRIMARY KEY,
            title TEXT UNIQUE,
            source TEXT,
            link TEXT,
            folder INT
        );
    """;

    private const string CREATE_ITEMS_TABLE = """
        CREATE TABLE items (
            id INTEGER PRIMARY KEY,
            title TEXT,
            source TEXT,
            author TEXT,
            description TEXT,
            time INT,
            read INT,
            starred INT,
            channel INT
        );
    """;


}
