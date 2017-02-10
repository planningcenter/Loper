//
//  Value.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
let SQLITE_STATIC    = unsafeBitCast(0, to: sqlite3_destructor_type.self)

internal enum Value {
    case null
    case string(String)
    case integer(Int64)
    case double(Double)
    case data(Data)

    func bind(toColumn col: Int, inStatement stmt: OpaquePointer) throws {
        switch self {
        case .null:
            let status = sqlite3_bind_null(stmt, Int32(col))
            try SQLiteError.check(status: status)
        case .string(let s):
            let status = sqlite3_bind_text(stmt, Int32(col), s, -1, SQLITE_TRANSIENT)
            try SQLiteError.check(status: status)
        case .integer(let i):
            let status = sqlite3_bind_int64(stmt, Int32(col), sqlite3_int64(i))
            try SQLiteError.check(status: status)
        case .double(let d):
            let status = sqlite3_bind_double(stmt, Int32(col), d)
            try SQLiteError.check(status: status)
        case .data(let d):
            let count = Int32(d.count)
            let status: Int32 = d.withUnsafeBytes {
                return sqlite3_bind_blob(stmt, Int32(col), $0, count, SQLITE_TRANSIENT)
            }
            try SQLiteError.check(status: status)
        }
    }

    var valueType: ValueType {
        switch self {
        case .data:
            return .data
        case .null:
            return .data
        case .string:
            return .string
        case .double:
            return .double
        case .integer:
            return .integer
        }
    }
}

internal enum ValueType : Int {
    case string  = 0
    case double  = 1
    case data    = 2
    case integer = 3

    var columnName: String {
        switch self {
        case .string:
            return "str"
        case .double:
            return "dbl"
        case .data:
            return "dat"
        case .integer:
            return "itg"
        }
    }
}
