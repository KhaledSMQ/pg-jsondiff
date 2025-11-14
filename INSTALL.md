# Quick Installation Guide

## Prerequisites

Before building and installing pg_json_diff, ensure you have:

1. **PostgreSQL** (version 12 or later)
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install postgresql postgresql-server-dev-14
   
   # On macOS with Homebrew
   brew install postgresql
   ```

2. **C++ Compiler** with C++17 support
   ```bash
   # Check your compiler version
   g++ --version  # Should be 7.0 or later
   # or
   clang++ --version  # Should be 5.0 or later
   ```

3. **Build tools**
   ```bash
   # On Ubuntu/Debian
   sudo apt-get install build-essential
   
   # On macOS
   xcode-select --install
   ```

## Build and Install

1. **Clone or download** this repository

2. **Build the extension**:
   ```bash
   cd pg-jsondiff
   make
   ```

3. **Install the extension** (requires sudo):
   ```bash
   sudo make install
   ```

4. **Enable in your database**:
   ```sql
   -- Connect to your database
   psql -d your_database
   
   -- Create the extension
   CREATE EXTENSION pg_json_diff;
   
   -- Verify installation
   \dx pg_json_diff
   ```

## Quick Test

```sql
-- Generate a diff
SELECT generate_json_diff(
    '{"name": "Alice", "age": 30}'::JSONB,
    '{"name": "Alice", "age": 31, "city": "NYC"}'::JSONB
);

-- Expected output:
-- [{"op": "replace", "path": "/age", "value": 31}, {"op": "add", "path": "/city", "value": "NYC"}]
```

## Run Tests

```bash
# Make sure the extension is built and installed first
make test
```

Or manually:
```bash
psql -d postgres -f test/test_pg_json_diff.sql
```

## Uninstall

To uninstall the extension:

```sql
-- From within PostgreSQL
DROP EXTENSION pg_json_diff;
```

```bash
# To remove files from the system
sudo make uninstall
```

## Troubleshooting

### Can't find pg_config

If the build fails with "pg_config: command not found":

```bash
# On Ubuntu/Debian
sudo apt-get install postgresql-server-dev-14  # Replace 14 with your version

# On macOS
export PATH="/usr/local/opt/postgresql/bin:$PATH"
# or add to your ~/.zshrc or ~/.bashrc
```

### Permission denied during installation

Make sure to use `sudo` for the install command:
```bash
sudo make install
```

### Extension not loading

Check PostgreSQL logs for specific error messages:
```bash
# On Ubuntu/Debian
sudo tail -f /var/log/postgresql/postgresql-14-main.log

# On macOS
tail -f /usr/local/var/log/postgresql@14.log
```

## Next Steps

See the full [README.md](README.md) for:
- Detailed function documentation
- Usage examples
- Performance considerations
- Advanced features

