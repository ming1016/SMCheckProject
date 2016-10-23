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
    
    func des() {
        print("文件路径：\(path)\n")
        print("文件名：\(name)\n")
        print("方法数量：\(methods.count)\n")
        print("方法列表：")
        for aMethod in methods {
            var showStr = "- (\(aMethod.returnType)) "
            showStr = showStr.appending(File.desDefineMethodParams(paramArr: aMethod.params))
            print("\n\(showStr)")
            if aMethod.usedMethod.count > 0 {
                print("用过的方法----------")
                showStr = ""
                for aUsedMethod in aMethod.usedMethod {
                    showStr = ""
                    showStr = showStr.appending(File.desUsedMethodParams(paramArr: aUsedMethod.params))
                    print("\(showStr)")
                }
                print("------------------")
            }
            
        }
        print("\n")
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
    public var params = [MethodParam]()
    public var usedMethod = [Method]()
    public var filePath = "" //定义方法的文件路径，方便修改文件使用
    public var pnameId = ""
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



