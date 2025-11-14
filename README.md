# pg_json_diff

A PostgreSQL extension that provides JSON diff, patch, and merge functionality using the [nlohmann/json](https://github.com/nlohmann/json) library. This extension implements RFC 6902 (JSON Patch) and RFC 7386 (JSON Merge Patch) standards.

## Features

- **generate_json_diff**: Create a JSON Patch (RFC 6902) describing differences between two JSONB documents
- **apply_patch**: Apply a JSON Patch to a JSONB document
- **merge_patch**: Merge two JSONB documents using JSON Merge Patch (RFC 7386)

## Requirements

- PostgreSQL 12 or later
- C++17 compatible compiler (g++ or clang++)
- PostgreSQL development headers (`postgresql-server-dev` package)

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/KhaledSMQ/pg-jsondiff.git
cd pg-jsondiff
```

### 2. Build and install the extension

```bash
make
sudo make install
```

### 3. Enable the extension in your database

```sql
CREATE EXTENSION pg_json_diff;
```

## Functions

### generate_json_diff

Generates a JSON Patch (RFC 6902) that describes the differences between two JSONB documents.

**Signature:**
```sql
generate_json_diff(source JSONB, target JSONB) RETURNS JSONB
```

**Example:**
```sql
SELECT generate_json_diff(
    '{"name": "John", "age": 30}'::JSONB,
    '{"name": "John", "age": 31, "city": "NYC"}'::JSONB
);
```

**Result:**
```json
[
  {"op": "replace", "path": "/age", "value": 31},
  {"op": "add", "path": "/city", "value": "NYC"}
]
```

### apply_patch

Applies a JSON Patch (RFC 6902) to a JSONB document.

**Signature:**
```sql
apply_patch(document JSONB, patch JSONB) RETURNS JSONB
```

**Supported Operations:**
- `add`: Add a value at a path
- `remove`: Remove a value at a path
- `replace`: Replace a value at a path
- `move`: Move a value from one path to another
- `copy`: Copy a value from one path to another
- `test`: Test that a value at a path equals a given value

**Example:**
```sql
SELECT apply_patch(
    '{"name": "Alice", "age": 30}'::JSONB,
    '[{"op": "replace", "path": "/age", "value": 31}]'::JSONB
);
```

**Result:**
```json
{"name": "Alice", "age": 31}
```

### merge_patch

Merges two JSONB documents using JSON Merge Patch (RFC 7386). This is a simpler alternative to JSON Patch that uses a merge document to describe changes.

**Signature:**
```sql
merge_patch(document JSONB, merge_patch JSONB) RETURNS JSONB
```

**Rules:**
- Setting a key to `null` removes it
- Setting a key to a value replaces or adds it
- Nested objects are merged recursively
- Arrays are replaced, not merged

**Example:**
```sql
SELECT merge_patch(
    '{"name": "Bob", "age": 40, "email": "bob@example.com"}'::JSONB,
    '{"age": 41, "email": null, "city": "Boston"}'::JSONB
);
```

**Result:**
```json
{"name": "Bob", "age": 41, "city": "Boston"}
```

## Usage Examples

### Example 1: Track Document Changes

```sql
-- Original document
CREATE TABLE documents (
    id SERIAL PRIMARY KEY,
    content JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

INSERT INTO documents (content) VALUES 
('{"title": "My Document", "status": "draft", "author": "Alice"}'::JSONB);

-- Update and track changes
DO $$
DECLARE
    old_doc JSONB;
    new_doc JSONB := '{"title": "My Document", "status": "published", "author": "Alice", "published_at": "2025-11-14"}'::JSONB;
    changes JSONB;
BEGIN
    SELECT content INTO old_doc FROM documents WHERE id = 1;
    
    -- Generate diff
    changes := generate_json_diff(old_doc, new_doc);
    
    RAISE NOTICE 'Changes: %', changes;
    
    -- Update the document
    UPDATE documents SET content = new_doc WHERE id = 1;
END $$;
```

### Example 2: Apply Incremental Updates

```sql
-- Start with a base document
SELECT apply_patch(
    '{"user": {"name": "Charlie", "settings": {"theme": "dark"}}}'::JSONB,
    '[
        {"op": "add", "path": "/user/settings/language", "value": "en"},
        {"op": "replace", "path": "/user/settings/theme", "value": "light"}
    ]'::JSONB
);
```

### Example 3: Configuration Merging

```sql
-- Merge default config with user preferences
WITH configs AS (
    SELECT 
        '{"theme": "light", "language": "en", "notifications": true}'::JSONB as defaults,
        '{"theme": "dark", "notifications": false}'::JSONB as user_prefs
)
SELECT merge_patch(defaults, user_prefs) as final_config
FROM configs;
```

**Result:**
```json
{"theme": "dark", "language": "en", "notifications": false}
```

### Example 4: Round-trip Diff and Patch

```sql
-- Generate a diff and apply it to verify
WITH source AS (
    SELECT '{"a": 1, "b": 2, "c": {"x": 10}}'::JSONB as doc
),
target AS (
    SELECT '{"a": 1, "b": 20, "c": {"x": 10, "y": 20}}'::JSONB as doc
),
diff AS (
    SELECT generate_json_diff(source.doc, target.doc) as patch
    FROM source, target
)
SELECT 
    apply_patch(source.doc, diff.patch) = target.doc as matches_target
FROM source, target, diff;
```

## Testing

Run the test suite:

```bash
make test
```

Or manually:

```bash
psql -d your_database -f test/test_pg_json_diff.sql
```

## How It Works

### Architecture

The extension consists of three main components:

1. **JSONB Conversion Layer** (`json_diff_impl.cpp`): Converts between PostgreSQL's JSONB binary format and nlohmann::json objects
2. **Core JSON Logic** (`json_diff_impl.cpp`): Implements diff generation, patch application, and merge logic
3. **PostgreSQL Interface** (`pg_json_diff.cpp`): Exposes C++ functions as PostgreSQL SQL functions

### JSON Patch (RFC 6902)

JSON Patch is a format for expressing a sequence of operations to apply to a JSON document. Each operation has:
- `op`: Operation type (add, remove, replace, move, copy, test)
- `path`: JSON Pointer (RFC 6901) to the target location
- `value`: The value for add/replace operations
- `from`: Source path for move/copy operations

### JSON Merge Patch (RFC 7386)

JSON Merge Patch is a simpler format where the patch itself is a JSON document. The patch is merged into the target document with these rules:
- If the patch is not an object, it replaces the target
- Null values in the patch remove the corresponding key
- Other values set or replace the key
- Objects are merged recursively

## Performance Considerations

- The extension converts JSONB to C++ objects for processing, which has some overhead
- For very large documents (>10MB), consider breaking into smaller chunks
- The diff algorithm is recursive and may be slow for deeply nested structures
- All functions are marked as `IMMUTABLE` and can be used in indexes

## Limitations

- Maximum JSONB document size is limited by PostgreSQL (typically 1GB)
- Deep recursion (>100 levels) may cause stack overflow
- Array diffs generate individual operations for each element change
- No support for custom diff algorithms or conflict resolution

## Troubleshooting

### Compilation errors

If you get compilation errors, ensure you have:
- PostgreSQL development headers: `sudo apt-get install postgresql-server-dev-<version>`
- C++17 compiler: `g++ --version` (should be 7.0 or later)

### Extension not found

If PostgreSQL can't find the extension:
```bash
# Check installation directory
pg_config --sharedir

# Manually copy files if needed
sudo cp pg_json_diff.control $(pg_config --sharedir)/extension/
sudo cp pg_json_diff--1.0.sql $(pg_config --sharedir)/extension/
sudo cp pg_json_diff.so $(pg_config --pkglibdir)/
```

### Function crashes

If functions crash or produce unexpected results:
- Check PostgreSQL logs: `tail -f /var/log/postgresql/postgresql-<version>-main.log`
- Verify input is valid JSONB: `SELECT '...'::JSONB;`
- Report issues with minimal reproducible examples

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
 
## References

- [RFC 6902: JSON Patch](https://tools.ietf.org/html/rfc6902)
- [RFC 6901: JSON Pointer](https://tools.ietf.org/html/rfc6901)
- [RFC 7386: JSON Merge Patch](https://tools.ietf.org/html/rfc7386)
- [nlohmann/json library](https://github.com/nlohmann/json)
- [PostgreSQL Extension Building Infrastructure](https://www.postgresql.org/docs/current/extend-pgxs.html)

## Acknowledgments

- [Niels Lohmann](https://github.com/nlohmann) for the excellent JSON library
- PostgreSQL community for the extension infrastructure
- RFC authors for the JSON Patch and Merge Patch specifications

