//
//  Normalizer.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation

private let alphanumeric = CharacterSet.alphanumerics.inverted
func NormalizeKey(_ string: String) -> String {
     return string.lowercased().components(separatedBy: alphanumeric).joined(separator: "_")
}
