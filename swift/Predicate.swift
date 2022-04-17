#!/usr/bin/env swift

// To run on windows:
// - C:\Library\Developer\Toolchains\unknown-Asserts-development.xctoolchain\usr\bin\swift.exe .\Predicate.swift -sdk C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk -I C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk\usr\lib\swift -L C:\Library\Developer\Platforms\Windows.platform\Developer\SDKs\Windows.sdk\usr\lib\swift\windows
// Current get ERROR: `unable to load standard library for target 'x86_64-unknown-windows-msvc'`
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
