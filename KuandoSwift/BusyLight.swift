//
//  BusyLight.swift
//  KuandoSwift
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import IOKit.hid

class BusyLight : NSObject {
    let vendorId = 0x04D8
    let productId = 0xF848
    let reportSize = 64//Device specific
    static let singleton = BusyLight()
    var device : IOHIDDevice? = nil
    
    
    func input(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, type: IOHIDReportType, reportId: UInt32, report: UnsafeMutablePointer<UInt8>, reportLength: CFIndex) {
        let message = NSData(bytes: report, length: reportLength)
        print("Input received: \(message)")
    }
    
    func output(data: NSData) {
        if (data.length > reportSize) {
            print("output data too large for USB report")
            return
        }
        let reportId : CFIndex = 0
        if let busylight = device {
            print("Senting output: \(data)")
            IOHIDDeviceSetReport(busylight, kIOHIDReportTypeOutput, reportId, UnsafePointer<UInt8>(data.bytes), data.length);
        }
    }
    
    func connected(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device connected")
        // It would be better to look up the report size and create a chunk of memory of that size
        let report = UnsafeMutablePointer<UInt8>.alloc(reportSize)
        device = inIOHIDDeviceRef
        
        let inputCallback : IOHIDReportCallback = { inContext, inResult, inSender, type, reportId, report, reportLength in
            let this : BusyLight = unsafeBitCast(inContext, BusyLight.self)
            this.input(inResult, inSender: inSender, type: type, reportId: reportId, report: report, reportLength: reportLength)
        }
        
        //Hook up inputcallback
        IOHIDDeviceRegisterInputReportCallback(device, report, reportSize, inputCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self));
        
        //Turn on light to demonstrate sending a command
        let sound : UInt8 = 0
        let r : UInt8 = 0
        let g : UInt8 = 0xff
        let b : UInt8 = 0
        let bytes : [UInt8] = [0, 0, r, g, b, 0, 0, sound, 0, 0, 0, 0, 0, 0]
        
        self.output(NSData(bytes:bytes, length:bytes.count))
    }
    
    func removed(inResult: IOReturn, inSender: UnsafeMutablePointer<Void>, inIOHIDDeviceRef: IOHIDDevice!) {
        print("Device removed")
        NSNotificationCenter.defaultCenter().postNotificationName("deviceDisconnected", object: nil, userInfo: ["class": NSStringFromClass(self.dynamicType)])
    }

    
    func initUsb() {
        let deviceMatch = [kIOHIDProductIDKey: productId, kIOHIDVendorIDKey: vendorId ]
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone)).takeUnretainedValue()
        
        IOHIDManagerSetDeviceMatching(managerRef, deviceMatch)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        IOHIDManagerOpen(managerRef, 0);
        
        let matchingCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : BusyLight = unsafeBitCast(inContext, BusyLight.self)
            this.connected(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let removalCallback : IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this : BusyLight = unsafeBitCast(inContext, BusyLight.self)
            this.removed(inResult, inSender: inSender, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, UnsafeMutablePointer<Void>.self))
        
        NSRunLoop.currentRunLoop().run();
    }

}