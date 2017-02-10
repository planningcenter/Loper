//
//  ResultBuilder.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import sqlite3

internal class ResultBuilder {
    typealias Row = (name: String, value: Any)

    let stmt: OpaquePointer
    let query: Query

    var finalized: Bool = false

    internal init(_ stmt: OpaquePointer, query: Query) {
        self.stmt = stmt
        self.query = query
    }

    deinit {
        try? finalize()
    }

    func results() throws -> [[String: Any]] {
        var results: [[String: Any]] = []
        while try self.next() {
            let row = try self.buildRow()
            results.append(row)
        }
        return results
    }

    private func buildRow() throws -> [String: Any] {
        let count = sqlite3_data_count(self.stmt)
        guard count > 0 else {
            throw StoreError(.nullDataInRow)
        }

        var result: [String: Any] = [:]

        let columnCount = sqlite3_column_count(self.stmt)
        for idx in 0..<columnCount {
            let row = try self.buildResult(atColumn: idx)
            result[row.name] = row.value
        }

        return result
    }

    private func buildResult(atColumn column: Int32) throws -> Row {
        let name = try self.name(forColumn: column)
        let value = try self.value(forColumn: column)
        return (name: name, value: value)
    }

    private func name(forColumn column: Int32) throws -> String {
        guard let buffer = sqlite3_column_name(self.stmt, column) else {
            throw StoreError(.unknownColumnName)
        }
        let str = unsafeBitCast(buffer, to: UnsafePointer<CChar>.self)
        guard let name = String(utf8String: str) else {
            throw StoreError(.unknownColumnFmt)
        }
        return name
    }

    private func value(forColumn column: Int32) throws -> Any {
        let type = sqlite3_column_type(self.stmt, column)

        switch type {
        case SQLITE_NULL:
            return NSNull()
        case SQLITE_INTEGER:
            return sqlite3_column_int64(self.stmt, column)
        case SQLITE_FLOAT:
            return sqlite3_column_double(self.stmt, column)
        case SQLITE_BLOB:
            guard let buffer = sqlite3_column_blob(self.stmt, column) else {
                throw StoreError(.blobReadFailure)
            }
            let voidBuffer = unsafeBitCast(buffer, to: UnsafePointer<UInt8>.self)
            let length = sqlite3_column_bytes(self.stmt, column)
            return Data(bytes: voidBuffer, count: Int(length))
        case SQLITE_TEXT:
            guard let raw = sqlite3_column_text(self.stmt, column) else {
                throw StoreError(.stringReadFailure)
            }
            let cStr = unsafeBitCast(raw, to: UnsafePointer<CChar>.self)
            guard let string = String(utf8String: cStr) else {
                throw StoreError(.stringConvertFailure)
            }
            return string
        default:
            throw StoreError(.unknownType)
        }
    }

    private func next() throws -> Bool {
        let status = sqlite3_step(self.stmt)

        try SQLiteError.check(status: status)

        return (status == SQLITE_ROW)
    }

    private func finalize() throws {
        guard self.finalized == false else {
            return
        }

        let status = sqlite3_finalize(self.stmt)
        try SQLiteError.check(status: status)
        self.finalized = true
    }
}
