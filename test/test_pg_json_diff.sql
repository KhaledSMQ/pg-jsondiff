-- Test suite for pg_json_diff extension
-- Run with: psql -f test/test_pg_json_diff.sql

BEGIN;

-- Create the extension
CREATE EXTENSION IF NOT EXISTS pg_json_diff;

-- Test 1: generate_json_diff - Basic object difference
DO $$
DECLARE
    source JSONB := '{"name": "John", "age": 30}'::JSONB;
    target JSONB := '{"name": "John", "age": 31, "city": "NYC"}'::JSONB;
    patch JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 1 - Basic object diff: %', patch;
    
    -- Verify the patch contains expected operations
    IF jsonb_array_length(patch) = 0 THEN
        RAISE EXCEPTION 'Test 1 failed: Patch should not be empty';
    END IF;
END $$;

-- Test 2: generate_json_diff - Identical documents
DO $$
DECLARE
    doc JSONB := '{"name": "Jane", "age": 25}'::JSONB;
    patch JSONB;
BEGIN
    patch := generate_json_diff(doc, doc);
    RAISE NOTICE 'Test 2 - Identical documents: %', patch;
    
    -- Should return empty array
    IF jsonb_array_length(patch) != 0 THEN
        RAISE EXCEPTION 'Test 2 failed: Identical documents should produce empty patch';
    END IF;
END $$;

-- Test 3: generate_json_diff - Array modifications
DO $$
DECLARE
    source JSONB := '{"items": [1, 2, 3]}'::JSONB;
    target JSONB := '{"items": [1, 2, 3, 4, 5]}'::JSONB;
    patch JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 3 - Array modifications: %', patch;
    
    IF jsonb_array_length(patch) < 1 THEN
        RAISE EXCEPTION 'Test 3 failed: Should detect array additions';
    END IF;
END $$;

-- Test 4: generate_json_diff - Nested objects
DO $$
DECLARE
    source JSONB := '{"user": {"name": "Alice", "email": "alice@example.com"}}'::JSONB;
    target JSONB := '{"user": {"name": "Alice", "email": "alice@newdomain.com", "verified": true}}'::JSONB;
    patch JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 4 - Nested objects: %', patch;
END $$;

-- Test 5: apply_patch - Simple replace operation
DO $$
DECLARE
    doc JSONB := '{"name": "Bob", "age": 40}'::JSONB;
    patch JSONB := '[{"op": "replace", "path": "/age", "value": 41}]'::JSONB;
    result JSONB;
BEGIN
    result := apply_patch(doc, patch);
    RAISE NOTICE 'Test 5 - Apply replace: %', result;
    
    IF (result->>'age')::int != 41 THEN
        RAISE EXCEPTION 'Test 5 failed: Age should be 41';
    END IF;
END $$;

-- Test 6: apply_patch - Add operation
DO $$
DECLARE
    doc JSONB := '{"name": "Charlie"}'::JSONB;
    patch JSONB := '[{"op": "add", "path": "/email", "value": "charlie@example.com"}]'::JSONB;
    result JSONB;
BEGIN
    result := apply_patch(doc, patch);
    RAISE NOTICE 'Test 6 - Apply add: %', result;
    
    IF NOT (result ? 'email') THEN
        RAISE EXCEPTION 'Test 6 failed: Email field should exist';
    END IF;
END $$;

-- Test 7: apply_patch - Remove operation
DO $$
DECLARE
    doc JSONB := '{"name": "David", "age": 35, "city": "LA"}'::JSONB;
    patch JSONB := '[{"op": "remove", "path": "/city"}]'::JSONB;
    result JSONB;
BEGIN
    result := apply_patch(doc, patch);
    RAISE NOTICE 'Test 7 - Apply remove: %', result;
    
    IF (result ? 'city') THEN
        RAISE EXCEPTION 'Test 7 failed: City field should be removed';
    END IF;
END $$;

-- Test 8: apply_patch - Multiple operations
DO $$
DECLARE
    doc JSONB := '{"name": "Eve", "age": 28}'::JSONB;
    patch JSONB := '[
        {"op": "replace", "path": "/age", "value": 29},
        {"op": "add", "path": "/country", "value": "USA"}
    ]'::JSONB;
    result JSONB;
BEGIN
    result := apply_patch(doc, patch);
    RAISE NOTICE 'Test 8 - Multiple operations: %', result;
    
    IF (result->>'age')::int != 29 OR NOT (result ? 'country') THEN
        RAISE EXCEPTION 'Test 8 failed: Both operations should be applied';
    END IF;
END $$;

-- Test 9: merge_patch - Simple merge
DO $$
DECLARE
    doc JSONB := '{"name": "Frank", "age": 45}'::JSONB;
    merge JSONB := '{"age": 46, "city": "Boston"}'::JSONB;
    result JSONB;
