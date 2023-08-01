//
//  AppDelegate.swift
//  TCMergePDFDemo
//
//  Created by tangchao on 2023/8/1.
//

import Cocoa
import PDFKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var window: NSWindow!


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        let button = NSButton()
        let size: CGFloat = 60
        let x = (NSWidth(self.window.frame) - size) * 0.5
        let y = (NSHeight(self.window.frame) - size) * 0.5
        button.frame = NSMakeRect(x, y, size, size)
        self.window.contentView?.addSubview(button)
        
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.green.cgColor
        button.isBordered = false
        button.title = NSLocalizedString("合并", comment: "")
        button.action = #selector(buttonAction)
    }
    
    @objc func buttonAction() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["pdf"]
        panel.allowsMultipleSelection = true
        panel.beginSheetModal(for: self.window) { response in
            if (response == .cancel) {
                return
            }
            
            self.mergePDF(urls: panel.urls)
        }
    }
    
    // 合并PDF，自动为每个文档新增书签(大纲)，标题为文件名
    
    func mergePDF(urls: [URL]) {
        DispatchQueue.global().async {
            let pdfDocument = PDFDocument()
            let ol_root = PDFOutline()
            
            for url in urls {
                guard let document = PDFDocument(url: url) else {
                    continue
                }

                if let root = document.outlineRoot {
                    // 书签(大纲)标题为文件名称
                    root.label = url.deletingPathExtension().lastPathComponent
                    
                    // 书签(大纲) 位置为文档首页
                    if let page = document.page(at: 0) {
                        root.destination = PDFDestination(page: page, at: NSMakePoint(0, page.bounds(for: .cropBox).size.height))
                    }
                    // 添加书签(大纲)
                    ol_root.insertChild(root, at: ol_root.numberOfChildren)
                } else {
                    let ol = PDFOutline()
                    // 书签(大纲)标题为文件名称
                    ol.label = url.deletingPathExtension().lastPathComponent
                    // 书签(大纲) 位置为文档首页
                    if let page = document.page(at: 0) {
                        ol.destination = PDFDestination(page: page, at: NSMakePoint(0, page.bounds(for: .cropBox).size.height))
                    }
                    document.outlineRoot = ol
                    
                    // 添加书签(大纲)
                    ol_root.insertChild(ol, at: ol_root.numberOfChildren)
                }
                
                // 合并文件
                for i in 0 ..< document.pageCount {
                    if let page = document.page(at: i) {
                        pdfDocument.insert(page, at: pdfDocument.pageCount)
                    }
                }
            }
            // 为新文档新增大纲
            pdfDocument.outlineRoot = ol_root
            
            // 存储到临时路径
            let path = "\(NSTemporaryDirectory())/merge_test.pdf"
            if (pdfDocument.write(toFile: path)) {
                NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

