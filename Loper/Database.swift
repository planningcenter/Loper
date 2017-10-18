//
//  Database.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

internal class Database {
    let path: String

    let state = Mutex()

    init(path: String) {
        self.path = path
    }

    deinit {
        try! self.close()
    }

    internal var db: OpaquePointer? = nil

    var isOpen: Bool {
        return self.state.synchronized { self._open }
    }

    fileprivate var _open: Bool {
        return self.db != nil
    }

    func open() throws {
        try self.state.synchronized {
            guard self.db == nil else {
                return
            }
            let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE

            let status = sqlite3_open_v2(self.path, &self.db, flags, nil)

            guard status == SQLITE_OK else {
                self.db = nil
                throw SQLiteError(status, nil)
            }
        }

    }

    func close() throws {
        try self.state.synchronized {
            guard let db = self.db else {
                return
            }
            let status = sqlite3_close_v2(db)
            guard status == SQLITE_OK else {
                throw SQLiteError(status, db)
            }
            self.db = nil
        }
    }

    func execute(update: Query) throws {
        try self.state.synchronized {
            guard let db = self.db else {
                throw StoreError(.unopened)
            }
            let statement = try update.statement(forDB: db)
            DebugLog("Running (update): \(update.sql)")

            let status = sqlite3_step(statement.stmt)
            if status == SQLITE_ROW {
                fatalError("Can't execute an update with a query \(update.sql)")
            }

            if sqlite3_finalize(statement.stmt) != SQLITE_OK {
                print("Failed to finalize statement for update")
            }

            try SQLiteError.check(status: status, db: db)
        }
    }

    func execute(query: Query) throws -> [[String: Any]] {
        return try self.state.synchronized {
            guard let db = self.db else {
                throw StoreError(.unopened)
            }
            let statement = try query.statement(forDB: db)
            DebugLog("Running (query): \(query.sql)")

            let builder = ResultBuilder(statement.stmt, query: query)
            
            return try builder.results()
        }
    }
}