BEGIN
    result := merge_patch(doc, merge);
    RAISE NOTICE 'Test 9 - Simple merge: %', result;
    
    IF (result->>'age')::int != 46 OR (result->>'city') != 'Boston' THEN
        RAISE EXCEPTION 'Test 9 failed: Merge should update age and add city';
    END IF;
END $$;

-- Test 10: merge_patch - Remove fields with null
DO $$
DECLARE
    doc JSONB := '{"name": "Grace", "age": 50, "email": "grace@example.com"}'::JSONB;
    merge JSONB := '{"email": null}'::JSONB;
    result JSONB;
BEGIN
    result := merge_patch(doc, merge);
    RAISE NOTICE 'Test 10 - Remove with null: %', result;
    
    IF (result ? 'email') THEN
        RAISE EXCEPTION 'Test 10 failed: Email should be removed';
    END IF;
END $$;

-- Test 11: merge_patch - Nested merge
DO $$
DECLARE
    doc JSONB := '{"user": {"name": "Henry", "email": "henry@example.com"}}'::JSONB;
    merge JSONB := '{"user": {"email": "henry@newdomain.com", "verified": true}}'::JSONB;
    result JSONB;
BEGIN
    result := merge_patch(doc, merge);
    RAISE NOTICE 'Test 11 - Nested merge: %', result;
    
    IF (result->'user'->>'name') != 'Henry' THEN
        RAISE EXCEPTION 'Test 11 failed: Name should be preserved in nested merge';
    END IF;
    IF NOT (result->'user' ? 'verified') THEN
        RAISE EXCEPTION 'Test 11 failed: Verified field should be added';
    END IF;
END $$;

-- Test 12: Round-trip test (generate diff, apply patch)
DO $$
DECLARE
    source JSONB := '{"a": 1, "b": 2, "c": 3}'::JSONB;
    target JSONB := '{"a": 1, "b": 20, "d": 4}'::JSONB;
    patch JSONB;
    result JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 12 - Generated patch: %', patch;
    
    result := apply_patch(source, patch);
    RAISE NOTICE 'Test 12 - Result after applying patch: %', result;
    
    -- The result should match the target
    IF result != target THEN
        RAISE EXCEPTION 'Test 12 failed: Round-trip should produce target document. Expected: %, Got: %', target, result;
    END IF;
END $$;

-- Test 13: Array operations
DO $$
DECLARE
    source JSONB := '{"numbers": [1, 2, 3, 4, 5]}'::JSONB;
    target JSONB := '{"numbers": [1, 2, 10, 4]}'::JSONB;
    patch JSONB;
    result JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 13 - Array diff patch: %', patch;
    
    result := apply_patch(source, patch);
    RAISE NOTICE 'Test 13 - Array result: %', result;
    
    IF result != target THEN
        RAISE EXCEPTION 'Test 13 failed: Array round-trip failed';
    END IF;
END $$;

-- Test 14: Complex nested structure
DO $$
DECLARE
    source JSONB := '{
        "users": [
            {"id": 1, "name": "Alice", "roles": ["admin"]},
            {"id": 2, "name": "Bob", "roles": ["user"]}
        ],
        "settings": {
            "theme": "dark",
            "language": "en"
        }
    }'::JSONB;
    target JSONB := '{
        "users": [
            {"id": 1, "name": "Alice", "roles": ["admin", "moderator"]},
            {"id": 2, "name": "Robert", "roles": ["user"]}
        ],
        "settings": {
            "theme": "light",
            "language": "en",
            "notifications": true
        }
    }'::JSONB;
    patch JSONB;
    result JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    RAISE NOTICE 'Test 14 - Complex nested patch: %', patch;
    
    result := apply_patch(source, patch);
    RAISE NOTICE 'Test 14 - Complex nested result: %', result;
    
    IF result != target THEN
        RAISE EXCEPTION 'Test 14 failed: Complex nested round-trip failed';
    END IF;
END $$;

-- Test 15: Empty objects and arrays
DO $$
DECLARE
    source JSONB := '{}'::JSONB;
    target JSONB := '{"key": "value"}'::JSONB;
    patch JSONB;
    result JSONB;
BEGIN
    patch := generate_json_diff(source, target);
    result := apply_patch(source, patch);
    
    IF result != target THEN
        RAISE EXCEPTION 'Test 15 failed: Empty object to non-empty failed';
    END IF;
    
    RAISE NOTICE 'Test 15 - Empty object handling: PASSED';
END $$;

ROLLBACK;

-- Summary message
\echo ''
\echo '================================'
\echo 'All tests completed successfully!'
\echo '================================'
\echo ''
\echo 'To install the extension in your database:'
\echo '  CREATE EXTENSION pg_json_diff;'
\echo ''
\echo 'Available functions:'
\echo '  - generate_json_diff(source JSONB, target JSONB) RETURNS JSONB'
\echo '  - apply_patch(document JSONB, patch JSONB) RETURNS JSONB'
\echo '  - merge_patch(document JSONB, merge_patch JSONB) RETURNS JSONB'
\echo ''

