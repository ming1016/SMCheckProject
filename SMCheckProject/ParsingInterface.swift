//
//  ParsingInterface.swift
//  SMCheckProject
//
//  Created by didi on 2017/2/23.
//  Copyright © 2017年 Starming. All rights reserved.
//

/*
 语法范例
 #@interface SMService (Car)
 #@interface SMPickView : UIView<UIPickerViewDataSource, UIPickerViewDelegate>
 #@interface SMView ()<SMListTableViewDelegate,SMComUnitDelegate,SMShowDelegate>
 */

import Cocoa

class ParsingInterface: NSObject {
    //将完整获取信息结合到object里
    class func parsing(line:String, inObject:Object) {
        let aLine = line.replacingOccurrences(of: Sb.atInteface, with: "")
        let tokens = ParsingBase.createOCTokens(conent: aLine)
        
        var endNameTf = false      //完成类名获取
        var inSuperNameTf = false  //获取:符号进入获取父类名阶段
        var inCategoryTf = false   //获取类别
        var inProtocolTf = false   //获取协议定义
        
        for tk in tokens {
            if !endNameTf && !inSuperNameTf && !inCategoryTf && !inProtocolTf {
                inObject.name = tk
                endNameTf = true
            } else if tk == Sb.colon && endNameTf && !inSuperNameTf  && !inCategoryTf && !inProtocolTf {
                inSuperNameTf = true
            } else if tk == Sb.rBktL && endNameTf && !inCategoryTf && !inProtocolTf {
                inCategoryTf = true
            } else if inSuperNameTf && !inCategoryTf && !inProtocolTf {
                inObject.superName = tk
                inSuperNameTf = false
            } else if inCategoryTf && tk != Sb.rBktR && !inProtocolTf {
                inObject.category = tk
            } else if tk == Sb.agBktL && !inProtocolTf {
                inProtocolTf = true
            } else if tk != Sb.comma && tk != Sb.agBktR && inProtocolTf {
                inObject.usingProtocols.append(tk)
            }
        }
        
    }
    //获取interface的name
    class func parsingNameFrom(line:String) -> String {
        guard let name = self.tokensFrom(line: line).first else {
            return ""
        }
        return name
    }
    
    class func tokensFrom(line:String) -> [String] {
        let aLine = line.replacingOccurrences(of: Sb.atInteface, with: "")
        return ParsingBase.createOCTokens(conent: aLine)
    }
}
