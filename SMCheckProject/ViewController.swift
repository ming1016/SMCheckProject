//
//  ViewController.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/13.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fileFolderPath = self.selectFolder()
//        let fileFolderPath = "file:///Users/didi/Documents/Demo/HomePageTest/test/"
        //let fileFolderPath = "file:///Users/ming/Documents/Bitbucket/SMPageTabView/"
        let fileFolderStringPath = fileFolderPath.replacingOccurrences(of: "file://", with: "")
        
        let fileManager = FileManager.default;
        //深度遍历
        let enumeratorAtPath = fileManager.enumerator(atPath: fileFolderStringPath)
        //过滤文件后缀
        let filterPath = NSArray(array: (enumeratorAtPath?.allObjects)!).pathsMatchingExtensions(["h","m"])
        //            print("过滤后缀后的文件: \(filterPath)")
        
        var files = [File]()
        
        var methodsDefinedInHFile = [Method]() //h文件定义的方法集合
        var methodsDefinedInMFile = [Method]() //m文件定义的方法集合
        var methodsUsed = [String]()    //用过的方法集合
        
        //遍历文件夹下所有文件
        for filePathString in filterPath {
            
            var fullPath = fileFolderPath
            
            fullPath.append(filePathString)
            
            
            //读取文件内容
            let fileUrl = URL(string: fullPath)
            
            if fileUrl == nil {
                
            } else {
                let aFile = File()
                
                aFile.path = fullPath
                
                let content =  try! String(contentsOf: fileUrl!, encoding: String.Encoding.utf8)
                
                //print("文件内容: \(content)")
                
                let tokens = self.createOCTokens(conent: content)
                //print(tokens)
                //方法解析
                var mtdArr = [String]() //方法字符串
                var psMtdTf = false //是否在解析方法
                var psMtdStep = 0
                //方法内部解析
                var mtdContentArr = [String]()
                var psMtdContentClass = Method() //正在解析的那个方法
                var psMtdContentTf = false  //是否正在解析那个方法中实现部分内容
                var psMtdContentBraceCount = 0 //大括号计数
                
                for tk in tokens {
                    //h文件 m文件
                    if aFile.type == FileType.fileH || aFile.type == FileType.fileM {
                        
                        //解析方法内容
                        if psMtdContentTf {
                            if tk == "{" {
                                mtdContentArr.append(tk)
                                psMtdContentBraceCount += 1
                            } else if tk == "}" {
                                mtdContentArr.append(tk)
                                psMtdContentBraceCount -= 1
                                if psMtdContentBraceCount == 0 {
                                    var reMethod = ParsingMethodContent().parsing(contentArr: mtdContentArr, inMethod: psMtdContentClass)
                                    aFile.methods.append(reMethod)
                                    reMethod.filePath = aFile.path //将m文件路径赋给方法
                                    methodsDefinedInMFile.append(reMethod)
                                    if reMethod.usedMethod.count > 0 {
                                        for aUsedMethod in reMethod.usedMethod {
                                            //将用过的方法添加到集合中
                                            //todo:现在去重，或者最后去重，以优化空间和速度
                                            methodsUsed.append(aUsedMethod.pnameId)
                                        }
                                    }
                                    //结束
                                    mtdContentArr = []
                                    psMtdTf = false
                                    psMtdContentTf = false
                                }
                            } else {
                                //解析方法内容中
                                //先解析使用的方法
                                mtdContentArr.append(tk)
                            }
                            continue
                        } //方法内容处理
                        
                        //方法解析
                        //如果-和(没有连接起来直接判断不是方法
                        if psMtdStep == 1 && tk != "(" {
                            psMtdStep = 0
                            psMtdTf = false
                            mtdArr = []
                        }
                        
                        if (tk == "-" || tk == "+") && psMtdStep == 0 && !psMtdTf {
                            psMtdTf = true
                            psMtdStep = 1;
                            mtdArr.append(tk)
                        } else if tk == "(" && psMtdStep == 1 && psMtdTf {
                            psMtdStep = 2;
                            mtdArr.append(tk)
                        } else if (tk == ";" || tk == "{") && psMtdStep == 2 && psMtdTf {
                            mtdArr.append(tk)
                            var parsedMethod = ParsingMethod().parsingWithArray(arr: mtdArr)
                            //开始处理方法内部
                            if tk == "{" {
                                psMtdContentClass = parsedMethod
                                psMtdContentTf = true
                                psMtdContentBraceCount += 1
                                mtdContentArr.append(tk)
                            } else {
                                aFile.methods.append(parsedMethod)
                                parsedMethod.filePath = aFile.path //将h文件的路径赋给方法
                                methodsDefinedInHFile.append(parsedMethod)
                                psMtdTf = false
                            }
                            //重置
                            psMtdStep = 0;
                            mtdArr = []
                            
                        } else if psMtdTf {
                            mtdArr.append(tk)
                        }
                    } //m和h文件
                    
                } //遍历tokens
                files.append(aFile)
                //aFile.des()
                
                
            } //判断地址是否为空
            
        } //结束所有文件遍历
