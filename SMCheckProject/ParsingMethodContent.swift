//
//  ParsingMethodContent.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/23.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ParsingMethodContent: NSObject {
    class func parsing(contentArr:Array<String>, inMethod:Method) -> Method {
        var mtdIn = inMethod
        var mtd = Method()
        //处理用过的方法
        //todo:还要过滤@""这种情况
        var psUMTf = false
        var psUMBracketCount = 0
        var psUMPreTk = ""
        var psUMColonTf = false
        
        for var tk in contentArr {
            if tk == "[" || tk == "]"{
                
                if tk == "[" {
                    psUMTf = true
                    psUMBracketCount += 1
                }
                if tk == "]" {
                    psUMBracketCount -= 1
                    
                    //无入参的简单方法
                    if !psUMColonTf {
                        let prm = MethodParam()
                        prm.name = psUMPreTk
                        if prm.name != "" {
                            mtd.params.append(prm)
                            mtd.pnameId = mtd.pnameId.appending("\(prm.name):")
                        }
                    }
                    
                    if psUMBracketCount == 0 {
                        psUMTf = false
                    }
                    
                }
                
                if mtd.params.count > 0 {
                    mtdIn.usedMethod.append(mtd)
                    //结束一个已用方法，开始重置
                    mtd = Method()
                    psUMTf = false
                }
                psUMColonTf = false
            } else if tk == ":" && psUMTf {
                let prm = MethodParam()
                prm.name = psUMPreTk
                if prm.name != "" {
                    mtd.params.append(prm)
                    mtd.pnameId = mtd.pnameId.appending("\(prm.name):")
                }
                
                //重置前一个tk
                psUMPreTk = ""
                psUMColonTf = true
            } else if psUMTf {
                tk = tk.replacingOccurrences(of: "\n", with: "")
                psUMPreTk = tk
            }
        }
        return mtdIn
    }
}
