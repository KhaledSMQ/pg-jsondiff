-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pg_json_diff" to load this file. \quit

-- Generate JSON Patch (RFC 6902) from two JSONB documents
CREATE FUNCTION generate_json_diff(source JSONB, target JSONB)
RETURNS JSONB
AS 'MODULE_PATHNAME', 'pg_generate_json_diff'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION generate_json_diff(JSONB, JSONB) IS
'Generate a JSON Patch (RFC 6902) describing the differences between source and target JSONB documents. Returns an array of operations that transform source into target.';

-- Apply a JSON Patch (RFC 6902) to a JSONB document
CREATE FUNCTION apply_patch(document JSONB, patch JSONB)
RETURNS JSONB
AS 'MODULE_PATHNAME', 'pg_apply_patch'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION apply_patch(JSONB, JSONB) IS
'Apply a JSON Patch (RFC 6902) to a JSONB document. The patch should be an array of operations (add, remove, replace, move, copy, test) that modify the document.';

-- Merge two JSONB documents using JSON Merge Patch (RFC 7386)
CREATE FUNCTION merge_patch(document JSONB, merge_patch JSONB)
RETURNS JSONB
AS 'MODULE_PATHNAME', 'pg_merge_patch'
LANGUAGE C IMMUTABLE STRICT;

COMMENT ON FUNCTION merge_patch(JSONB, JSONB) IS
'Merge two JSONB documents using JSON Merge Patch (RFC 7386). The merge_patch document is applied to the document, with null values removing keys and other values being set or merged recursively.';

