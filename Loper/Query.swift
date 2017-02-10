//
//  Query.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

internal struct Query {
    let sql: String
    let args: [Value]

    init(_ sql: String, _ args: [Value]? = nil) {
        self.sql = sql
        self.args = args ?? []
    }

    func statement(forDB db: OpaquePointer) throws -> OpaquePointer {
        let wrapper: UnsafeMutablePointer<OpaquePointer?> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<OpaquePointer>.size)
        let status = sqlite3_prepare(db, self.sql, -1, wrapper, nil)

        try SQLiteError.check(status: status, db: db) {
            sqlite3_finalize(wrapper.pointee)
        }

        guard let stmt = wrapper.pointee else {
            throw StoreError(.statementFailed)
        }

        let count = Int(sqlite3_bind_parameter_count(stmt))

        guard self.args.count == count else {
            sqlite3_finalize(stmt)
            throw StoreError(.argCountMismatch)
        }

        for i in 0..<count {
            let value = self.args[i]
            do {
                try value.bind(toColumn: i + 1, inStatement: stmt)
            } catch let e {
                sqlite3_finalize(stmt)
                throw e
            }
        }

        return stmt
    }
}
