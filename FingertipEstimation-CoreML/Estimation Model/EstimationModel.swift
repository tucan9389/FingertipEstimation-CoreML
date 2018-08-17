//
//  EstimationModel.swift
//  FingerEstimation-CoreML
//
//  Created by GwakDoyoung on 14/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import Foundation

protocol EstimationModelProtocol {
    var pointLabels: [String] { get }
    var connectingPointIndexs: [(Int, Int)] { get }
}
