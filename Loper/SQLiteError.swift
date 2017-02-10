//
//  SQLiteError.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

public struct SQLiteError : CustomNSError {
    public let code: Int32
    public let message: String

    internal init(_ code: Int32, _ db: OpaquePointer?) {
        self.code = code
        self.message = lastErrorMessage(db)
    }

    public static var errorDomain: String {
        return "LoperSQLiteErrorDomain"
    }

    public var errorCode: Int {
        return Int(self.code)
    }

    public var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey : self.message
        ]
    }

    internal static func check(status: Int32, db: OpaquePointer? = nil, values: Set<Int32> = [SQLITE_OK, SQLITE_ROW, SQLITE_DONE], handler: ((Void) -> (Void))? = nil) throws {
        guard !values.contains(status) else {
            return
        }
        handler?()
        throw SQLiteError(status, db)
    }
}

fileprivate func lastErrorMessage(_ db: OpaquePointer?) -> String {
    guard let ptr = db else {
        return "Unknown Error (0)"
    }
    guard let result = sqlite3_errmsg(ptr) else {
        return "Unknown Error (1)"
    }
    guard let message = String(validatingUTF8: result) else {
        return "Unknown Error (2)"
    }
    return message
}
