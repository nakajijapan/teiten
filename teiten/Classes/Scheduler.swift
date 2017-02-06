//
//  Scheduler.swift
//  Teiten
//
//  Created by nakajijapan on 2016/02/13.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Cocoa
import RxSwift
import RxCocoa

class Scheduler {
    
    let backgroundWorkScheduler: OperationQueueScheduler
    let mainScheduler: SerialDispatchQueueScheduler
    
    init() {

        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 10
        operationQueue.qualityOfService = QualityOfService.userInitiated
        backgroundWorkScheduler = OperationQueueScheduler(operationQueue: operationQueue)

        mainScheduler = MainScheduler.instance
    }
    
}
