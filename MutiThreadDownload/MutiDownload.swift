//
//  MutiDownload.swift
//  MutiThreadDownload
//
//  Created by XWJACK on 3/17/16.
//  Copyright © 2016 XWJACK. All rights reserved.
//

import Foundation

public class MutiDownload {
    
    private var url:String
    private var fileinfo:fileInfo?
    private weak var delegate:downloadDelegate?
    
    private var download = [Download]()
    
    public var name:String? { return  fileinfo == nil ? nil : fileinfo!.name }
    public var size:Int64? { return fileinfo == nil ? nil : fileinfo!.size }
    
    init(url:String, delegate:downloadDelegate?) {
        self.url = url
        self.delegate = delegate
        
        fileinfo = xGetFileInfo(url)
        assert(fileinfo != nil, "Can't get file infomation")
        //guard fileinfo != nil else { return nil }
    }
    /**
    To get file information about file size and file name
    
    - returns: fileInfo
    */
    private func xGetFileInfo(url:String) -> fileInfo? {
        let requst = NSMutableURLRequest(URL: NSURL(string: url)!)
        requst.HTTPMethod = Method.HEAD.rawValue
        var response:NSURLResponse?
        do {
            try NSURLConnection.sendSynchronousRequest(requst, returningResponse: &response)
            return fileInfo(size: response!.expectedContentLength, name: response!.suggestedFilename)
        }catch { assert(response != nil, "get file information error") }/* URL error or Network Error */
        return nil
    }
    
    public func xMutiDownload() {
        let home = NSHomeDirectory()
        let filepath = home + "/Downloads/\(name!)"
        
        /// Remove file if it exist
        let fileManager = NSFileManager.defaultManager()
        if fileManager.fileExistsAtPath(filepath) {
            do {
                try fileManager.removeItemAtPath(filepath)
            }catch { assert(false, "Remove file error") }
        }
        
        /// Create an empty file
        fileManager.createFileAtPath(filepath, contents: nil, attributes: nil)
        if let filehandle = NSFileHandle(forWritingAtPath: filepath) {
            filehandle.truncateFileAtOffset(UInt64(size!))
            filehandle.closeFile()
        }
        
        let group = dispatch_group_create()
        let queue = dispatch_queue_create("com.download.xwjack", DISPATCH_QUEUE_SERIAL)
        
        dispatch_group_async(group, queue, {
            self.download.append(Download(url: self.url, filelocation: filepath, delegate: self.delegate, 1, 0, self.fileinfo!.size / 4))
            self.download[0].xdownload()
        })
        dispatch_group_async(group, queue, {
            self.download.append(Download(url: self.url, filelocation: filepath, delegate: self.delegate, 2, self.fileinfo!.size / 4 + 1, self.fileinfo!.size / 4 * 2))
            self.download[1].xdownload()
        })
        dispatch_group_async(group, queue, {
            self.download.append(Download(url: self.url, filelocation: filepath, delegate: self.delegate, 3, self.fileinfo!.size / 4 * 2 + 1, self.fileinfo!.size / 4 * 3))
            self.download[2].xdownload()
        })
        dispatch_group_async(group, queue, {
            self.download.append(Download(url: self.url, filelocation: filepath, delegate: self.delegate, 4, self.fileinfo!.size / 4 * 3 + 1, self.fileinfo!.size))
            self.download[3].xdownload()
        })
        dispatch_group_notify(group, queue, {
            print("All Thread Begin Download")
        })
    }
    
    public func xSuspend() {
        for download in self.download {
            download.xSuspend()
        }
    }
    public func xResume() {
        for download in self.download {
            download.xResume()
        }
    }
    public func xStop() {
        for download in self.download {
            download.xStop()
        }
    }
}