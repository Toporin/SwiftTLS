//
//  IPAddress.swift
//
//  Created by Nico Schmidt on 09.06.14.
//  Copyright (c) 2014 Nico Schmidt. All rights reserved.
//

import Foundation

public class IPAddress
{
    public var port : UInt16 {
        get { return 0}
        set {}
    }
    
    internal var _hostname : String = ""
    
    var hostname : String {
        get { return _hostname }
    }
    
    var string : String? {
        get {
            return ""
        }
    }
    
    var unsafeSockAddrPointer : UnsafePointer<sockaddr> {
        get {
            return UnsafePointer<sockaddr>(nil)!
        }
    }
    
    public class func localAddress() -> IPAddress {
        let localAddress = IPv6Address()

        var ipv6address = sockaddr_in6()
        memset(&ipv6address, 0, sizeof(sockaddr_in6.self))
        ipv6address.sin6_len = UInt8(sizeof(sockaddr_in6.self))
        ipv6address.sin6_family = sa_family_t(AF_INET6)
        ipv6address.sin6_port = 0
        ipv6address.sin6_addr = in6addr_loopback
        localAddress.socketAddress = ipv6address
        
        return localAddress
    }
    
    init() {}
    
    public class func addressWithString(_ hostname : String, port : Int? = nil) -> IPAddress?
    {
        if let ipv4address = IPv4Address(hostname) {
            if let p = port {
                ipv4address.port = UInt16(p)
            }
            return ipv4address
        }
        
        if let ipv6address = IPv6Address(hostname) {
            if let p = port {
                ipv6address.port = UInt16(p)
            }
            return ipv6address
        }
        
        var addressInfoPointer: UnsafeMutablePointer<addrinfo>? = nil
        let address : IPAddress? = hostname.nulTerminatedUTF8.withUnsafeBufferPointer {
            if getaddrinfo(UnsafePointer<Int8>($0.baseAddress), nil, nil, &addressInfoPointer) != 0 {
                print("Error: \(strerror(errno))")
                return nil
            }
            
            let addressInfo = addressInfoPointer!.pointee
            switch addressInfo.ai_family
            {
            case AF_INET:
                let addr = IPv4Address()
                memcpy(&addr.socketAddress, addressInfo.ai_addr, Int(addressInfo.ai_addrlen))
                
                return addr
                
            case AF_INET6:
                let addr = IPv6Address()
                memcpy(&addr.socketAddress, addressInfo.ai_addr, Int(addressInfo.ai_addrlen))
                
                return addr
                
            default:
                return nil
            }
        }
        
        if address != nil {
            if let p = port {
                address!.port = UInt16(p)
            }
            address!._hostname = hostname
        }
        
        return address
    }
    
}

public class IPv4Address : IPAddress
{
    var socketAddress = sockaddr_in()

    override public var port : UInt16 {
        get {
            return CFSwapInt16BigToHost(socketAddress.sin_port)
        }
        
        set {
            socketAddress.sin_port = CFSwapInt16HostToBig(newValue)
        }
    }
    
    public override init()
    {
    }
    
    public init?(_ address : String)
    {
        super.init()
        
        var resultCode : Int32 = 0
        address.withCString { (p : UnsafePointer<Int8>) -> () in
            resultCode = inet_pton(AF_INET, p, &self.socketAddress.sin_addr)
            if resultCode == 1 {
                self.socketAddress.sin_family = sa_family_t(AF_INET)
                self.socketAddress.sin_len = UInt8(sizeof(sockaddr_in.self))
            }
        }
        
        if resultCode == 0 {
            return nil
        }
    }
    
    override var string : String?
        {
        get {
            var buffer = Array<CChar>(repeating: 0, count: Int(INET_ADDRSTRLEN))
            let result = inet_ntop(AF_INET,
                &socketAddress.sin_addr,
                &buffer,
                socklen_t(INET_ADDRSTRLEN))
            
            if result != nil {
                return String(cString: result!)
            }
            
            return nil
        }
    }
    
    override var unsafeSockAddrPointer : UnsafePointer<sockaddr> {
        get {
            return withUnsafePointer(&socketAddress) {
                ptr in
                return UnsafePointer<sockaddr>(ptr)
            }
        }
    }
    
    public override class func localAddress() -> IPAddress {
        let localAddress = IPv4Address()
        
        var address = sockaddr_in()
        memset(&address, 0, sizeof(sockaddr_in.self))
        address.sin_len = UInt8(sizeof(sockaddr_in.self))
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = 0
        address.sin_addr.s_addr = 0
        localAddress.socketAddress = address
        
        return localAddress
    }

}

public class IPv6Address : IPAddress
{
    var socketAddress = sockaddr_in6()
    
    override public var port : UInt16 {
        get {
            return CFSwapInt16BigToHost(socketAddress.sin6_port)
        }
        
        set {
            socketAddress.sin6_port = CFSwapInt16HostToBig(newValue)
        }
    }

    override init()
    {
    }

    init?(_ address : String)
    {
        super.init()
        
        var resultCode : Int32 = 0
        address.withCString { (p : UnsafePointer<Int8>) -> () in
            resultCode = inet_pton(AF_INET6, p, &self.socketAddress.sin6_addr)
            if resultCode == 1 {
                self.socketAddress.sin6_family = sa_family_t(AF_INET6)
                self.socketAddress.sin6_len = UInt8(sizeof(sockaddr_in.self))
            }
        }
        
        if resultCode == 0 {
            return nil
        }
    }

    override var string : String?
    {
        get {
            var buffer = Array<CChar>(repeating: 0, count: Int(INET6_ADDRSTRLEN))
            let result = inet_ntop(AF_INET6,
                &socketAddress.sin6_addr,
                &buffer,
                socklen_t(INET6_ADDRSTRLEN))
            
            if result != nil {
                return String(cString: result!)
            }
            
            return nil
        }
    }

    override var unsafeSockAddrPointer : UnsafePointer<sockaddr> {
        get {
            return withUnsafePointer(&socketAddress) {
                ptr in
                return UnsafePointer<sockaddr>(ptr)
            }
        }
    }

}
