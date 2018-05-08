//
//  ChannelDetailsInteractor.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-04.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol ChannelDetailsBusinessLogic {
  func refresh(request: ChannelDetails.Refresh.Request)
  func connect(request: ChannelDetails.Connect.Request)
  func close(request: ChannelDetails.Close.Request)
}

protocol ChannelDetailsDataStore {
  var channelVM: ChannelVM? { get set }
}

class ChannelDetailsInteractor: ChannelDetailsBusinessLogic, ChannelDetailsDataStore
{
  var presenter: ChannelDetailsPresentationLogic?
  
  // MARK: Data Store
  
  var channelVM: ChannelVM?
  
  
  // MARK: Refresh
  
  func refresh(request: ChannelDetails.Refresh.Request) {
    guard var channelVM = channelVM else {
      SLLog.assert("channelVM = nil in ChannelDetails interactor")
      let result = Result<ChannelVM>.failure(ChannelDetails.Error.noChannelInfo)
      let response = ChannelDetails.Refresh.Response(result: result)
      self.presenter?.presentRefresh(response: response)
      return
    }
    
    // Try to grab additional node details
    LNServices.getNodeInfo(pubKey: channelVM.nodePubKey) { (responder) in
      do {
        let nodeInfo = try responder()
        
        let ipPort = nodeInfo.address[0].split(separator: ":")

        channelVM.ipAddress = String(ipPort[0])
        channelVM.port = String(ipPort[1])
        channelVM.alias = nodeInfo.alias
        self.channelVM = channelVM  // Save a copy back to own data store
        
        let result = Result<ChannelVM>.success(channelVM)
        let response = ChannelDetails.Refresh.Response(result: result)
        self.presenter?.presentRefresh(response: response)
        
      } catch {
        let result = Result<ChannelVM>.failure(error)
        let response = ChannelDetails.Refresh.Response(result: result)
        self.presenter?.presentRefresh(response: response)
      }
    }
  }
  
  
  // MARK: Connect
  
  func connect(request: ChannelDetails.Connect.Request) {
    guard let channelVM = channelVM else {
      SLLog.assert("channelVM = nil in ChannelDetails interactor")
      let result = Result<Void>.failure(ChannelDetails.Error.noChannelInfo)
      let response = ChannelDetails.Connect.Response(result: result)
      self.presenter?.presentConnect(response: response)
      return
    }
    
    guard let ipAddress = channelVM.ipAddress, let portString = channelVM.port, let port = Int(portString) else {
      let result = Result<Void>.failure(ChannelDetails.Error.noIPPort)
      let response = ChannelDetails.Connect.Response(result: result)
      self.presenter?.presentConnect(response: response)
      return
    }
    
    LNServices.connectPeer(pubKey: channelVM.nodePubKey, hostAddr: ipAddress, hostPort: port) { (responder) in
      do {
        try responder()
        let response = ChannelDetails.Connect.Response(result: Result<Void>.success(()))
        self.presenter?.presentConnect(response: response)
        
      } catch {
        let result = Result<Void>.failure(error)
        let response = ChannelDetails.Connect.Response(result: result)
        self.presenter?.presentConnect(response: response)
      }
    }
  }
  
  
  // MARK: Close
  
  func close(request: ChannelDetails.Close.Request) {
    guard let channelVM = channelVM else {
      SLLog.assert("channelVM = nil in ChannelDetails interactor")
      let result = Result<Void>.failure(ChannelDetails.Error.noChannelInfo)
      let response = ChannelDetails.Close.Response(result: result)
      self.presenter?.presentClose(response: response)
      return
    }
    
    let channelPoint = channelVM.channelPoint.split(separator: ":")
    
    guard channelPoint.count == 2 else {
      SLLog.assert("channelPoint.count != 2 in ChannelDetails interactor")
      let result = Result<Void>.failure(ChannelDetails.Error.invalidChannelPoint)
      let response = ChannelDetails.Close.Response(result: result)
      self.presenter?.presentClose(response: response)
      return
    }
    
    let fundingTxIDStr = String(channelPoint[0])
    let outputIndexStr = String(channelPoint[1])
    
    guard let outputIndex = UInt(outputIndexStr) else {
      SLLog.assert("channelPoint.count != 2 in ChannelDetails interactor")
      let result = Result<Void>.failure(ChannelDetails.Error.invalidChannelPoint)
      let response = ChannelDetails.Close.Response(result: result)
      self.presenter?.presentClose(response: response)
      return
    }
    
    LNServices.closeChannel(fundingTxIDStr: fundingTxIDStr,
                            outputIndex: outputIndex,
                            force: request.force,
                            completion: closeChannelCompletion)
  }
  
//  private func closeChannelStreaming(callHandle: () throws -> (Lnrpc_LightningCloseChannelCall)) {
//    do {
//      let _ = try callHandle()
//      
//      // TODO: Pass to Stream Handler module for receive handling after the first stream
//      
//      let response = ChannelDetails.Close.Response(result: Result<Void>.success(()))
//      presenter?.presentClose(response: response)
//    } catch {
//      // Counting on failures to come thru the Completion path instead of the Streaming path
//    }
//  }
  
  private func closeChannelCompletion(responder: () throws -> ()) {
    do {
      try responder()
      // TODO: Do direct trigger into Event Center
      
      let response = ChannelDetails.Close.Response(result: Result<Void>.success(()))
      presenter?.presentClose(response: response)
    } catch {
      
      // This is the nay path if the Close Channel Scene still exists
      let response = ChannelDetails.Close.Response(result: Result<Void>.failure(error))
      presenter?.presentClose(response: response)
      
      // If the Scene dun exist, route to Event Center instead
      // TODO: Do direct trigger into Event Cetner
    }
  }
  
}
