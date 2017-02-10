//
//  Logger.swift
//  Loper
//
//  Created by Skylar Schipper on 2/9/17.
//  Copyright (c) 2017 Planning Center
//

import Foundation

internal func DebugLog(_ msg: String) {
#if DEBUG && false
    print("Loper [DEBUG] - \(msg)")
#endif
}
