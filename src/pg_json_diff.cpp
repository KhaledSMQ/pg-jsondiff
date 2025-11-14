/*
 * pg_json_diff.cpp
 * 
 * PostgreSQL extension for JSON diff, patch, and merge operations
 * Implements RFC 6902 (JSON Patch) and RFC 7386 (JSON Merge Patch)
 * 
 * Copyright (c) 2025 Khaled Sameer <khaled.smq@hotmail.com>
 * Licensed under the MIT License
 * https://khaled.ee
 */

#include "json_diff_impl.h"

extern "C" {
#include "postgres.h"
#include "fmgr.h"
#include "utils/jsonb.h"     // For Jsonb, jsonb_to_cstring
#include "utils/builtins.h"  // For cstring_to_text, text_to_cstring
#include "catalog/pg_type.h" // For JSONBOID
}

// We need nlohmann/json here for the ::parse and ::dump functions
#include <nlohmann/json.hpp>
#include <string>

using json = nlohmann::json;

// --- Helper Functions ---
// These two helpers are the core of the new, simpler conversion.

/*
 * Helper to convert Postgres Jsonb* to nlohmann::json
 * * This is the "safe" way:
 * 1. Postgres Jsonb* -> C string (char*)
 * 2. C string (char*) -> C++ std::string
 * 3. C++ std::string -> nlohmann::json
 */
static json jsonb_to_json(Jsonb *jb) {
    // Use jsonb_out to convert jsonb to cstring
    Datum jsonb_datum = JsonbPGetDatum(jb);
    char *cstring = DatumGetCString(DirectFunctionCall1(jsonb_out, jsonb_datum));
    
    // Parse the string
    // We use a std::string to ensure proper memory management
    json j = json::parse(std::string(cstring));
    
    // Free the C string Postgres allocated
    pfree(cstring);
    
    return j;
}

/*
 * Helper to convert nlohmann::json to Postgres Jsonb*
 * * This is the "safe" way:
 * 1. nlohmann::json -> C++ std::string
 * 2. C++ std::string -> C string (char*)
 * 3. C string (char*) -> Postgres Jsonb*
 */
static Jsonb* json_to_jsonb(const json &j) {
    // Use nlohmann's dump function to get a string
    std::string str = j.dump();
    
    // Use Postgres's built-in function to parse the string into jsonb
    // We pass the string directly to jsonb_in
    Datum result = DirectFunctionCall1(jsonb_in, CStringGetDatum(str.c_str()));
    
    return DatumGetJsonbP(result);
}

// --- End Helper Functions ---


extern "C" {

#ifdef PG_MODULE_MAGIC
PG_MODULE_MAGIC;
#endif

// Function declarations
PG_FUNCTION_INFO_V1(pg_generate_json_diff);
PG_FUNCTION_INFO_V1(pg_apply_patch);
PG_FUNCTION_INFO_V1(pg_merge_patch);

/*
 * pg_generate_json_diff (The C -> C++ Bridge)
 */
Datum pg_generate_json_diff(PG_FUNCTION_ARGS) {
    // 1. Get Postgres args
    Jsonb *source_jsonb = PG_GETARG_JSONB_P(0);
    Jsonb *target_jsonb = PG_GETARG_JSONB_P(1);
    
    try {
        // 2. Convert to C++ types
        json source = jsonb_to_json(source_jsonb);
        json target = jsonb_to_json(target_jsonb);
        
        // 3. Call our simple C++ implementation
        json patch = generate_diff(source, target);
        
        // 4. Convert back to Postgres type
        Jsonb *result = json_to_jsonb(patch);
        PG_RETURN_JSONB_P(result);

    } catch (const std::exception &e) {
        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("Error generating JSON diff: %s", e.what())));
    }
    
    PG_RETURN_NULL();
}

/*
 * pg_apply_patch (The C -> C++ Bridge)
 */
Datum pg_apply_patch(PG_FUNCTION_ARGS) {
    // 1. Get Postgres args
    Jsonb *document_jsonb = PG_GETARG_JSONB_P(0);
    Jsonb *patch_jsonb = PG_GETARG_JSONB_P(1);
    
    try {
        // 2. Convert to C++ types
        json document = jsonb_to_json(document_jsonb);
        json patch = jsonb_to_json(patch_jsonb);
        
        // 3. Call our simple C++ implementation
        json result_json = apply_json_patch(document, patch);
        
        // 4. Convert back to Postgres type
        Jsonb *result = json_to_jsonb(result_json);
        PG_RETURN_JSONB_P(result);

    } catch (const std::exception &e) {
        // nlohmann::json::patch throws exceptions on failure (e.g., test op)
        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("Error applying JSON patch: %s", e.what())));
    }
    
    PG_RETURN_NULL();
}

/*
 * pg_merge_patch (The C -> C++ Bridge)
 */
Datum pg_merge_patch(PG_FUNCTION_ARGS) {
    // 1. Get Postgres args
    Jsonb *document_jsonb = PG_GETARG_JSONB_P(0);
    Jsonb *merge_patch_jsonb = PG_GETARG_JSONB_P(1);
    
    try {
        // 2. Convert to C++ types
        json document = jsonb_to_json(document_jsonb);
        json merge_patch = jsonb_to_json(merge_patch_jsonb);
        
        // 3. Call our simple C++ implementation
        json result_json = merge_json_patch(document, merge_patch);
        
        // 4. Convert back to Postgres type
        Jsonb *result = json_to_jsonb(result_json);
        PG_RETURN_JSONB_P(result);

    } catch (const std::exception &e) {
        ereport(ERROR,
                (errcode(ERRCODE_INTERNAL_ERROR),
                 errmsg("Error merging JSON: %s", e.what())));
    }
    
    PG_RETURN_NULL();
}

} // extern "C"