//
//  JHDownloadManager.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/21.
//  Copyright © 2019 jdj. All rights reserved.
//

import Foundation

enum JHDownloadState: Int {
    
    case start
    case paused
    case completed
    case failed
}

extension JHDownloadState {
    
    var desc: String {
        switch self {
        case .start: return "开始"
        case .paused: return "暂停"
        case .completed: return "完成"
        case .failed: return "失败"
        }
    }
}

class JHDownloadSessionModel {
    
    var stream: OutputStream?
    lazy var url = ""
    lazy var totalLength: Int = 0
    
    var progressBlock: ((_ receivedSize: Int, _ expectedSize: Int, _ progress: Float) -> Void)?
    var stateBlock: ((_ state: JHDownloadState) -> Void)?
}

class JHDownloadManager: NSObject {
    
    override init() {
        super.init()
        JHLog("JHDownloadManager 缓存路径: \(cachesDirectory)")
    }
    
    /// 保存所有任务 资源地址md5值为key
    fileprivate lazy var tasks: [String: URLSessionTask] = [:]
    /// 保存所有下载相关信息
    fileprivate lazy var sessionModels: [Int: JHDownloadSessionModel] = [:]
    
    /// 缓存路径
    fileprivate lazy var cachesDirectory: String = {
        let doc = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).last
        if doc != nil && doc != "" { return doc! + "/JHDownloadCache" }
        return ""
    }()

}

extension JHDownloadManager {
    
    /// 文件名
    fileprivate func fileName(with url: String) -> String {
        return url.jh_md5()
    }
    
    /// 文件完整路径
    fileprivate func fileFullPath(with url: String) -> String {
        return cachesDirectory + "/" + fileName(with:url)
    }
    
    /// 文件已下载长度
    fileprivate func downloadLength(with url: String) -> Int {
        do {
            let items = try FileManager.default.attributesOfItem(atPath: fileFullPath(with: url))
            if let size = items[FileAttributeKey.size] {
                if let s = size as? Int { return s }
            }
        } catch {
        }
        return 0
    }
    
    /// 存储文件长度的文件路径
    fileprivate func totalLengthFullPath() -> String {
        return cachesDirectory + "/jhDownloadTotalSize.plist"
    }
    
    /// 创建缓存文件夹
    fileprivate func createCacheDirectory() {
        if !FileManager.default.fileExists(atPath: cachesDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: cachesDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                JHLog("创建缓存文件夹失败")
            }
        }
    }
    
    fileprivate func start(url: String) {
        if let task = getTask(url: url) {
            task.resume()
            JHLog("开始下载: \(url)")
            sessionModels[task.taskIdentifier]?.stateBlock?(.start)
        }
    }
    
    fileprivate func pause(url: String) {
        if let task = getTask(url: url) {
            task.suspend()
            JHLog("暂停下载: \(url)")
            sessionModels[task.taskIdentifier]?.stateBlock?(.paused)
        }
    }
    
    fileprivate func getTask(url: String) -> URLSessionTask? {
        return tasks[fileName(with: url)]
    }
}

extension JHDownloadManager {
    
    /// 开启任务下载资源
    ///
    /// - Parameters:
    ///   - url: 资源路径
    ///   - progress: 下载进度
    ///   - state: 下载状态
    func download(url: String, progress: @escaping ((_ receivedSize: Int, _ expectedSize: Int, _ progress: Float) -> Void), state:  @escaping ((_ state: JHDownloadState) -> Void)) {
        if url.isEmpty { return }
        if isCompletion(with: url) {
            progress(downloadLength(with: url), totalLengthSize(with: url), 1.0)
            state(.completed)
            JHLog("该资源已下载完成 >>> \(url)")
            return
        }
        
        if let task = tasks[fileName(with: url)] {
            if task.state == .running {
                pause(url: url)
            } else {
                start(url: url)
            }
            return
        }
        
        createCacheDirectory()
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        if let stream = OutputStream(toFileAtPath: fileFullPath(with: url), append: true), let u = URL(string: url) {
            var request = URLRequest(url: u)
            request.setValue(String(format: "bytes=%zd-", downloadLength(with: url)), forHTTPHeaderField: "Range")
            
            let task = session.dataTask(with: request)
            let taskID = Int(arc4random()%100000) + Int(Date().jh_milliStamp)
            task.setValue(taskID, forKey: "taskIdentifier")
            
            tasks[fileName(with: url)] = task
            
            let sessionModel = JHDownloadSessionModel()
            sessionModel.url = url
            sessionModel.progressBlock = progress
            sessionModel.stateBlock = state
            sessionModel.stream = stream
            sessionModels[taskID] = sessionModel
            
            start(url: url)
        }
        
    }
    
