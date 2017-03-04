//
//  CleanUnusedImports.swift
//  SMCheckProject
//
//  Created by daiming on 2017/3/1.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa
import RxSwift

//获取递归后所有的import
class CleanUnusedImports: NSObject {
    func find(files:Dictionary<String, File>) -> Observable<Any> {
        
        return Observable.create({ (observer) -> Disposable in
            
            var allFiles = [String:File]() //需要查找的头文件
            var newFiles = [String:File]() //递归全的文件
            
            var allObjects = [String:Object]()
            var allUsedObjects = [String:Object]()
            
            for (_, aFile) in files {
                allFiles[aFile.name] = aFile
            }
            for (_, aFile) in allFiles {
                //单文件处理
                aFile.recursionImports = self.fetchImports(file: aFile, allFiles: allFiles, allRecursionImports:[Import]())
                for aImport in aFile.recursionImports {
                    for (name, aObj) in aImport.file.objects {
                        aFile.importObjects[name] = aObj
                        allObjects[name] = aObj
                    }
                }
                newFiles[aFile.name] = aFile
                //处理无用的import
                for aMethod in aFile.methods {
                    let _ = ParsingMethodContent.parsing(method: aMethod, file: aFile).subscribe(onNext:{ (result) in
                        if result is Object {
                            let aObj = result as! Object
                            allUsedObjects[aObj.name] = aObj
                        }
                    })
                }
            }
            print("\(allObjects.keys)")
            print("-----------------------")
            print("\(allUsedObjects.keys)")
            //遍历对比出无用的类
//            for (key, value) in allObjects {
//                guard let _ = allUsedObjects[key] else {
//                    
//                }
//            }
            observer.on(.next(newFiles))
            observer.on(.completed)
            return Disposables.create {
                //
            }
        })
    }
    
    //递归获取所有import
    func fetchImports(file: File, allFiles:[String:File], allRecursionImports:[Import]) -> [Import] {
        var allRecursionImports = allRecursionImports
        for aImport in file.imports {
            if !checkIfContain(aImport: aImport, inImports: allRecursionImports) {
                allRecursionImports.append(addFileObjectTo(aImport: aImport, allFiles: allFiles))
            }
            
            guard let importFile = allFiles[aImport.fileName] else {
                continue
            }
            
            let reRecursionImports = fetchImports(file: importFile, allFiles: allFiles, allRecursionImports: allRecursionImports)
            for aImport in reRecursionImports {
                if !checkIfContain(aImport: aImport, inImports: allRecursionImports) {
                    allRecursionImports.append(addFileObjectTo(aImport: aImport, allFiles: allFiles))
                }
            }
            
        }
        return allRecursionImports
    }
    
    func addFileObjectTo(aImport:Import, allFiles: [String:File]) -> Import {
        var mImport = aImport
        guard let aFile =  allFiles[aImport.fileName] else {
            return aImport
        }
        mImport.file = aFile
        return mImport
    }
    
    func checkIfContain(aImport:Import, inImports:[Import]) -> Bool{
        let tf = inImports.contains { element in
            if aImport.fileName == element.fileName {
                return true
            } else {
                return false
            }
        }
        return tf
    }
}
