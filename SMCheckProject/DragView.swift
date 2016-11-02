//
//  DragView.swift
//  SMCheckProject
//
//  Created by didi on 2016/11/1.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa

protocol DragViewDelegate {
    func dragEnter();
    func dragExit();
    func dragFileOk(filePath:String);
}

class DragView: NSView {
    var delegate : DragViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.register(forDraggedTypes: [NSFilenamesPboardType, NSURLPboardType, NSPasteboardTypeTIFF])
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if let delegate = self.delegate {
            delegate.dragEnter()
        }
        return NSDragOperation.generic
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let delegate = self.delegate {
            delegate.dragExit()
        }
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
//        var files = [URL]()
        var filePath = ""
        if let board = sender.draggingPasteboard().propertyList(forType: NSFilenamesPboardType) as? NSArray {
            for path in board {
                filePath = path as! String
            }
        }
        if let delegate = self.delegate {
            delegate.dragFileOk(filePath: filePath)
        }
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
