//
//  PoseEstimationModel.swift
//  FingerEstimation-CoreML
//
//  Created by GwakDoyoung on 14/07/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import Foundation

struct PoseEstimationModel: EstimationModelProtocol {
    var pointLabels: [String] = [
        "top\t\t\t", //0
        "neck\t\t", //1
        
        "R shoulder\t", //2
        "R elbow\t\t", //3
        "R wrist\t\t", //4
        "L shoulder\t", //5
        "L elbow\t\t", //6
        "L wrist\t\t", //7
        
        "R hip\t\t", //8
        "R knee\t\t", //9
        "R ankle\t\t", //10
        "L hip\t\t", //11
        "L knee\t\t", //12
        "L ankle\t\t", //13
    ]
    
    var connectingPointIndexs: [(Int, Int)] = [
        (0, 1), // top-neck
        
        (1, 2), // neck-rshoulder
        (2, 3), // rshoulder-relbow
        (3, 4), // relbow-rwrist
        (1, 8), // neck-rhip
        (8, 9), // rhip-rknee
        (9, 10), // rknee-rankle
        
        (1, 5), // neck-lshoulder
        (5, 6), // lshoulder-lelbow
        (6, 7), // lelbow-lwrist
        (1, 11), // neck-lhip
        (11, 12), // lhip-lknee
        (12, 13), // lknee-lankle
    ]
}
