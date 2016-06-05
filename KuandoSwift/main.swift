//
//  main.swift
//  KuandoSwift
//
//  Created by Eric Betts on 6/19/15.
//  Copyright © 2015 Eric Betts. All rights reserved.
//

import Foundation
import AppKit

let busylight = BusyLight.singleton
var daemon = NSThread(target: busylight, selector:#selector(BusyLight.initUsb), object: nil)

daemon.start()
NSRunLoop.currentRunLoop().run()

