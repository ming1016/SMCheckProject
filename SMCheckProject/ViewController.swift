//
//  ViewController.swift
//  SMCheckProject
//
//  Created by didi on 2016/10/13.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let fileFolderPath = self.selectFolder()
        let fileFolderPath = "file:///Users/didi/Documents/Demo/HomePageTest/test/"
        let fileFolderStringPath = fileFolderPath.replacingOccurrences(of: "file://", with: "")
        
        let fileManager = FileManager.default;
        //深度遍历
        let enumeratorAtPath = fileManager.enumerator(atPath: fileFolderStringPath)
        //过滤文件后缀
        let filterPath = NSArray(array: (enumeratorAtPath?.allObjects)!).pathsMatchingExtensions(["h","m"])
        //            print("过滤后缀后的文件: \(filterPath)")
        
        var files = [File]()
        
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
                
//                print("文件内容: \(content)")
                
                let tokens = self.createOCTokens(conent: content)
                //                        print(tokens)
                var mtdArr = [String]() //方法字符串
                
                var psMtdTf = false
                var psMtdStep = 0
                
                for tk in tokens {
                    //h文件 m文件
                    if aFile.type == FileType.fileH || aFile.type == FileType.fileM {
                        //方法解析
                        //如果-和(没有连接起来直接判断不是方法
                        if psMtdStep == 1 && tk != "(" {
                            psMtdStep = 0
                            psMtdTf = false
                            mtdArr = []
                        }
                        
                        if (tk == "-" || tk == "+") && psMtdStep == 0 {
                            psMtdTf = true
                            psMtdStep = 1;
                            mtdArr.append(tk)
                        } else if tk == "(" && psMtdStep == 1 && psMtdTf {
                            psMtdStep = 2;
                            mtdArr.append(tk)
                        } else if (tk == ";" || tk == "{") && psMtdStep == 2 && psMtdTf {
                            mtdArr.append(tk)
                            aFile.methods.append(ParsingMethod().parsingWithArray(arr: mtdArr))
                            psMtdTf = false
                            psMtdStep = 0;
                            mtdArr = []
                        } else if psMtdTf {
                            mtdArr.append(tk)
                        }
                    }
                    
                } //遍历tokens
                files.append(aFile)
                aFile.des()
            } //判断地址是否为空
            
        } //结束遍历
//        print(files)
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
        
        let operaters = ["+","-","(",")","*",":",";","/"," ","<",">","@","\"","#","{","}"]
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

