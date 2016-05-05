//
//  MovieCreatable.swift
//  Teiten
//
//  Created by nakajijapan on 2016/05/06.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Foundation

protocol MovieMakerDelegate {
    func movieMakerDidAddObject(current: Int, total: Int)
}

protocol MovieCreatable {
    associatedtype FileListType
    var size:NSSize { get set }
    var files:[FileListType] { get set }
    var delegate:MovieMakerDelegate? { get set }

    
    func generateMovie(composedMoviePath:String, success: (() -> Void)) -> Void
}

