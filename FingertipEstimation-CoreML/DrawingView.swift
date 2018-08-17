//
//  DrawingView.swift
//  FingerEstimation-CoreML
//
//  Created by GwakDoyoung on 03/08/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit

class DrawingView: UIView {

    let maxDataCount: Int = 28
    var data: [CGPoint?] = [] {
        didSet {
            setNeedsDisplay()
        }
    }
    
    public func append(p: CGPoint?) {
        data.append(p)
        if data.count > maxDataCount {
            data.remove(at: 0)
        }
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        
//        let pointsArray: [[(CGPoint, CGFloat)]] = splitPoints(ps: data)
//        for points in pointsArray {
//            let path = straightPath(points: points)
//
//            UIColor.black.setStroke()
//            path.lineWidth = 1
//            path.stroke()
//        }
        
        guard data.count != 0 else { return }
        if data.count == 1, let p = data.first as? CGPoint {
            drawPoint(point: p, color: UIColor.red, radius: 3)
            return
        }
        
        var lastDotIndex: Int = -1
        let alpha: ((Int, Int, CGFloat) -> CGFloat) = { i, count, maxAlpha in
            let result: CGFloat = CGFloat(i+1) * ((maxAlpha * 1.5) / CGFloat(count))
            return result > maxAlpha ? maxAlpha : result
        }
        for i in 0..<data.count-1 {
            if let p1: CGPoint = data[i],
                let p2: CGPoint = data[i+1] {
                let point1: CGPoint = p1.convert(to: bounds.size)
                let point2: CGPoint = p2.convert(to: bounds.size)
                if i != lastDotIndex {
                    drawPoint(point: point1,
                              color: UIColor(red: 1.0, green: 0.2, blue: 0.2,
                                             alpha: alpha(i, data.count, 1.0)),
                              radius: 3)
                }
                drawPoint(point: point2,
                          color: UIColor(red: 1.0, green: 0.2, blue: 0.2,
                                         alpha: alpha(i+1, data.count, 1.0)),
                          radius: 3)
                lastDotIndex = i+1
                
                
                let path = straightPath(points: [p1, p2])
                UIColor(red: 1.0, green: 0, blue: 0,
                        alpha: alpha(i, data.count, 0.5)).setStroke()
                path.lineWidth = 2.0
                path.stroke()
            }
            
        }
    }
    
    func splitPoints(ps: [CGPoint?]) -> [[(CGPoint, CGFloat)]] {
        
        var pointsArray: [[(CGPoint, CGFloat)]] = [[]]
        for optionalPoint in ps {
            if let p: CGPoint = optionalPoint {
                pointsArray[pointsArray.count - 1].append((p, 0.3))
            } else {
                if let points: [(CGPoint, CGFloat)] = pointsArray.last {
                    if points.count > 0 {
                        pointsArray.append([])
                    }
                }
            }
        }
        
        return pointsArray
    }
    
    func straightPath(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        guard points.count > 0 else { return path }
        
        let p1: CGPoint = points[0].convert(to: bounds.size)
        path.move(to: p1)
        
        if points.count > 1 {
            for p in points {
                let convertedPoint: CGPoint = p.convert(to: bounds.size)
                path.addLine(to: convertedPoint)
            }
        }
        
        return path
    }
    
    
    func drawPoint(point: CGPoint, color: UIColor, radius: CGFloat) {
        let ovalPath = UIBezierPath(ovalIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
        color.setFill()
        ovalPath.fill()
    }

}

extension CGPoint {
    func convert(to size: CGSize) -> CGPoint {
        return CGPoint(x: x * size.width, y: y * size.height)
    }
}
