//
//  SocketTests.swift
//  SwiftTLS
//
//  Created by Nico Schmidt on 09.05.15.
//  Copyright (c) 2015 Nico Schmidt. All rights reserved.
//

import Cocoa
import XCTest
@testable import SwiftTLS

class SocketTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func test_listen_whenClientConnects_callsAcceptBlock()
    {
        let server = TCPSocket()
        let address = IPv4Address.localAddress()
        address.port = UInt16(12345)
        
        let expectation = self.expectation(description: "accept connection successfully")

        DispatchQueue.global(attributes: DispatchQueue.GlobalAttributes.qosDefault).async {
            do {
                try server.acceptConnection(address)
                
                expectation.fulfill()
                server.close()

            } catch {
            }
        }
        
        sleep(2)
        
        do {
            let client = TCPSocket()
            do {
                try client.connect(address)
                
                client.close()
                
                self.waitForExpectations(timeout: 50.0, handler: { (error : NSError?) -> Void in
                })
            }
            catch let error as SocketError {
                print("\(error)")
                XCTFail()
            }
            catch _ {}
        }

    }
}
