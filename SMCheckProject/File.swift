//
//  File.swift
//  SMCheckProject
//
//  Created by didi on 2016/10/20.
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
        print("文件路径：\(path)")
        print("文件名：\(name)")
        print("方法数量：\(methods.count)")
        print("方法列表：")
        for aMethod in methods {
            var showStr = "- (\(aMethod.returnType)) "
            for aParam in aMethod.params {
                if aParam.type == "" {
                    showStr = showStr.appending("\(aParam.name);")
                } else {
                    showStr = showStr.appending("\(aParam.name):(\(aParam.type))\(aParam.iName);")
                }
                
            }
            print("\(showStr)")
        }
        print("\n")
    }
}

class Method: NSObject {
    public var classMethodTf = false
    public var name = ""
    public var returnType = ""
    public var returnTypePointTf = false
    public var params = [MethodParam]()
}

class MethodParam: NSObject {
    public var name = ""
    public var type = ""
    public var typePointTf = false
    public var iName = ""
}



