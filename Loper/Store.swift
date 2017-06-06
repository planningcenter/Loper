//
//  Store.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation

@objc(LOPStore)
public final class Store : NSObject {
    public static let scope = "default_scope"

    /// The default persistent store.  Saved to disk
    @objc(defaultStore)
    public static let `default` = Store(persistent: true)

    /// An in-memory store.  All values will be flushed when app is terminated
    @objc(memoryStore)
    public static let memory = Store(persistent: false)

    init(persistent: Bool) {
        self.persistent = persistent
    }

    let persistent: Bool

    internal let mutex = Mutex(type: .recursive)

    internal var database: Database?

    private let tableName = "store_1"

    /// Has the database been opened and it's currently ready to be written to
    public var isOpen: Bool {
        return self.mutex.synchronized { self._open }
    }

    internal var _open: Bool {
        return self.database?.isOpen ?? false
    }

    private func databasePath() throws -> String {
        guard self.persistent else {
            return ":memory:"
        }
        guard let support = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else {
            throw StoreError(.missingPath, "Can't find application support directory")
        }
        return support.appending("/loper-1.sqlite")
    }


    /// Opens the KeyStore and sets up the the database
    public func open() throws {
        try self.mutex.synchronized {
            if self._open {
                return
            }

            let path = try self.databasePath()
            let db = Database(path: path)
            try db.open()
            self.database = db

            let columns: [String] = [
                "`id` INTEGER PRIMARY KEY",
                "`key` TEXT NOT NULL",
                "`scope` TEXT NOT NULL",
                "`type` INTEGER NOT NULL",
                "`inserted_at` REAL NOT NULL",
                "`last_read_at` REAL",
                "`\(ValueType.string.columnName)` TEXT",
                "`\(ValueType.double.columnName)` REAL",
                "`\(ValueType.integer.columnName)` INTEGER",
                "`\(ValueType.data.columnName)` BLOB",
                "UNIQUE(`key`, `scope`) ON CONFLICT REPLACE"
            ]

            let create = Query("CREATE TABLE IF NOT EXISTS `\(self.tableName)` (\(columns.joined(separator: ", ")));")

            try db.execute(update: create)
            try db.execute(update: Query("CREATE INDEX IF NOT EXISTS `\(self.tableName)_type_idx` ON `\(self.tableName)` (`type`);"))
            try db.execute(update: Query("CREATE INDEX IF NOT EXISTS `\(self.tableName)_key_idx` ON `\(self.tableName)` (`key`);"))
            try db.execute(update: Query("CREATE INDEX IF NOT EXISTS `\(self.tableName)_scp_idx` ON `\(self.tableName)` (`scope`);"))
        }
    }

    /// Close the open database handle and teardown assets.
    public func close() throws {
        try self.mutex.synchronized {
            try self.database?.close()
        }
    }

    // MARK: - Writing

    /// Writes a String into the store
    ///
    /// - Parameters:
    ///   - value: The value to write
    ///   - key: The key to store the value
    ///   - scope: The scope the key belongs to
    @objc(setString:forKey:inScope:error:)
    public func set(string value: String, forKey key: String, inScope scope: String?) throws {
        try self.set(.string(value), key, scope)
    }

    /// Writes Data into the store
    ///
    /// - Parameters:
    ///   - value: The value to write
    ///   - key: The key to store the value
    ///   - scope: The scope the key belongs to
    @objc(setData:forKey:inScope:error:)
    public func set(data value: Data, forKey key: String, inScope scope: String?) throws {
        try self.set(.data(value), key, scope)
    }

    /// Writes an Int64 into the store
    ///
    /// - Parameters:
    ///   - value: The value to write
    ///   - key: The key to store the value
    ///   - scope: The scope the key belongs to
    @objc(setInteger:forKey:inScope:error:)
    public func set(integer value: Int64, forKey key: String, inScope scope: String?) throws {
        try self.set(.integer(value), key, scope)
    }

    /// Writes a Double into the store
    ///
    /// - Parameters:
    ///   - value: The value to write
    ///   - key: The key to store the value
    ///   - scope: The scope the key belongs to
    @objc(setDouble:forKey:inScope:error:)
    public func set(double value: Double, forKey key: String, inScope scope: String?) throws {
        try self.set(.double(value), key, scope)
    }

    /// Encodes an object conforming to NSCoding into the key store
    ///
    /// - Parameters:
    ///   - value: The value to encode
    ///   - key: The key to store the value
    ///   - scope: The scope the key belongs to
    @objc(setObject:forKey:inScope:error:)
    public func set(object value: NSCoding, forKey key: String, inScope scope: String?) throws {
        let enc = EncodedObject(object: value)
        let data = NSMutableData()
        let archiver = NSKeyedArchiver(forWritingWith: data)
        archiver.encode(enc, forKey: "__enc")
        archiver.finishEncoding()
        try self.set(.data(data as Data), key, scope)
    }

    // MARK: - Reading