    /// 获取资源的下载进度
    ///
    /// - Parameter url: 资源路径
    /// - Returns: 下载进度值
    func progressSize(with url: String) -> Float {
        if totalLengthSize(with: url) > 0 {
            return Float(downloadLength(with: url)) / Float(totalLengthSize(with: url))
        }
        return 0
    }
    
    /// 获取资源总大小（bytes）
    ///
    /// - Parameter url: 资源路径
    /// - Returns: 资源总大小（bytes）
    func totalLengthSize(with url: String) -> Int {
        if let dic = NSDictionary(contentsOfFile: totalLengthFullPath()) {
            if let v = dic.value(forKey: fileName(with: url)) {
                return v as! Int
            }
        }
        return 0
    }
    
    /// 判断资源是否完成
    ///
    /// - Parameter url: 资源路径
    /// - Returns: true 完成
    func isCompletion(with url: String) -> Bool {
        if totalLengthSize(with: url) > 0 && totalLengthSize(with: url) == downloadLength(with: url) {
            return true
        }
        return false
    }
    
    /// 删除本地资源
    ///
    /// - Parameter url: 资源路径
    func deleteFile(with url: String) {
        tasks.removeValue(forKey: fileName(with: url))
        if let task = getTask(url: url) {
            task.cancel()
            sessionModels.removeValue(forKey: task.taskIdentifier)
        }
        let manager = FileManager.default
        if manager.fileExists(atPath: fileFullPath(with: url)) {
            do {
                try manager.removeItem(atPath: fileFullPath(with: url))
            } catch {
                JHLog("删除资源失败：\(url)")
            }
        }
        if manager.fileExists(atPath: totalLengthFullPath()) {
            if let dict = NSMutableDictionary(contentsOfFile: totalLengthFullPath()) {
                dict.removeObject(forKey: fileName(with: url))
                dict.write(toFile: totalLengthFullPath(), atomically: true)
            }
        }
    }
    
    /// 删除所有本地资源
    func deleteAllFiles() {
        for (_, task) in tasks {
            task.cancel()
        }
        tasks.removeAll()
        for (_, m) in sessionModels {
            m.stream?.close()
            m.stream = nil
        }
        sessionModels.removeAll()
        
        let manager = FileManager.default
        if manager.fileExists(atPath: cachesDirectory) {
            do {
                try manager.removeItem(atPath: cachesDirectory)
            } catch {
                JHLog("删除所有资源失败")
            }
        }
    }
    
}

extension JHDownloadManager: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        if let sessionModel = sessionModels[dataTask.taskIdentifier] {
            sessionModel.stream?.open()
            
            let totalLength = Int(response.expectedContentLength) + downloadLength(with: sessionModel.url)
            sessionModel.totalLength = totalLength
            
            var dict = NSMutableDictionary(contentsOfFile: totalLengthFullPath())
            if dict == nil { dict = NSMutableDictionary() }
            dict?.setValue(totalLength, forKey: fileName(with: sessionModel.url))
            dict?.write(toFile: totalLengthFullPath(), atomically: true)
            
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let sessionModel = sessionModels[dataTask.taskIdentifier] {
            
            let bytes = [UInt8](data)
            sessionModel.stream?.write(UnsafePointer<UInt8>(bytes), maxLength: bytes.count)
            
            let receivedSize = downloadLength(with: sessionModel.url)
            let expectedSize = sessionModel.totalLength
            let progress = Float(receivedSize) / Float(expectedSize)
            
            sessionModel.progressBlock?(receivedSize, expectedSize, progress)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let sessionModel = sessionModels[task.taskIdentifier] {
            JHLog("任务结束: \(sessionModel.url)")
            if isCompletion(with: sessionModel.url) {
                sessionModel.stateBlock?(.completed)
            } else {
                sessionModel.stateBlock?(.failed)
            }
            sessionModel.stream?.close()
            sessionModel.stream = nil
            
            tasks.removeValue(forKey: fileName(with: sessionModel.url))
            sessionModels.removeValue(forKey: task.taskIdentifier)
        }
    }
    
}

extension JHDownloadManager {
    
    func JHLog<T>(_ messsage: T, file: String = #file, funcName: String = #function, lineNum: Int = #line) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("\(fileName):(\(lineNum))======>>>>>>\n\(messsage)")
        #endif
    }
    
}

extension Date {
    
    /// 获取当前 毫秒级 时间戳 - 13位
    fileprivate var jh_milliStamp : Int {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval*1000))
        return Int(millisecond)
    }
}

extension String {
    
    // md5加密
    fileprivate func jh_md5() -> String {
        let str = self.cString(using: .utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: .utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
}
