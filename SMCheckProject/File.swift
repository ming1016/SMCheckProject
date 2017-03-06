//
//  File.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/20.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa
enum FileType {
    case FileH,FileM,FileSwift
}
//文件
class File: NSObject {
    public var path = "" {
        didSet {
            if path.hasSuffix(".h") {
                type = FileType.FileH
            } else if path.hasSuffix(".m") {
                type = FileType.FileM
            } else if path.hasSuffix(".swift") {
                type = FileType.FileSwift
            }
            name = (path.components(separatedBy: "/").last)!
        }
    }
    public var type = FileType.FileH
    public var name = ""
    public var content = ""
    public var methods = [Method]() //所有方法
    public var imports = [Import]() //一级引入
    public var recursionImports = [Import]()     //递归所有层级引入
    public var importObjects = [String:Object]() //所有引入的对象
    public var usedObjects = [String:Object]()   //已经使用过的对象，无用的引入可以通过对比self.imports里的文件里的定义的objects求差集得到
    public var objects = [String:Object]()       //文件里定义的所有类
    public var macros = [String:Macro]()         //文件里定义的宏，全局的也会有一份
    public var protocols = [String:Protocol]()   //Todo:还没用，作为性能提升用
    
    
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
        //Todo: 添加更多详细的文件里的信息。比如说object里的和新加的marcos等。
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
//#import "file.h"
struct Import {
    public var fileName = ""
    public var libName = ""
    public var file = File()  //这样记录所有递归出的引用类时就能够直接获取File里的详细信息了
}

//#define REDCOLOR [UIColor HexString:@"000000"]
struct Macro {
    public var name = ""
    public var tokens = [String]()
}

//@protocol DCOrderListViewDelegate <NSObject>
struct Protocol {
    public var name = ""
    public var methods = [Method]()
}

//对象
class Object {
    public var name = ""
    public var superName = ""
    public var category = ""
    public var usingProtocols = [String]()     //协议
    public var properties = [Property]()       //对象里定义的属性
    public var methods = [Method]()            //定义的方法
    public var protocols = [String:Protocol]() //Todo:还没用，根据属性和来看看那些属性地方会用什么protocol
}

struct Property {
    public var name = ""
    public var type = ""
    public var sets = [String]() //nonatomic strong
}

struct Method {
    public var classMethodTf = false //+ or -
    public var returnType = ""
    public var returnTypePointTf = false
    public var returnTypeBlockTf = false
    public var params = [MethodParam]()
    public var tokens = [String]()     //方法内容token
    public var usedMethod = [Method]()
    public var tmpObjects = [Object]() //临时变量集
    public var filePath = ""           //定义方法的文件路径，方便修改文件使用
    public var pnameId = ""            //唯一标识，便于快速比较
    
}

class MethodParam: NSObject {
    public var name = ""
    public var type = ""
    public var typePointTf = false //是否是指针类型
    public var iName = ""
}

class Type: NSObject {
    //todo:更多类型
    public var name = ""
    public var type = 0 //0是值类型 1是指针
}



