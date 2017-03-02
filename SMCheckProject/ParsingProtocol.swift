//
//  ParsingProtocol.swift
//  SMCheckProject
//
//  Created by didi on 2017/2/28.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa

class ParsingProtocol: NSObject {
    //获取Protocol的name
    class func parsingNameFrom(line:String) -> String {
        guard let name = self.tokensFrom(line: line).first else {
            return ""
        }
        return name
    }
    
    class func tokensFrom(line:String) -> [String] {
        let aLine = line.replacingOccurrences(of: Sb.atProtocol, with: "")
        return ParsingBase.createOCTokens(conent: aLine)
    }
}
