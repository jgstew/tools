#!/usr/bin/env swift

import Foundation

// https://www.swiftbysundell.com/articles/predicates-in-swift/

// Examples:
// - https://www.macblog.org/posts/stop-autopkg-virustotal/
//   - NOT virus_total_analyzer_summary_result.data.ratio BEGINSWITH '0'
// - download_changed == FALSE

let examplePredicateString = "download_changed == false"
let envTest = ["download_changed": "false"]

print("NSPredicate:", examplePredicateString)
print("fake env dict:", envTest)

let resultPredicate = NSPredicate(fromMetadataQueryString: examplePredicateString)

let searchResults = resultPredicate?.evaluate(with: envTest)

print("Result:", searchResults!)
