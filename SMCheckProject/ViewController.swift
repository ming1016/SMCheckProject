//
//  ViewController.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/13.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    @IBOutlet weak var parsingIndicator: NSProgressIndicator!
    @IBOutlet weak var desLb: NSTextField!
    @IBOutlet weak var cleanUnuseMethodBt: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        parsingIndicator.isHidden = true
        desLb.stringValue = "请选择工程目录"
        
    }
    
    @IBAction func cleanUnuseMethodAction(_ sender: AnyObject) {
        let fileFolderPath = self.selectFolder()
        parsingIndicator.isHidden = false
        parsingIndicator.startAnimation(nil)
        desLb.stringValue = "清理中..."
        DispatchQueue.global().async {
            CleanUnusedMethods().clean(path: fileFolderPath)
            DispatchQueue.main.async {
                self.parsingIndicator.stopAnimation(nil)
                self.parsingIndicator.isHidden = true
                self.desLb.stringValue = "完成清理"
            }
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    //选择一个文件夹
    func selectFolder() -> String {
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

}

