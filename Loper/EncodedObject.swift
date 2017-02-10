//
//  EncodedObject.swift
//  Loper
//
//  Created by Skylar Schipper on 2/10/17.
//  Copyright © 2017 Planning Center. All rights reserved.
//

import Foundation

internal final class EncodedObject : NSObject, NSSecureCoding {
    let object: NSCoding

    static var supportsSecureCoding: Bool {
        return true
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.object, forKey: "__object")

        let klass = String(describing: type(of: self.object))
        aCoder.encode(klass, forKey: "__klass")
    }

    init?(coder aDecoder: NSCoder) {
        guard let klass = aDecoder.decodeObject(forKey: "__klass") as? String else {
            return nil
        }
        guard let expected = NSClassFromString(klass) else {
            return nil
        }
        guard let object = aDecoder.decodeObject(forKey: "__object") as? NSCoding else {
            return nil
        }
        guard expected == type(of: object) else {
            return nil;
        }
        self.object = object
    }

    init(object: NSCoding) {
        self.object = object
    }
}