    /// Read a stored string value
    ///
    /// - Parameters:
    ///   - key: The key the value is stored for
    ///   - scope: The scope the key belongs to
    /// - Returns: A string or nil if it's not found in the store
    @objc(readStringForKey:inScope:)
    public func read(stringForKey key: String, inScope scope: String?) -> String? {
        guard let object = try? self.read(.string, key, scope) else {
            return nil
        }
        return object[ValueType.string.columnName] as? String
    }

    /// Read a stored data value
    ///
    /// - Parameters:
    ///   - key: The key the value is stored for
    ///   - scope: The scope the key belongs to
    /// - Returns: A data object or nil if it's not found in the store
    @objc(readDataForKey:inScope:)
    public func read(dataForKey key: String, inScope scope: String?) -> Data? {
        guard let object = try? self.read(.data, key, scope) else {
            return nil
        }
        return object[ValueType.data.columnName] as? Data
    }

    /// Read a stored integer value
    ///
    /// - Parameters:
    ///   - key: The key the value is stored for
    ///   - scope: The scope the key belongs to
    /// - Returns: An Int64.  If the value isn't found in the store 0 will be returned.
    ///            If you need to treat nil and 0 differently see `hasValue(forKey:inScope:)`
    @objc(readIntegerForKey:inScope:)
    public func read(integerForKey key: String, inScope scope: String?) -> Int64 {
        guard let object = try? self.read(.integer, key, scope) else {
            return 0
        }
        return object[ValueType.integer.columnName] as? Int64 ?? 0
    }

    /// Read a stored double value
    ///
    /// - Parameters:
    ///   - key: The key the value is stored for
    ///   - scope: The scope the key belongs to
    /// - Returns: A Double.  If the value isn't found in the store 0.0 will be returned.
    ///            If you need to treat nil and 0.0 differently see `hasValue(forKey:inScope:)`
    @objc(readDoubleForKey:inScope:)
    public func read(doubleForKey key: String, inScope scope: String?) -> Double {
        guard let object = try? self.read(.double, key, scope) else {
            return 0.0
        }
        return object[ValueType.double.columnName] as? Double ?? 0.0
    }

    /// Reads a NSCoding encoded object out of the database.
    ///
    /// - Parameters:
    ///   - key: The key the value is stored for
    ///   - scope: The scope the key belongs to
    /// - Returns: A decoded object.  If the object wasn't stored with `set(object:forKey:inScope:)` the decode will fail
    @objc(readEncodedObjectForKey:inScope:)
    public func read(encodedObjectForKey key: String, inScope scope: String?) -> AnyObject? {
        guard let data = self.read(dataForKey: key, inScope: scope) else {
            return nil
        }
        let unarchive = NSKeyedUnarchiver(forReadingWith: data)
        guard let encoded = unarchive.decodeObject(forKey: "__enc") as? EncodedObject else {
            return nil
        }
        return encoded.object
    }

    /// Does a value exist in the store for the passed key
    ///
    /// - Parameters:
    ///   - key: The key to check
    ///   - scope: The scope the key belongs to
    /// - Returns: A Bool indicating if a value exists in the store for the key/value
    @objc(hasValueForKey:inScope:)
    public func hasValue(forKey key: String, inScope scope: String?) -> Bool {
        return self.mutex.synchronized {
            guard let db = self.database else {
                return false
            }
            let f_key = NormalizeKey(key)
            let f_skp = NormalizeKey(scope ?? Store.scope)
            let args: [Value] = [
                .string(f_key),
                .string(f_skp)
            ]
            let query = Query("SELECT COUNT(*) FROM `\(self.tableName)` WHERE `key` = ? AND `scope` = ?;", args)
            guard let results = try? db.execute(query: query) else {
                return false
            }

            guard let result = results.first else {
                return false
            }

            guard let count = result["COUNT(*)"] as? Int64 else {
                return false
            }

            return (count > 0)
        }
    }

