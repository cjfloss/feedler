namespace DBHelper {
    public Sqlite.Statement prepare (Sqlite.Database db, string query) {
        Sqlite.Statement stmt;
        db.prepare_v2 (query, query.length, out stmt);
        return stmt;
    }

    public void set_int (Sqlite.Statement stmt, string name, int value) {
        stmt.bind_int (stmt.bind_parameter_index (name), value);
    }

    public int get_int (Sqlite.Statement stmt, string name) {
        int size = stmt.column_count ();
        for (int i = 0; i < size; i++) {
            if (stmt.column_name (i) == name)
                return stmt.column_int (i);
        }
        return -1;
    }

    public void set_int64 (Sqlite.Statement stmt, string name, int64 value) {
        stmt.bind_int64 (stmt.bind_parameter_index (name), value);
    }

    public int64 get_int64 (Sqlite.Statement stmt, string name) {
        int size = stmt.column_count ();
        for (int i = 0; i < size; i++) {
            if (stmt.column_name (i) == name)
                return stmt.column_int64 (i);
        }
        return -1;
    }

    public void set_double (Sqlite.Statement stmt, string name, double value) {
        stmt.bind_double (stmt.bind_parameter_index (name), value);
    }

    public double get_double (Sqlite.Statement stmt, string name) {
        int size = stmt.column_count ();
        for (int i = 0; i < size; i++) {
            if (stmt.column_name (i) == name)
                return stmt.column_double (i);
        }
        return -1;
    }

    public void set_string (Sqlite.Statement stmt, string name, string value) {
        stmt.bind_text (stmt.bind_parameter_index (name), value);
    }

    public string? get_string (Sqlite.Statement stmt, string name) {
        int size = stmt.column_count ();
        for (int i = 0; i < size; i++) {
            if (stmt.column_name (i) == name)
                return stmt.column_text (i);
        }
        return null;
    }

    public void set_null (Sqlite.Statement stmt, string name) {
        stmt.bind_null (stmt.bind_parameter_index (name));
    }
}
