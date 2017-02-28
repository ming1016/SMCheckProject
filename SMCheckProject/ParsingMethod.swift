//
//  ParsingMethod.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/20.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ParsingMethod: NSObject {
    class func parsing(tokens:Array<String>) -> Method {
        var mtd = Method()
        var returnTypeTf = false //是否取得返回类型
        var parsingTf = false //解析中
        var bracketCount = 0 //括弧计数
        var step = 0 //1获取参数名，2获取参数类型，3获取iName
        var types = [String]()
        var methodParam = MethodParam()
        //print("\(arr)")
        for var tk in tokens {
            tk = tk.replacingOccurrences(of: Sb.newLine, with: "")
            if (tk == Sb.semicolon || tk == Sb.braceL) && step != 1 {
                var shouldAdd = false
                
                if mtd.params.count > 1 {
                    //处理这种- (void)initWithC:(type)m m2:(type2)i, ... NS_REQUIRES_NIL_TERMINATION;入参为多参数情况
                    if methodParam.type.characters.count > 0 {
                        shouldAdd = true
                    }
                } else {
                    shouldAdd = true
                }
                if shouldAdd {
                    mtd.params.append(methodParam)
                    mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
                }
                
            } else if tk == Sb.rBktL {
                bracketCount += 1
                parsingTf = true
            } else if tk == Sb.rBktR {
                bracketCount -= 1
                if bracketCount == 0 {
                    var typeString = ""
                    for typeTk in types {
                        typeString = typeString.appending(typeTk)
                    }
                    if !returnTypeTf {
                        //完成获取返回
                        mtd.returnType = typeString
                        step = 1
                        returnTypeTf = true
                    } else {
                        if step == 2 {
                            methodParam.type = typeString
                            step = 3
                        }
                        
                    }
                    //括弧结束后的重置工作
                    parsingTf = false
                    types = []
                }
            } else if parsingTf {
                types.append(tk)
                //todo:返回block类型会使用.设置值的方式，目前获取用过方法方式没有.这种的解析，暂时作为
                if tk == Sb.upArrow {
                    mtd.returnTypeBlockTf = true
                }
            } else if tk == Sb.colon {
                step = 2
            } else if step == 1 {
                if tk == "initWithCoordinate" {
                    //
                }
                methodParam.name = tk
                step = 0
            } else if step == 3 {
                methodParam.iName = tk
                step = 1
                mtd.params.append(methodParam)
                mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
                methodParam = MethodParam()
            } else if tk != Sb.minus && tk != Sb.add {
                methodParam.name = tk
            }
            
        }//遍历
        
        return mtd
    }
}
