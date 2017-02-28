//
//  ParsingImport.swift
//  SMCheckProject
//
//  Created by daiming on 2017/2/22.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa

class ParsingImport: NSObject {
    class func parsing(tokens:Array<String>) -> Import {
        var aImport = Import()
        //处理#import "file.h"
        var inQuot = false
        var fileName = ""
        
        //处理#import <lib/file.h>
        var inBkt = false
        var getLibNameTf = false
        var libName = ""
        
        for tk in tokens {
            //引号
            if tk == Sb.quotM && !inQuot {
                inQuot = true
            } else if tk == Sb.quotM && inQuot {
                inQuot = false
                aImport.fileName = fileName
            } else if inQuot {
                fileName += tk
            }
            //中括号
            if tk == Sb.agBktL && !inBkt {
                inBkt = true
            } else if tk == Sb.divide && inBkt && !getLibNameTf {
                aImport.libName = libName
                getLibNameTf = true
            } else if tk == Sb.agBktR && getLibNameTf {
                aImport.fileName = fileName
                //clean
                inBkt = false
                getLibNameTf = false
                fileName = ""
                libName = ""
            } else if inBkt && getLibNameTf {
                fileName += tk
            } else if inBkt && !getLibNameTf {
                libName += tk
            }
            
        }
        
        return aImport
    }
}
