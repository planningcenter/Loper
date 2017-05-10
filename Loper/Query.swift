//
//  Query.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

internal class Statement {
    let stmt: OpaquePointer

    private let pointer: UnsafeMutablePointer<OpaquePointer?>

    init(_ db: OpaquePointer, _ sql: String) throws {
        let pointer: UnsafeMutablePointer<OpaquePointer?> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<OpaquePointer>.size)
        let status = sqlite3_prepare(db, sql, -1, pointer, nil)

        try SQLiteError.check(status: status, db: db) {
            pointer.deallocate(capacity: MemoryLayout<OpaquePointer>.size)
            sqlite3_finalize(pointer.pointee)
        }

        guard let stmt = pointer.pointee else {
            pointer.deallocate(capacity: MemoryLayout<OpaquePointer>.size)
            sqlite3_finalize(pointer.pointee)
            throw StoreError(.statementFailed)
        }

        self.pointer = pointer
        self.stmt = stmt
    }

    deinit {
        self.pointer.deallocate(capacity: MemoryLayout<OpaquePointer>.size)
    }
}

internal struct Query {
    let sql: String
    let args: [Value]

    init(_ sql: String, _ args: [Value]? = nil) {
        self.sql = sql
        self.args = args ?? []
    }

    func statement(forDB db: OpaquePointer) throws -> Statement {
        let statement = try Statement(db, self.sql)

        let count = Int(sqlite3_bind_parameter_count(statement.stmt))

        guard self.args.count == count else {
            sqlite3_finalize(statement.stmt)
            throw StoreError(.argCountMismatch)
        }

        for i in 0..<count {
            let value = self.args[i]
            do {
                try value.bind(toColumn: i + 1, inStatement: statement.stmt)
            } catch let e {
                sqlite3_finalize(statement.stmt)
                throw e
            }
        }

        return statement
    }
}
