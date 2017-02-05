//
//  Filter.swift
//  moviecam
//
//  Created by Yuta Tanimura on 2017/02/06.
//  Copyright © 2017年 yutanim. All rights reserved.
//

import Foundation
import GPUImage

protocol Filter {
    var name: String { get }
    var filter: GPUImageFilter {get}
}
