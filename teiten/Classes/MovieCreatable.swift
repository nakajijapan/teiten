//
//  MovieCreatable.swift
//  Teiten
//
//  Created by nakajijapan on 2016/05/06.
//  Copyright © 2016年 net.nakajijapan. All rights reserved.
//

import Foundation


protocol MovieCreatable {
    associatedtype FileListType
    var size:NSSize { get set }
    var files:[FileListType] { get set }
    
    func generateMovie(composedMoviePath:String, success: (() -> Void)) -> Void
}

extension MovieCreatable {
    
}