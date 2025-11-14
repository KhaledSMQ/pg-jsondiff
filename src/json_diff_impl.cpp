/*
 * json_diff_impl.cpp
 * 
 * Core C++ implementation of JSON diff, patch, and merge operations
 * Uses the nlohmann/json library
 * 
 * Copyright (c) 2025 Khaled Sameer <khaled.smq@hotmail.com>
 * Licensed under the MIT License
 * https://khaled.ee
 */

#include "json_diff_impl.h"
 

/*
 * generate_diff
 * * Calls nlohmann::json::diff directly.
 */
json generate_diff(const json &source, const json &target) {
    // nlohmann's built-in diff function
    return json::diff(source, target);
}

/*
 * apply_json_patch
 * * Calls nlohmann::json::patch directly.
 * We'll let the pg_json_diff.cpp wrapper handle any exceptions.
 */
json apply_json_patch(const json &doc, const json &patch) {
    // nlohmann's built-in patch function
    return doc.patch(patch);
}

/*
 * merge_json_patch
 * * Calls nlohmann::json::merge_patch directly.
 */
json merge_json_patch(const json &doc, const json &merge_patch) {
    json result = doc; // Start with a copy of the original
    
    // nlohmann's built-in merge_patch function
    result.merge_patch(merge_patch);
    
    return result;
}