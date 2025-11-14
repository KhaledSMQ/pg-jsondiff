/*
 * json_diff_impl.h
 * 
 * Header file for JSON diff, patch, and merge operations
 * C++ interface using nlohmann/json library
 * 
 * Copyright (c) 2025 Khaled Sameer <khaled.smq@hotmail.com>
 * Licensed under the MIT License
 * https://khaled.ee
 */

#ifndef JSON_DIFF_IMPL_H
#define JSON_DIFF_IMPL_H

#include <nlohmann/json.hpp>

// We use nlohmann::json as the common type for our C++ logic
using json = nlohmann::json;

/*
 * generate_diff
 * * Takes two C++ json objects and returns a C++ json patch object.
 * This is a thin wrapper around nlohmann::json::diff.
 */
json generate_diff(const json &source, const json &target);

/*
 * apply_json_patch
 * * Takes a C++ json document and a C++ json patch object and applies it.
 * This is a thin wrapper around nlohmann::json::patch.
 */
json apply_json_patch(const json &doc, const json &patch);

/*
 * merge_json_patch
 * * Takes a C++ json document and a C++ json merge patch object.
 * This is a wrapper around nlohmann::json::merge_patch.
 */
json merge_json_patch(const json &doc, const json &merge_patch);

#endif // JSON_DIFF_IMPL_H