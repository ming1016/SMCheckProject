# 使用Swift3开发了个MacOS的程序可以检测出objc项目中无用方法，然后一键全部清理

当项目越来越大，引入第三方库越来越多，上架的APP体积也会越来越大，对于用户来说体验必定是不好的。在清理资源，编译选项优化，清理无用类等完成后，能够做而且效果会比较明显的就只有清理无用函数了。现有一种方案是根据Linkmap文件取到objc的所有类方法和实例方法。再用工具逆向可执行文件里引用到的方法名，求个差集列出无用方法。这个方案有些比较麻烦的地方，因为检索出的无用方法没法确定能够直接删除，还需要挨个检索人工判断是否可以删除，这样每次要清理时都需要这样人工排查一遍是非常耗时耗力的。

这样就只有模拟编译过程对代码进行深入分析才能够找出确定能够删除的方法。具体效果可以先试试看，程序代码在：<https://github.com/ming1016/SMCheckProject> 选择工程目录后程序就开始检索无用方法然后将其注释掉。

首先遍历目录下所有的文件。
```swift
let fileFolderPath = self.selectFolder()
let fileFolderStringPath = fileFolderPath.replacingOccurrences(of: "file://", with: "")
let fileManager = FileManager.default;
//深度遍历
let enumeratorAtPath = fileManager.enumerator(atPath: fileFolderStringPath)
//过滤文件后缀
let filterPath = NSArray(array: (enumeratorAtPath?.allObjects)!).pathsMatchingExtensions(["h","m"])
```

然后将注释排除在分析之外，这样做能够有效避免无用的解析。这里可以这样处理。
```swift
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
```

这里/*...*/这种注释是允许换行的，所以使用.*的方式会有问题，因为.是指非空和换行的字符。那么就需要用到[\s\S]这样的方法来包含所有字符，\s是匹配任意的空白符，\S是匹配任意不是空白符的字符，这样的或组合就能够包含全部字符。

接下来就要开始根据标记符号来进行切割分组了，使用Scanner，具体方式如下
```swift
//根据代码文件解析出一个根据标记符切分的数组
class func createOCTokens(conent:String) -> [String] {
    var str = conent

    str = self.dislodgeAnnotaion(content: str)

    //开始扫描切割
    let scanner = Scanner(string: str)
    var tokens = [String]()
    //Todo:待处理符号,.
    let operaters = [Sb.add,Sb.minus,Sb.rBktL,Sb.rBktR,Sb.asterisk,Sb.colon,Sb.semicolon,Sb.divide,Sb.agBktL,Sb.agBktR,Sb.quotM,Sb.pSign,Sb.braceL,Sb.braceR,Sb.bktL,Sb.bktR,Sb.qM]
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
        result = nil;
        if scanner.scanUpToCharacters(from: set, into: &result) {
            tokens.append(result as! String)
        }
    }
    tokens = tokens.filter {
        $0 != Sb.space
    }
    return tokens;
}
```

由于objc语法中有行分割解析的，所以还要写个行解析的方法
```swift
//根据代码文件解析出一个根据行切分的数组
class func createOCLines(content:String) -> [String] {
    var str = content
    str = self.dislodgeAnnotaion(content: str)
    let strArr = str.components(separatedBy: CharacterSet.newlines)
    return strArr
}
```

获得这些数据后就可以开始检索定义的方法了。我写了一个类专门用来获得所有定义的方法
```swift
class ParsingMethod: NSObject {
    class func parsingWithArray(arr:Array<String>) -> Method {
        var mtd = Method()
        var returnTypeTf = false //是否取得返回类型
        var parsingTf = false //解析中
        var bracketCount = 0 //括弧计数
        var step = 0 //1获取参数名，2获取参数类型，3获取iName
        var types = [String]()
        var methodParam = MethodParam()
        //print("\(arr)")
        for var tk in arr {
            tk = tk.replacingOccurrences(of: Sb.newLine, with: "")
            if (tk == Sb.semicolon || tk == Sb.braceL) && step != 1 {
                mtd.params.append(methodParam)
                mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
            } else if tk == Sb.rBktL {
                bracketCount += 1
                parsingTf = true
            } else if tk == Sb.rBktR {
                bracketCount -= 1
                if bracketCount == 0 {
                    var typeString = ""
                    for typeTk in types {
                        typeString = typeString.appending(typeTk)
                    }
                    if !returnTypeTf {
                        //完成获取返回
                        mtd.returnType = typeString
                        step = 1
                        returnTypeTf = true
                    } else {
                        if step == 2 {
                            methodParam.type = typeString
                            step = 3
                        }

                    }
                    //括弧结束后的重置工作
                    parsingTf = false
                    types = []
                }
            } else if parsingTf {
                types.append(tk)
                //todo:返回block类型会使用.设置值的方式，目前获取用过方法方式没有.这种的解析，暂时作为
                if tk == Sb.upArrow {
                    mtd.returnTypeBlockTf = true
                }
            } else if tk == Sb.colon {
                step = 2
            } else if step == 1 {
                methodParam.name = tk
                step = 0
            } else if step == 3 {
                methodParam.iName = tk
                step = 1
                mtd.params.append(methodParam)
                mtd.pnameId = mtd.pnameId.appending("\(methodParam.name):")
                methodParam = MethodParam()
            } else if tk != Sb.minus && tk != Sb.add {
                methodParam.name = tk
            }

        }//遍历

        return mtd
    }
}
```

这个方法大概的思路就是根据标记符设置不同的状态，然后将获取的信息放入定义的结构中，这个结构我是按照文件作为主体的，文件中定义那些定义方法的列表，然后定义一个方法的结构体，这个结构体里定义一些方法的信息。具体结构如下
```swift
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
```

有了文件里定义的方法，接下来就是需要找出所有使用过的方法，这样才能够通过差集得到没有用过的方法。获取使用过的方法，我使用了一种时间复杂度较优的方法，关键在于对方法中使用方法的情况做了计数的处理，这样能够最大的减少遍历，达到一次遍历获取所有方法。具体实现如下
```swift
class ParsingMethodContent: NSObject {
    class func parsing(contentArr:Array<String>, inMethod:Method) -> Method {
        var mtdIn = inMethod
        //处理用过的方法
        //todo:还要过滤@""这种情况
        var psBrcStep = 0
        var uMtdDic = [Int:Method]()
        var preTk = ""
        //处理?:这种条件判断简写方式
        var psCdtTf = false
        var psCdtStep = 0

        for var tk in contentArr {
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
```

比对后获得无用方法后就要开始注释掉他们了。这里用的是逐行分析，使用解析定义方法的方式通过方法结构体里定义的唯一标识符来比对是否到了无用的方法那，然后开始添加注释将其注释掉。实现的方法具体如下：
```swift
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

                let methodPnameId = ParsingMethod.parsingWithArray(arr: hMtds).pnameId
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
        try! hContentCleaned.write(to: URL(string:aMethod.filePath)!, atomically: false, encoding: String.Encoding.utf8)

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
                let methodPnameId = ParsingMethod.parsingWithArray(arr: mMtds).pnameId
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
            try! mContentCleaned.write(to: URL(string:mFilePath)!, atomically: false, encoding: String.Encoding.utf8)
        }

    }
}
```

完整代码在：<https://github.com/ming1016/SMCheckProject> 这里。基于语法层面的分析是比较有想象的，后面完善这个解析，比如说分析各个文件import的头文件递归来判断哪些类没有使用，通过获取的方法结合获取类里面定义的局部变量和全局变量来分析循环引用，通过获取的类的完整结构还能够将其转成JavaScriptCore能解析的js语法文件。
