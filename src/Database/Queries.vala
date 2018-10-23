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

    private const string PRAGMA_VERSION_SET = """
        PRAGMA user_version = 1;
    """;

    private const string PRAGMA_VERSION_GET = """
        PRAGMA user_version;
    """;


    private const string PRAGMA_DISABLE_SYNCHRONOUS = """
        PRAGMA synchronous = OFF;
    """;

    private const string PRAGMA_ENABLE_FOREIGN_KEYS = """
        PRAGMA foreign_keys = TRUE;
    """;


    private const string BEGIN_TRANSACTION = """
        BEGIN TRANSACTION;
    """;

    private const string COMMIT_TRANSACTION = """
        COMMIT;
    """;

    private const string ROLLBACK_TRANSACTION = """
        ROLLBACK;
    """;

    private const string SELECT_MAX_ID = """
        SELECT MAX(id)
        FROM :table;
    """;

    private const string SELECT_ALL_FOLDERS = """
        SELECT * FROM folders;
    """;

    private const string SELECT_CHANNELS_FROM_FOLDER = """
        SELECT *
        FROM channels
        WHERE
            folder = :id;
    """;

    private const string SELECT_ITEMS_FROM_CHANNEL = """
        SELECT *
        FROM items
        WHERE
            channel = :id;
    """;


    private const string MARK_ALL_AS_READ = """
        UPDATE items
            SET read = 1
        WHERE
            read = 0;
    """;

    private const string MARK_CHANNEL_AS_READ = """
        UPDATE items
            SET read = :read
        WHERE
            channel = :channel_id
        AND
            read = 0;
    """;

    private const string MARK_ITEM_AS_READ = """
        UPDATE items
            SET read = :read
        WHERE
            id = :id;
    """;

    private const string MARK_ITEM_AS_STARRED = """
        UPDATE items
            SET starred = :starred
        WHERE
            id = :id;
    """;


    private const string RENAME_CHANNEL = """
        UPDATE channels
            SET title = :new_name
        WHERE
            title = :old_name;
    """;

    private const string DELETE_CHANNEL = """
        DELETE FROM
            channels
        WHERE
            id = :id;
    """;

    private const string DELETE_ITEMS_FROM_CHANNEL = """
        DELETE FROM
            items
        WHERE
            channel = :id;
    """;

    private const string INSERT_FOLDER = """
        INSERT INTO folders
            (name)
        VALUES
            (:name);
    """;

    private const string INSERT_CHANNEL = """
        INSERT INTO channels
            (title, source, link, folder)
        VALUES
            (:title, :source, :link, :folder);
    """;

    private const string INSERT_ITEM = """
        INSERT INTO items
            (title, source, description, author, time, read, starred, channel)
        VALUES
            (:title, :source, :desc, :author, :time, :read, :starred, :channel);
    """;
}
