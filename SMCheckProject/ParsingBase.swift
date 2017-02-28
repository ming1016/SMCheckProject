//
//  ParsingBase.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/20.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ParsingBase: NSObject {
    //删除指定的一组方法
    class func delete(methods:[Method]) {
        print("无用方法")
        for aMethod in methods {
            print("\(File.desDefineMethodParams(paramArr: aMethod.params))")
            
            //开始删除
            //continue
            var hContent = ""
            var mContent = ""
            var mFilePath = aMethod.filePath
            if aMethod.filePath.hasSuffix(".h") {
                hContent = try! String(contentsOf: URL(string:aMethod.filePath)!, encoding: String.Encoding.utf8)
                //todo:因为先处理了h文件的情况
                mFilePath = aMethod.filePath.trimmingCharacters(in: CharacterSet(charactersIn: "h")) //去除头尾字符集
                mFilePath = mFilePath.appending("m")
            }
            if mFilePath.hasSuffix(".m") {
                do {
                    mContent = try String(contentsOf: URL(string:mFilePath)!, encoding: String.Encoding.utf8)
                } catch {
                    mContent = ""
                }
                
            }
            
            let hContentArr = hContent.components(separatedBy: CharacterSet.newlines)
            let mContentArr = mContent.components(separatedBy: CharacterSet.newlines)
            //print(mContentArr)
            //----------------h文件------------------
            var psHMtdTf = false
            var hMtds = [String]()
            var hMtdStr = ""
            var hMtdAnnoStr = ""
            var hContentCleaned = ""
            for hOneLine in hContentArr {
                var line = hOneLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                if line.hasPrefix(Sb.minus) || line.hasPrefix(Sb.add) {
                    psHMtdTf = true
                    hMtds += self.createOCTokens(conent: line)
                    hMtdStr = hMtdStr.appending(hOneLine + Sb.newLine)
                    hMtdAnnoStr += "//-----由SMCheckProject工具删除-----\n//"
                    hMtdAnnoStr += hOneLine + Sb.newLine
                    line = self.dislodgeAnnotaionInOneLine(content: line)
                    line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else if psHMtdTf {
                    hMtds += self.createOCTokens(conent: line)
                    hMtdStr = hMtdStr.appending(hOneLine + Sb.newLine)
                    hMtdAnnoStr += "//" + hOneLine + Sb.newLine
                    line = self.dislodgeAnnotaionInOneLine(content: line)
                    line = line.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                } else {
                    hContentCleaned += hOneLine + Sb.newLine
                }
                
                if line.hasSuffix(Sb.semicolon) && psHMtdTf{
                    psHMtdTf = false
                    
                    let methodPnameId = ParsingMethod.parsing(tokens: hMtds).pnameId
                    if aMethod.pnameId == methodPnameId {
                        hContentCleaned += hMtdAnnoStr
                        
                    } else {
                        hContentCleaned += hMtdStr
                    }
                    hMtdAnnoStr = ""
                    hMtdStr = ""
                    hMtds = []
                }
                
                
            }
            //删除无用函数
            do {
                try hContentCleaned.write(to: URL(string:aMethod.filePath)!, atomically: false, encoding: String.Encoding.utf8)
            } catch  {
                //
            }
            
            
            //----------------m文件----------------
            var mDeletingTf = false
            var mBraceCount = 0
            var mContentCleaned = ""
            var mMtdStr = ""
            var mMtdAnnoStr = ""
            var mMtds = [String]()
            var psMMtdTf = false
            for mOneLine in mContentArr {
                let line = mOneLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                
                if mDeletingTf {
                    let lTokens = self.createOCTokens(conent: line)
                    mMtdAnnoStr += "//" + mOneLine + Sb.newLine
                    for tk in lTokens {
                        if tk == Sb.braceL {
                            mBraceCount += 1
                        }
                        if tk == Sb.braceR {
                            mBraceCount -= 1
                            if mBraceCount == 0 {
                                mContentCleaned = mContentCleaned.appending(mMtdAnnoStr)
                                mMtdAnnoStr = ""
                                mDeletingTf = false
                            }
                        }
                    }
                    
                    continue
                }
                
                
                if line.hasPrefix(Sb.minus) || line.hasPrefix(Sb.add) {
                    psMMtdTf = true
                    mMtds += self.createOCTokens(conent: line)
                    mMtdStr = mMtdStr.appending(mOneLine + Sb.newLine)
                    mMtdAnnoStr += "//-----由SMCheckProject工具删除-----\n//" + mOneLine + Sb.newLine
                } else if psMMtdTf {
                    mMtdStr = mMtdStr.appending(mOneLine + Sb.newLine)
                    mMtdAnnoStr += "//" + mOneLine + Sb.newLine
                    mMtds += self.createOCTokens(conent: line)
                } else {
                    mContentCleaned = mContentCleaned.appending(mOneLine + Sb.newLine)
                }
                
                if line.hasSuffix(Sb.braceL) && psMMtdTf {
                    psMMtdTf = false
                    let methodPnameId = ParsingMethod.parsing(tokens: mMtds).pnameId
                    if aMethod.pnameId == methodPnameId {
                        mDeletingTf = true
                        mBraceCount += 1
                        mContentCleaned = mContentCleaned.appending(mMtdAnnoStr)
                    } else {
                        mContentCleaned = mContentCleaned.appending(mMtdStr)
                    }
                    mMtdStr = ""
                    mMtdAnnoStr = ""
                    mMtds = []
                }
                
            } //m文件
            
            //删除无用函数
            if mContent.characters.count > 0 {
                do {
                    try mContentCleaned.write(to: URL(string:mFilePath)!, atomically: false, encoding: String.Encoding.utf8)
                } catch {
                    //
                }
                
            }
            
        }
    }
    
    //根据代码文件解析出一个根据行切分的数组
    class func createOCLines(content:String) -> [String] {
        var str = content
        str = self.dislodgeAnnotaion(content: str)
        let strArr = str.components(separatedBy: CharacterSet.newlines)
        return strArr
    }
    
    //根据代码文件解析出一个根据标记符切分的数组
    class func createOCTokens(conent:String) -> [String] {
        var str = conent
        
        str = self.dislodgeAnnotaion(content: str)
        
        //开始扫描切割
        let scanner = Scanner(string: str)
        var tokens = [String]()
        //Todo:待处理符号,.
        let operaters = [Sb.add,Sb.minus,Sb.rBktL,Sb.rBktR,Sb.asterisk,Sb.colon,Sb.comma,Sb.semicolon,Sb.divide,Sb.agBktL,Sb.agBktR,Sb.quotM,Sb.pSign,Sb.braceL,Sb.braceR,Sb.bktL,Sb.bktR,Sb.qM]
        var operatersString = ""
        for op in operaters {
            operatersString = operatersString.appending(op)
        }
        
        var set = CharacterSet()
        set.insert(charactersIn: operatersString)
        set.formUnion(CharacterSet.whitespacesAndNewlines)
        
        while !scanner.isAtEnd {
            for operater in operaters {
                if (scanner.scanString(operater, into: nil)) {
                    tokens.append(operater)
                }
            }
            
            var result:NSString?
            result = nil
            if scanner.scanUpToCharacters(from: set, into: &result) {
                tokens.append(result as! String)
            }
        }
        tokens = tokens.filter {
            $0 != Sb.space
        }
        return tokens;
    }
    
    //清理注释
    class func dislodgeAnnotaion(content:String) -> String {
        
        let annotationBlockPattern = "/\\*[\\s\\S]*?\\*/" //匹配/*...*/这样的注释
        let annotationLinePattern = "//.*?\\n" //匹配//这样的注释
        
        let regexBlock = try! NSRegularExpression(pattern: annotationBlockPattern, options: NSRegularExpression.Options(rawValue:0))
        let regexLine = try! NSRegularExpression(pattern: annotationLinePattern, options: NSRegularExpression.Options(rawValue:0))
        var newStr = ""
        newStr = regexLine.stringByReplacingMatches(in: content, options: NSRegularExpression.MatchingOptions(rawValue:0), range: NSMakeRange(0, content.characters.count), withTemplate: Sb.space)
        newStr = regexBlock.stringByReplacingMatches(in: newStr, options: NSRegularExpression.MatchingOptions(rawValue:0), range: NSMakeRange(0, newStr.characters.count), withTemplate: Sb.space)
        return newStr
    }
    //一行内清理注释
    class func dislodgeAnnotaionInOneLine(content:String) -> String {
        let annotationLinePattern = "//[\\s\\S]*?$" //匹配//这样的注释
        
        let regexLine = try! NSRegularExpression(pattern: annotationLinePattern, options: NSRegularExpression.Options(rawValue:0))
        var newStr = ""
        newStr = regexLine.stringByReplacingMatches(in: content, options: NSRegularExpression.MatchingOptions(rawValue:0), range: NSMakeRange(0, content.characters.count), withTemplate: "")
        return newStr
    }
}
