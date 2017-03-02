//
//  ParsingMacro.swift
//  SMCheckProject
//
//  Created by daiming on 2017/2/22.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa

class ParsingMacro: NSObject {
    class func parsing(line:String) -> Macro {
        var macro = Macro()
        let aLine = line.replacingOccurrences(of: Sb.defineStr, with: "")
        let tokens = ParsingBase.createOCTokens(conent: aLine)
        guard let name = tokens.first else {
            return macro
        }
        macro.name = name
        macro.tokens = tokens
        return macro
    }
}
