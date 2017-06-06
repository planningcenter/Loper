//
//  Mutex.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation
import Darwin.POSIX.pthread

/// A wrapper class around a mutex
public final class Mutex {
    public enum MutexType {
        /// This type of mutex does not check for usage errors.  It will deadlock if reentered, and result in undefined behavior if a locked mutex is unlocked by
        /// another thread.  Attempts to unlock an already unlocked `normal` mutex will result in undefined behavior.
        case normal

        /// These mutexes allow recursive locking.  An attempt to relock a `recursive` mutex that is already locked by the same thread succeeds.  An
        /// equivalent number of `unlock()` calls are needed before the mutex will wake another thread waiting on this lock.  If a thread attempts to
        /// unlock a `recursive` mutex that is locked by another thread, an error will be returned.  If a thread attempts to unlock a
        /// `recursive` thread that is unlocked, an error will be returned.
        case recursive

        /// These mutexes do check for usage errors.  If an attempt is made to relock a `errorChecking` mutex without first dropping the lock, an error
        /// will be returned.  If a thread attempts to unlock a `errorChecking` mutex that is locked by another thread, an error will be returned.  If a
        /// thread attempts to unlock a `errorChecking` thread that is unlocked, an error will be returned.
        case errorChecking

        /// Same as normal(?) read your systems man page on `pthread_mutexattr_settype`
        case `default`
    }

    private var mutex = pthread_mutex_t()

    /// Create a new mutex
    ///
    /// - Parameter type: The type of mutex to create.
    public init(type: MutexType = .normal) {
        var attr = pthread_mutexattr_t()
        guard pthread_mutexattr_init(&attr) == 0 else {
            preconditionFailure("Failed to init mutex attribute")
        }

        switch type {
        case .normal:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_NORMAL)
        case .recursive:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_RECURSIVE)
        case .errorChecking:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK)
        case .default:
            pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_DEFAULT)

        }

        guard pthread_mutex_init(&mutex, &attr) == 0 else {
            preconditionFailure("Failed to init mutex")
        }
    }

    deinit {
        pthread_mutex_destroy(&mutex)
    }

    /// Acquire the lock.
    ///
    /// - Returns: Success if the lock was acquired.
    @discardableResult
    public final func lock() -> Bool {
        return pthread_mutex_lock(&mutex) == 0
    }


    /// Unlock the mutex.  Must be called on the same thread the lock was aquired from.
    ///
    /// - Returns: Success if the lock was released.
    @discardableResult
    public final func unlock() -> Bool {
        return pthread_mutex_unlock(&mutex) == 0
    }


    /// Acquire the lock.  If the mutex is already locked, this will not wait for the lock to become possible.
    ///
    /// - Returns: True if the lock was acquired.  False if the lock could not be acquired.
    public final func tryLock() -> Bool {
        return pthread_mutex_trylock(&mutex) == 0
    }


    /// Perform the passed block within the lock
    ///
    /// - Parameter block: The block to perform
    public final func synchronized<T>(_ block: () throws -> (T)) rethrows -> T {
        self.lock()
        defer { self.unlock() }
        return try block()
    }
}
