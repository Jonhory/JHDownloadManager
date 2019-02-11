//
//  TestCellModel.swift
//  JHDownloadManager
//
//  Created by Jonhory on 2019/1/29.
//  Copyright © 2019 jdj. All rights reserved.
//

import Foundation
import UIKit

class TestCellModel: NSObject {
    
    var backColor = UIColor.randomColor
    var url: String = ""
    var index: String = "0"
    
    var progress: Float = 0
    var speed: String = "0 kb"
    var state: String = "开始"
    
    func reload() {
        progress = 0
        state = "开始"
        speed = "0 kb"
    }
}
