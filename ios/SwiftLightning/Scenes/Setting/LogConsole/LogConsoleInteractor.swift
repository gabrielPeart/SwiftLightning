//
//  LogConsoleInteractor.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-12.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol LogConsoleBusinessLogic
{
  func readLog(request: LogConsole.ReadLog.Request)
  func getLogURL(request: LogConsole.GetLogURL.Request)
}

protocol LogConsoleDataStore
{
  //var name: String { get set }
}

class LogConsoleInteractor: LogConsoleBusinessLogic, LogConsoleDataStore {
  var presenter: LogConsolePresentationLogic?

  // MARK: Read Log
  
  func readLog(request: LogConsole.ReadLog.Request) {
    var logPath: String?
    
    switch request.logType {
    case .wallet:
      logPath = getLatestWalletLogPath
    case .lnd:
      logPath = LNManager.getLndLogURL().path
    }

    guard let readLogPath = logPath else {
      let result = Result<String>.failure(LogConsole.Error.logPathNotFound(request.logType.rawValue))
      let response = LogConsole.ReadLog.Response(result: result)
      presenter?.presentReadLog(response: response)
      return
    }
    
    do {
      // Got the last file, read it into a string
      let logText = try String(contentsOfFile: readLogPath, encoding: .utf8)
      
      // !!! this is super large, can the phone handle it?
      let result = Result<String>.success(logText)
      let response = LogConsole.ReadLog.Response(result: result)
      presenter?.presentReadLog(response: response)
      
    } catch {
      let result = Result<String>.failure(error)
      let response = LogConsole.ReadLog.Response(result: result)
      presenter?.presentReadLog(response: response)
    }
  }
  
  
  // MARK: Get Log URL
  
  func getLogURL(request: LogConsole.GetLogURL.Request) {
    var logURL: URL
    
    switch request.logType {
    case .wallet:
      guard let logPath = getLatestWalletLogPath else {
        let result = Result<URL>.failure(LogConsole.Error.logPathNotFound(request.logType.rawValue))
        let response = LogConsole.GetLogURL.Response(result: result)
        presenter?.presentGetLogURL(response: response)
        return
      }
      
      logURL = URL(fileURLWithPath: logPath, isDirectory: false)
      
    case .lnd:
      logURL = LNManager.getLndLogURL()
    }
    
    let result = Result<URL>.success(logURL)
    let response = LogConsole.GetLogURL.Response(result: result)
    presenter?.presentGetLogURL(response: response)
  }
  
  
  private var getLatestWalletLogPath: String? {
    guard let appSupportPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path else {
      SLLog.fatal("Cannot get Application Support Folder URL")
    }
    let walletLogFolderPath = appSupportPath + "/Logs"

    // Find all the files in .log
    let enumerator = FileManager.default.enumerator(atPath: walletLogFolderPath)
    if let filePaths = enumerator?.allObjects as? [String] {
      let logFilePaths = filePaths.filter{$0.contains(".log")}
      
      // Get the latest of all .log files
      if let latestLogPath = logFilePaths.sorted().last {
        return walletLogFolderPath + "/" + latestLogPath
      }
    }
    
    return nil
  }
}
