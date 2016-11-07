//
//  ViewController.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/13.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa
import SnapKit
import RxSwift

class ViewController: NSViewController,NSTableViewDataSource,NSTableViewDelegate,DragViewDelegate {
    
    @IBOutlet weak var parsingIndicator: NSProgressIndicator!
    @IBOutlet weak var desLb: NSTextField!
    @IBOutlet weak var pathDes: NSTextField!
    @IBOutlet weak var cleanBt: NSButton!
    @IBOutlet weak var resultTb: NSTableView!
    @IBOutlet weak var dragView: DragView!
    @IBOutlet weak var seachBt: NSButtonCell!
    @IBOutlet weak var detailTv: NSScrollView!
    @IBOutlet var detailTxv: NSTextView!
    
    var unusedMethods = [Method]() //无用方法
    var selectedPath : String = "" {
        didSet {
            if selectedPath.characters.count > 0 {
                let ud = UserDefaults()
                ud.set(selectedPath, forKey: "selectedPath")
                ud.synchronize()
                pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailTxv.string = ""
        detailTxv.textColor = NSColor.gray
        parsingIndicator.isHidden = true
        desLb.stringValue = ""
        pathDes.stringValue = "请选择工程目录"
        cleanBt.isEnabled = false
        resultTb.doubleAction = #selector(cellDoubleClick)
        if (UserDefaults().object(forKey: "selectedPath") != nil) {
            selectedPath = UserDefaults().value(forKey: "selectedPath") as! String
        }
        
    }
    
    override func awakeFromNib() {
        dragView.delegate = self
    }
    
    //查找按钮
    @IBAction func searchMethodAction(_ sender: Any) {
        if selectedPath.characters.count > 0 {
            self.searchingUnusedMethods()
        }
        
    }
    
    //清理按钮
    @IBAction func cleanMethodsAction(_ sender: AnyObject) {
        desLb.stringValue = "清理中..."
        cleanBt.isEnabled = false
        parsingIndicator.startAnimation(nil)
        DispatchQueue.global().async {
            CleanUnusedMethods().clean(methods: self.unusedMethods)
            DispatchQueue.main.async {
                self.cleanBt.isEnabled = true
                self.parsingIndicator.stopAnimation(nil)
                self.parsingIndicator.isHidden = true
                self.desLb.stringValue = "完成清理"
            }
        }
    }
    
    //Priavte
    private func searchingUnusedMethods() {
        parsingIndicator.isHidden = false
        parsingIndicator.startAnimation(nil)
        desLb.stringValue = "查找中..."
        cleanBt.isEnabled = false
        pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
        DispatchQueue.global().async {
//            self.unusedMethods = CleanUnusedMethods().find(path: self.selectedPath)
            _ = CleanUnusedMethods().find(path: self.selectedPath).subscribe(onNext: { (result) in
                if result is String {
                    DispatchQueue.main.async {
                        self.desLb.stringValue = result as! String
                    }
                    
                } else if result is [Method] {
                    self.unusedMethods = result as! [Method]
                } else if result is File {
                    DispatchQueue.main.async {
                        let aFile = result as! File
                        self.detailTxv.string = self.detailTxv.string! + aFile.des() + "\n"
                        self.detailTv.contentView .scroll(to: NSPoint(x: 0, y: ((self.detailTv.documentView?.frame.size.height)! - self.detailTv.contentSize.height)))
                    }
                }
            })
            DispatchQueue.main.async {
                self.cleanBt.isEnabled = true
                self.parsingIndicator.stopAnimation(nil)
                self.parsingIndicator.isHidden = true
                self.desLb.stringValue = "完成查找"
                self.resultTb.reloadData()
            }
        }
        
    }
    
    //选择一个文件夹
    private func selectFolder() -> String {
        let openPanel = NSOpenPanel();
        openPanel.canChooseDirectories = true;
        openPanel.canChooseFiles = false;
        if(openPanel.runModal() == NSModalResponseOK) {
            //print(openPanel.url?.absoluteString)
            let path = openPanel.url?.absoluteString
            //print("选择文件夹路径: \(path)")
            return path!
        }
        
        return ""
    }
    
    //TableView
    //Cell DoubleClick
    func cellDoubleClick() {
        let aMethod = self.unusedMethods[self.resultTb.clickedRow]
        let filePathString = aMethod.filePath.replacingOccurrences(of: "file://", with: "")
        //双击打开finder到指定的文件
        NSWorkspace.shared().openFile(filePathString, withApplication: "Xcode")
    }
    
    //NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.unusedMethods.count
    }
    
    //NSTableViewDelegate
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let aMethod = self.unusedMethods[row]
        
        let columnId = tableColumn?.identifier
        if columnId == "MethodId" {
            return aMethod.pnameId
        } else if columnId == "MethodPath" {
            let filePathString = aMethod.filePath.replacingOccurrences(of: "file://", with: "")
            return filePathString
        }
        
        return nil
    }
    
    //DragViewDelegate
    func dragExit() {
        //
    }
    func dragEnter() {
        //
    }
    func dragFileOk(filePath: String) {
        print("\(filePath)")
        selectedPath = "file://" + filePath + "/"
        pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
    }
}

