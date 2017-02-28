//
//  ParsingProperty.swift
//  SMCheckProject
//
//  Created by daiming on 2017/2/23.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa

class ParsingProperty: NSObject {
    class func parsing(tokens:Array<String>) -> Property {
        var aProperty = Property()
        var inBktTf = false
        var inTypeTf = false
        var inNameTf = false
        var setName = ""
        
        for tk in tokens {
            //处理设置set
            if tk == Sb.rBktL && !inBktTf {
                inBktTf = true
            } else if tk == Sb.comma && inBktTf {
                aProperty.sets.append(setName)
            } else if tk == Sb.rBktR && inBktTf {
                aProperty.sets.append(setName)
                inBktTf = false
                setName = ""
                inTypeTf = true
                continue
            } else if inBktTf {
                setName = tk
            }
            //处理类型和属性名
            if inTypeTf && !inNameTf && (tk != Sb.agBktL || tk != Sb.agBktR) {
                aProperty.type = tk
                inNameTf = true
                continue
            }
            if inTypeTf && tk == Sb.agBktL {
                inNameTf = false
            }
            if inTypeTf && tk == Sb.agBktR {
                inNameTf = true
                continue
            }
            if inNameTf && tk != Sb.asterisk && tk != Sb.semicolon{
                aProperty.name = tk
            }
            
        }
        
        return aProperty
    }
}
