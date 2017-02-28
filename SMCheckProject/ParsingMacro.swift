//
//  ParsingMacro.swift
//  SMCheckProject
//
//  Created by daiming on 2017/2/22.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa

class ParsingMacro: NSObject {
    class func parsing(tokens:Array<String>) -> Macro {
        var macro = Macro()
        macro.tokens = tokens
        return macro
    }
}
