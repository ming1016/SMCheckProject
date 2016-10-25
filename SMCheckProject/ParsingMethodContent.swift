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
        //处理用过的方法
        //todo:还要过滤@""这种情况
        var psBrcStep = 0
        var uMtdDic = [Int:Method]()
        var preTk = ""
        //处理?:这种条件判断简写方式
        var psCdtTf = false
        var psCdtStep = 0
        
        for var tk in contentArr {
            if tk == "[" {
                if psCdtTf {
                    psCdtStep += 1
                }
                psBrcStep += 1
                uMtdDic[psBrcStep] = Method()
            } else if tk == "]" {
                if psCdtTf {
                    psCdtStep -= 1
                }
                if (uMtdDic[psBrcStep]?.params.count)! > 0 {
                    mtdIn.usedMethod.append(uMtdDic[psBrcStep]!)
                }
                psBrcStep -= 1
                
            } else if tk == ":" {
                //条件简写情况处理
                if psCdtTf && psCdtStep == 0 {
                    psCdtTf = false
                    continue
                }
                //dictionary情况处理@"key":@"value"
                if preTk == "\"" {
                    continue
                }
                let prm = MethodParam()
                prm.name = preTk
                if prm.name != "" {
                    uMtdDic[psBrcStep]?.params.append(prm)
                    uMtdDic[psBrcStep]?.pnameId = (uMtdDic[psBrcStep]?.pnameId.appending("\(prm.name):"))!
                }
            } else if tk == "?" {
                psCdtTf = true
            } else {
                tk = tk.replacingOccurrences(of: "\n", with: "")
                preTk = tk
            }
        }
        
        return mtdIn
    }
}
