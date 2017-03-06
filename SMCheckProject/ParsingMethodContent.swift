//
//  ParsingMethodContent.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/23.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa
import RxSwift

class ParsingMethodContent: NSObject {
    class func parsing(method:Method, file:File) -> Observable<Any> {
        return Observable.create({ (observer) -> Disposable in
            for tk in method.tokens {
                guard let obj = file.importObjects[tk] else {
                    continue
                }
                guard let _ = file.usedObjects[tk] else {
                    //记录使用过的类
                    file.usedObjects[tk] = obj
                    observer.on(.next(obj))
                    
                    continue
                }   
            }
            
            observer.on(.completed)
            return Disposables.create {
                
            }
        })
        
    }
    
    //-----------处理用过的方法------------
    class func parsing(contentArr:Array<String>, inMethod:Method) -> Method {
        var mtdIn = inMethod
        mtdIn.tokens = contentArr
        
        //todo:还要过滤@""这种情况
        var psBrcStep = 0
        var uMtdDic = [Int:Method]()
        var preTk = ""
        //处理?:这种条件判断简写方式
        var psCdtTf = false
        var psCdtStep = 0
        //判断selector
        var psSelectorTf = false
        var preSelectorTk = ""
        var selectorMtd = Method()
        var selectorMtdPar = MethodParam()
        
        uMtdDic[psBrcStep] = Method() //初始时就实例化一个method，避免在define里定义只定义]符号
        
        for var tk in contentArr {
            //selector处理
            if psSelectorTf {
                if tk == Sb.colon {
                    selectorMtdPar.name = preSelectorTk
                    selectorMtd.params.append(selectorMtdPar)
                    selectorMtd.pnameId += "\(selectorMtdPar.name):"
                } else if tk == Sb.rBktR {
                    mtdIn.usedMethod.append(selectorMtd)
                    psSelectorTf = false
                    selectorMtd = Method()
                    selectorMtdPar = MethodParam()
                } else {
                    preSelectorTk = tk
                }
                continue
            }
            if tk == Sb.atSelector {
                psSelectorTf = true
                selectorMtd = Method()
                selectorMtdPar = MethodParam()
                continue
            }
            //通常处理
            if tk == Sb.bktL {
                if psCdtTf {
                    psCdtStep += 1
                }
                psBrcStep += 1
                uMtdDic[psBrcStep] = Method()
            } else if tk == Sb.bktR {
                if psCdtTf {
                    psCdtStep -= 1
                }
                if (uMtdDic[psBrcStep]?.params.count)! > 0 {
                    mtdIn.usedMethod.append(uMtdDic[psBrcStep]!)
                }
                psBrcStep -= 1
                //[]不配对的容错处理
                if psBrcStep < 0 {
                    psBrcStep = 0
                }
                
            } else if tk == Sb.colon {
                //条件简写情况处理
                if psCdtTf && psCdtStep == 0 {
                    psCdtTf = false
                    continue
                }
                //dictionary情况处理@"key":@"value"
                if preTk == Sb.quotM || preTk == "respondsToSelector" {
                    continue
                }
                let prm = MethodParam()
                prm.name = preTk
                if prm.name != "" {
                    uMtdDic[psBrcStep]?.params.append(prm)
                    uMtdDic[psBrcStep]?.pnameId = (uMtdDic[psBrcStep]?.pnameId.appending("\(prm.name):"))!
                }
            } else if tk == Sb.qM {
                psCdtTf = true
            } else {
                tk = tk.replacingOccurrences(of: Sb.newLine, with: "")
                preTk = tk
            }
        }
        
        return mtdIn
    }
}