    private func read(_ type: ValueType, _ key: String, _ scope: String?) throws -> [String: Any] {
        return try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let f_key = NormalizeKey(key)
            let f_skp = NormalizeKey(scope ?? Store.scope)
            let args: [Value] = [
                .string(f_key),
                .string(f_skp),
                .integer(Int64(type.rawValue))
            ]
            let query = Query("SELECT `id`, `type`, `\(type.columnName)` FROM `\(self.tableName)` WHERE `key` = ? AND `scope` = ? AND `type` = ? LIMIT 1;", args)
            let results = try db.execute(query: query)

            guard let result = results.first else {
                throw StoreError(.notFound)
            }

            guard let id = result["id"] as? Int64 else {
                throw StoreError(.invalidID)
            }

            do {
                let args: [Value] = [
                    .double(Date().timeIntervalSince1970),
                    .integer(id)
                ]
                let query = Query("UPDATE `\(self.tableName)` SET `last_read_at` = ? WHERE `id` = ?", args)
                try db.execute(update: query)
            }

            return result
        }
    }

    // MARK: - Private Setter
    private func set(_ val: Value, _ key: String, _ scope: String?) throws {
        try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let type = val.valueType
            let col = type.columnName
            let f_key = NormalizeKey(key)
            let f_skp = NormalizeKey(scope ?? Store.scope)
            let args: [Value] = [
                .string(f_key),
                .string(f_skp),
                .double(Date().timeIntervalSince1970),
                .integer(Int64(type.rawValue)),
                val
            ]
            let query = Query("INSERT INTO `\(self.tableName)` (`key`, `scope`, `inserted_at`, `type`, `\(col)`) VALUES (?, ?, ?, ?, ?);", args)
            try self.inTransaction(db) {
                try db.execute(update: query)
            }
        }
    }

    private func inTransaction(_ db: Database, _ block: () throws -> (Void)) throws {
        try db.execute(update: Query("BEGIN TRANSACTION;"));
        do {
            try block()
        } catch let e {
            try db.execute(update: Query("ROLLBACK TRANSACTION;"))
            throw e
        }
        try db.execute(update: Query("COMMIT TRANSACTION;"))
    }

    // MARK: - Cleanup
    /// Delete all keys in the scope.
    @objc(deleteScope:error:)
    public func delete(scope: String) throws {
        try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let f_skp = NormalizeKey(scope)
            let query = Query("DELETE FROM `\(self.tableName)` WHERE `scope` = ?;", [.string(f_skp)])
            try db.execute(update: query)
        }
    }


    /// Delete's all the values in the store.
    ///
    /// Still need to run `cleanup()` to reclaim storage space in the database file.
    public func deleteAll() throws {
        try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let query = Query("DELETE FROM `\(self.tableName)` WHERE 1 = 1;")
            try db.execute(update: query)
        }
    }

    /// Delete a stored value for the passed key
    ///
    /// - Parameters:
    ///   - key: The key to delete
    ///   - scope: The scope the key belongs to
    @objc(deleteValueForKey:inScope:error:)
    public func deleteValue(forKey key: String, inScope scope: String?) throws {
        try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let f_key = NormalizeKey(key)
            let f_skp = NormalizeKey(scope ?? Store.scope)
            let args: [Value] = [
                .string(f_key),
                .string(f_skp)
            ]
            let query = Query("DELETE FROM `\(self.tableName)` WHERE `key` = ? AND `scope` = ?;",args)
            try db.execute(update: query)
        }
    }

    /// Running cleanup rebuilds the database file, repacking it into a minimal amount of disk space.
    ///
    /// See the docs on https://sqlite.org/lang_vacuum.html
    public func cleanup() throws {
        try self.mutex.synchronized {
            guard let db = self.database else {
                throw StoreError(.unopened)
            }
            let query = Query("VACUUM;")
            try db.execute(update: query)
        }
    }

    /// Hard resets the database
    ///
    /// If the store is already open, this will re-open after hard deleting
    public func hardReset() throws {
        // Mutex is recursive so we can call these locking function in the mutex
        try self.mutex.synchronized {
            let reopen = self.isOpen
            try self.close()
            if self.persistent {
                let path = try self.databasePath()
                try FileManager.default.removeItem(atPath: path)
            }
            if reopen {
                try self.open()
            }
        }
    }
}

public extension Store {
    @objc(setObject:forKey:inScope:)
    public func set(object: AnyObject, forKey key: String, inScope scope: String?) {
        switch object {
        case is String:
            try? self.set(string: (object as! String), forKey: key, inScope: scope)
        case is Data:
            try? self.set(data: (object as! Data), forKey: key, inScope: scope)
        case is Int64:
            try? self.set(integer: (object as! Int64), forKey: key, inScope: scope)
        case is Double:
            try? self.set(double: (object as! Double), forKey: key, inScope: scope)
        case is NSCoding:
            try? self.set(object: (object as! NSCoding), forKey: key, inScope: scope)
        default:
            assert(false, "Invalid type passed \(object).  Valid types are String, Data, Int64, Double or NSCoding")
        }
    }

    @objc(setBool:forKey:inScope:)
    public func set(bool: Bool, forKey key: String, inScope scope: String?) {
        try? self.set(integer: (bool) ? 1 : 0, forKey: key, inScope: scope)
    }

    @objc(stringForKey:inScope:)
    public func string(forKey key: String, inScope scope: String?) -> String? {
        return self.read(stringForKey: key, inScope: scope)
    }

    @objc(dataForKey:inScope:)
    public func data(forKey key: String, inScope scope: String?) -> Data? {
        return self.read(dataForKey: key, inScope: scope)
    }

    @objc(integerForKey:inScope:)
    public func integer(forKey key: String, inScope scope: String?) -> Int64 {
        return self.read(integerForKey: key, inScope: scope)
    }

    @objc(doubleForKey:inScope:)
    public func double(forKey key: String, inScope scope: String?) -> Double {
        return self.read(doubleForKey: key, inScope: scope)
    }

    @objc(encodedObjectForKey:inScope:)
    public func encodedObject(forKey key: String, inScope scope: String?) -> AnyObject? {
        return self.read(encodedObjectForKey: key, inScope: scope)
    }

    @objc(boolForKey:inScope:)
    public func bool(forKey key: String, inScope scope: String?) -> Bool {
        return self.read(integerForKey: key, inScope: scope) == 1
    }
}