//        print(files)
        //打印定义方法和使用过的方法
        
        /*
        print("H方法：\(methodsDefinedInHFile.count)个")
        print("M方法：\(methodsDefinedInMFile.count)个")
        print("用过方法：\(methodsUsed.count)个")
        print("\nH方法")
        for aMethod in methodsDefinedInHFile {
            print("\(File.desDefineMethodParams(paramArr: aMethod.params))")
        }
        print("\nM方法")
        for aMethod in methodsDefinedInMFile {
            print("\(File.desDefineMethodParams(paramArr: aMethod.params))")
        }
         
        print("\n用过的方法")
        for aMethod in methodsUsed {
            print("\(aMethod)")
        }
         */
        
        
        //return
        //todo:去重
        let methodsUsedSet = Set(methodsUsed)
        methodsUsed = Array(methodsUsedSet)
        //找出h文件中没有用过的方法
        var unUsedMethods = [Method]()
        for aHMethod in methodsDefinedInHFile {
            var hasHMethodUsed = false
            for aUMethodPNameId in methodsUsed {
                if aHMethod.pnameId == aUMethodPNameId {
                    hasHMethodUsed = true
                    break
                }
            }
            if !hasHMethodUsed {
                unUsedMethods.append(aHMethod)
            }
        }
        print("无用方法")
        for aMethod in unUsedMethods {
            print("\(File.desDefineMethodParams(paramArr: aMethod.params))")
        }
        //开始删除
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    //根据代码文件解析出一个根据标记符切分的数组
    func createOCTokens(conent:String) -> [String] {
        //todo: 使用正则取出
        var str = conent
        
        str = self.dislodgeAnnotaion(content: str)
        
        //开始扫描切割
        let scanner = Scanner(string: str)
        var tokens = [String]()
        
        let operaters = ["+","-","(",")","*",":",";","/"," ","<",">","@","\"","#","{","}","[","]"]
        var operatersString = ""
        for op in operaters {
            operatersString = operatersString.appending(op)
        }
        
        var set = CharacterSet()
        set.insert(charactersIn: operatersString)
        
        while !scanner.isAtEnd {
            for operater in operaters {
                if (scanner.scanString(operater, into: nil)) {
                    tokens.append(operater)
                }
            }
            
            var result:NSString?
            result = nil;
            if scanner.scanUpToCharacters(from: set, into: &result) {
                tokens.append(result as! String)
            }
        }
        tokens = tokens.filter {
            $0 != " "
        }
        return tokens;
    }
    //清理注释
    func dislodgeAnnotaion(content:String) -> String {
        
        let annotationBlockPattern = "/\\*[\\s\\S]*?\\*/" //匹配/*...*/这样的注释
        let annotationLinePattern = "//.*?\\n" //匹配//这样的注释
        
        let regexBlock = try! NSRegularExpression(pattern: annotationBlockPattern, options: NSRegularExpression.Options(rawValue:0))
        let regexLine = try! NSRegularExpression(pattern: annotationLinePattern, options: NSRegularExpression.Options(rawValue:0))
        var newStr = ""
        newStr = regexLine.stringByReplacingMatches(in: content, options: NSRegularExpression.MatchingOptions(rawValue:0), range: NSMakeRange(0, content.characters.count), withTemplate: " ")
        newStr = regexBlock.stringByReplacingMatches(in: newStr, options: NSRegularExpression.MatchingOptions(rawValue:0), range: NSMakeRange(0, newStr.characters.count), withTemplate: " ")
        return newStr
    }
    
    //选择一个文件夹
    func selectFolder() -> String {
        let openPanel = NSOpenPanel();
        openPanel.canChooseDirectories = true;
        openPanel.canChooseFiles = false;
        if(openPanel.runModal() == NSModalResponseOK) {
            print(openPanel.url?.absoluteString)
            let path = openPanel.url?.absoluteString
            print("选择文件夹路径: \(path)")
            return path!
        }
        
        return ""
    }

}

