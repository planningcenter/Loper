//
//  StoreError.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation

@objc(LOPStoreErrorCode)
public enum StoreErrorCode : Int {
    case unknown              = 0
    case missingPath          = 1
    case unopened             = 2
    case statementFailed      = 3
    case argCountMismatch     = 4
    case notFound             = 5
    case invalidID            = 6
    case nullDataInRow        = 7
    case unknownColumnName    = 8
    case unknownColumnFmt     = 9
    case unknownType          = 10
    case blobReadFailure      = 11
    case stringReadFailure    = 12
    case stringConvertFailure = 13
}

public struct StoreError : CustomNSError {
    public let code: StoreErrorCode
    public let message: String

    internal init(_ code: StoreErrorCode, _ message: String? = nil) {
        self.code = code
        self.message = message ?? NSLocalizedString("Unknown Error", comment: "Loper unknown error default message")
    }

    public static var errorDomain: String {
        return "LoperErrorDomain"
    }

    public var errorCode: Int {
        return self.code.rawValue
    }

    public var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey : self.message
        ]
    }
}
