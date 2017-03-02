//
//  CleanUnusedImports.swift
//  SMCheckProject
//
//  Created by didi on 2017/3/1.
//  Copyright © 2017年 Starming. All rights reserved.
//

import Cocoa
import RxSwift

class CleanUnusedImports: NSObject {
    func find(files:Dictionary<String, File>) -> Observable<Any> {
        
        return Observable.create({ (observer) -> Disposable in
            
            var allFiles = [String:File]() //需要查找的头文件
            var newFiles = [String:File]() //递归全的文件
            
            for (_, aFile) in files {
                allFiles[aFile.name] = aFile
            }
            for (_, aFile) in allFiles {
                //单文件处理
                aFile.recursionImports = self.fetchImports(file: aFile, allFiles: allFiles, allRecursionImports:[Import]())
                newFiles[aFile.name] = aFile
                
            }
            
            return Disposables.create {
                //
            }
        })
    }
    
    //递归
    func fetchImports(file: File, allFiles:[String:File], allRecursionImports:[Import]) -> [Import] {
        var allRecursionImports = allRecursionImports
        for aImport in file.imports {
            
            let tf = allRecursionImports.contains { element in
                if aImport.fileName == element.fileName {
                    return true
                } else {
                    return false
                }
            }
            if !tf {
                allRecursionImports.append(aImport)
            }
            
            guard let importFile = allFiles[aImport.fileName] else {
                continue
            }
            
            let reRecursionImports = fetchImports(file: importFile, allFiles: allFiles, allRecursionImports: allRecursionImports)
            for rImport in reRecursionImports {
                let rTf = allRecursionImports.contains { element in
                    if rImport.fileName == element.fileName {
                        return true
                    } else {
                        return false
                    }
                }
                if !rTf {
                    allRecursionImports.append(rImport)
                }
            }
            
            
        }
        return allRecursionImports
    }
}
