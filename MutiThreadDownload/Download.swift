//
//  Download.swift
//  MutiThreadDownload
//
//  Created by XWJACK on 3/16/16.
//  Copyright © 2016 XWJACK. All rights reserved.
//

import Foundation

//Method of head
public enum Method: String {
    case OPTIONS, GET, HEAD, POST, PUT, PATCH, DELETE, TRACE, CONNECT
}

/**
*  Store file information
*/
public struct fileInfo {
    var size:Int64        /*size of bytes*/
    var name:String?     /*file name*/
}

/**
*  Refresh UI
*/
public protocol downloadDelegate: NSObjectProtocol {
    func refresh(thread:Int, threadprogress:Double)
}

/// Download file
public class Download: NSObject, NSURLSessionDownloadDelegate {
    
    private var url:String
    private weak var delegate:downloadDelegate?
    private var task:NSURLSessionDownloadTask?
    private var thread:Int
    private var filelocation:String
    private var fbegin:Int64
    private var fend:Int64
    
    init(url:String, filelocation:String, delegate:downloadDelegate?, _ thread:Int, _ fbegin:Int64, _ fend:Int64) {
        self.url = url
        self.delegate = delegate
        self.thread = thread
        self.filelocation = filelocation
        self.fbegin = fbegin
        self.fend = fend
    }
    
    public func xdownload() {
        let requst = NSMutableURLRequest(URL: NSURL(string: url)!)
        assert(fbegin < fend)
        requst.setValue("bytes=\(fbegin)-\(fend)", forHTTPHeaderField: "Range")/* Set rang to get different data */
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: nil)
        task = session.downloadTaskWithRequest(requst)/*, completionHandler: { (url, response, error) -> Void in
            session.finishTasksAndInvalidate()/* Invalidates the object */
            print("Close")
        })*/
        assert(task != nil, "task is nil")
        task?.resume()
    }
    
    public func xSuspend() { task?.suspend() }
    
    public func xResume() { task?.resume() }
    
    public func xStop() { task?.cancel() }
    
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progressPercent = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if let progressdelegate = delegate {
            progressdelegate.refresh(thread, threadprogress: progressPercent)
        }
        //print("\(thread):\(totalBytesWritten)bytes \(totalBytesExpectedToWrite)bytes")
    }
    public func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL) {
        session.finishTasksAndInvalidate()/* Invalidates the object */
        guard let filepath = location.path else { assert(false, "Get file location error"); return }
        guard let readhandle = NSFileHandle(forReadingAtPath: filepath) else { assert(false, "Read file error"); return }
        guard let writehandle = NSFileHandle(forWritingAtPath: filelocation) else { assert(false, "Write file error"); return }
        
        print(filepath)
        writehandle.seekToFileOffset(UInt64(fbegin))
        
        /// move file to destination
        var currentLength:UInt64 = 0
        while true {
            let data = readhandle.readDataOfLength(1024)
            writehandle.writeData(data)
            if data.length < 1024 { break }
            currentLength += 1024
            readhandle.seekToFileOffset(currentLength)
            writehandle.seekToFileOffset(currentLength)
        }
        writehandle.closeFile()
        readhandle.closeFile()
        
        /// delete temp file
        let filemanager = NSFileManager.defaultManager()
        do {
            try filemanager.removeItemAtPath(filepath)
        }catch { assert(false, "Remove file error") }
    }
}