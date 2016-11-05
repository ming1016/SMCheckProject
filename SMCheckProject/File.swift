//
//  File.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/20.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa
enum FileType {
    case fileH
    case fileM
    case fileSwift
}

class File: NSObject {
    public var path = "" {
        didSet {
            if path.hasSuffix(".h") {
                type = FileType.fileH
            } else if path.hasSuffix(".m") {
                type = FileType.fileM
            } else if path.hasSuffix(".swift") {
                type = FileType.fileSwift
            }
            name = (path.components(separatedBy: "/").last?.components(separatedBy: ".").first)!
        }
    }
    public var type = FileType.fileH
    public var name = ""
    public var methods = [Method]() //所有方法
    
    func des() -> String {
        var str = ""
        str += "文件路径：\(path)\n"
        str += "文件名：\(name)\n"
        str += "方法数量：\(methods.count)\n"
        str += "方法列表：\n"
        for aMethod in methods {
            var showStr = "- (\(aMethod.returnType)) "
            showStr = showStr.appending(File.desDefineMethodParams(paramArr: aMethod.params))
            str += "\n\(showStr)\n"
            if aMethod.usedMethod.count > 0 {
                str += "用过的方法----------\n"
                showStr = ""
                for aUsedMethod in aMethod.usedMethod {
                    showStr = ""
                    showStr = showStr.appending(File.desUsedMethodParams(paramArr: aUsedMethod.params))
                    str += "\(showStr)\n"
                }
                str += "------------------\n"
            }
            
        }
        return str
    }
    
    //类方法
    //打印定义方法参数
    class func desDefineMethodParams(paramArr:[MethodParam]) -> String {
        var showStr = ""
        for aParam in paramArr {
            if aParam.type == "" {
                showStr = showStr.appending("\(aParam.name);")
            } else {
                showStr = showStr.appending("\(aParam.name):(\(aParam.type))\(aParam.iName);")
            }
            
        }
        return showStr
    }
    class func desUsedMethodParams(paramArr:[MethodParam]) -> String {
        var showStr = ""
        for aUParam in paramArr {
            showStr = showStr.appending("\(aUParam.name):")
        }
        return showStr
    }
    
}

struct Method {
    public var classMethodTf = false //+ or -
    public var returnType = ""
    public var returnTypePointTf = false
    public var returnTypeBlockTf = false
    public var params = [MethodParam]()
    public var usedMethod = [Method]()
    public var filePath = "" //定义方法的文件路径，方便修改文件使用
    public var pnameId = ""  //唯一标识，便于快速比较
}

class MethodParam: NSObject {
    public var name = ""
    public var type = ""
    public var typePointTf = false
    public var iName = ""
}

class Type: NSObject {
    //todo:更多类型
    public var name = ""
    public var type = 0 //0是值类型 1是指针
}



