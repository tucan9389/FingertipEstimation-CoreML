//
//  ViewController.swift
//  FingertipEstimation-CoreML
//
//  Created by GwakDoyoung on 17/08/2018.
//  Copyright © 2018 tucan9389. All rights reserved.
//

import UIKit
import Vision
import CoreMedia

class ViewController: UIViewController {
    
    public typealias BodyPoint = (point: CGPoint, confidence: Double)
    public typealias DetectObjectsCompletion = ([BodyPoint?]?, Error?) -> Void
    
    // MARK: - UI Properties
    @IBOutlet weak var videoPreview: UIView!
    //@IBOutlet weak var poseView: PoseView!
    @IBOutlet weak var drawingView: DrawingView!
    @IBOutlet weak var labelsTableView: UITableView!
    
    @IBOutlet weak var inferenceLabel: UILabel!
    @IBOutlet weak var etimeLabel: UILabel!
    @IBOutlet weak var fpsLabel: UILabel!
    
    // MARK - Inference Result Data
    private var tableData: [BodyPoint?] = []
    private var maFilter: MovingAverageFilter = MovingAverageFilter()
    
    // MARK - Performance Measurement Property
    private let 👨‍🔧 = 📏()
    
    // MARK - Core ML model
    typealias EstimationModel = mv2_cpm_model_98000
    var coremlModel: EstimationModel? = nil
    
    // MARK: - Vision Properties
    var request: VNCoreMLRequest!
    var visionModel: VNCoreMLModel! {
        didSet {
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            request.imageCropAndScaleOption = .scaleFill
        }
    }
    
    // MARK: - AV Property
    var videoCapture: VideoCapture!
    
    // MARK: - View Controller Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MobileNet 클래스는 `MobileNet.mlmodel`를 프로젝트에 넣고, 빌드시키면 자동으로 생성된 랩퍼 클래스
        // MobileNet에서 만든 model: MLModel 객체로 (Vision에서 사용할) VNCoreMLModel 객체를 생성
        // Vision은 모델의 입력 크기(이미지 크기)에 따라 자동으로 조정해 줌
        visionModel = try? VNCoreMLModel(for: EstimationModel().model)
        
        // 카메라 세팅
        setUpCamera()
        
        // 레이블 테이블 세팅
        labelsTableView.dataSource = self
        
        // 레이블 점 세팅
        //poseView.setUpOutputComponent()
        
        // 성능측정용 델리게이트 설정
        👨‍🔧.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - SetUp Video
    func setUpCamera() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        videoCapture.fps = 30
        videoCapture.setUp(sessionPreset: .vga640x480) { success in
            
            if success {
                // UI에 비디오 미리보기 뷰 넣기
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.resizePreviewLayer()
                }
                
                // 초기설정이 끝나면 라이브 비디오를 시작할 수 있음
                self.videoCapture.start()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        resizePreviewLayer()
    }
    
    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
    // MARK: - Inferencing
    func predictUsingVision(pixelBuffer: CVPixelBuffer) {
        // Vision이 입력이미지를 자동으로 크기조정을 해줄 것임.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        try? handler.perform([request])
    }
    
    // MARK: - Poseprocessing
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        self.👨‍🔧.🏷(with: "endInference")
        if let observations = request.results as? [VNCoreMLFeatureValueObservation],
            let heatmap = observations.first?.featureValue.multiArrayValue {
            
            // convert heatmap to [keypoint]
            let n_kpoints = convert(heatmap: heatmap)
            
            
            
            DispatchQueue.main.sync {
                // draw line
                if let bp = n_kpoints.first, let c: Double = bp?.confidence, c > 0.3, let p: CGPoint = bp?.point {
                    maFilter.addPoint(point: p)
                } else {
                    maFilter.addPoint(point: nil)
                }
                self.drawingView.append(p: maFilter.point)
                
                // show key points description
                self.showKeypointsDescription(with: n_kpoints)
                
                // end of measure
                self.👨‍🔧.🎬🤚()
            }
        }
    }
    
    func convert(heatmap: MLMultiArray) -> [BodyPoint?] {
        guard heatmap.shape.count >= 3 else {
            print("heatmap's shape is invalid. \(heatmap.shape)")
            return []
        }
        let keypoint_number = heatmap.shape[0].intValue
        let heatmap_w = heatmap.shape[1].intValue
        let heatmap_h = heatmap.shape[2].intValue
        
        var n_kpoints = (0..<keypoint_number).map { _ -> BodyPoint? in
            return nil
        }
        
        
        for k in 0..<keypoint_number {
            for i in 0..<heatmap_w {
                for j in 0..<heatmap_h {
                    let index = k*(heatmap_w*heatmap_h) + i*(heatmap_h) + j
                    let confidence = heatmap[index].doubleValue
                    guard confidence > 0 else { continue }
                    if n_kpoints[k] == nil ||
                        (n_kpoints[k] != nil && n_kpoints[k]!.confidence < confidence) {
                        n_kpoints[k] = (CGPoint(x: CGFloat(j), y: CGFloat(i)), confidence)
                    }
                }
            }
        }
        
        
        // transpose to (1.0, 1.0)
        n_kpoints = n_kpoints.map { kpoint -> BodyPoint? in
            if let kp = kpoint {
                return (CGPoint(x: (kp.point.x+0.5)/CGFloat(heatmap_w),
                                y: (kp.point.y+0.5)/CGFloat(heatmap_h)),
                        kp.confidence)
            } else {
                return nil
            }
        }
        
        return n_kpoints
    }
    
    func showKeypointsDescription(with n_kpoints: [BodyPoint?]) {
        self.tableData = n_kpoints
        self.labelsTableView.reloadData()
    }
}

// MARK: - VideoCaptureDelegate
extension ViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame pixelBuffer: CVPixelBuffer?, timestamp: CMTime) {
        // 카메라에서 캡쳐된 화면은 pixelBuffer에 담김.
        // Vision 프레임워크에서는 이미지 대신 pixelBuffer를 바로 사용 가능
        if let pixelBuffer = pixelBuffer {
            // start of measure
            self.👨‍🔧.🎬👏()
            
            // predict!
            self.predictUsingVision(pixelBuffer: pixelBuffer)
        }
    }
}

// MARK: - UITableView Data Source
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count// > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "LabelCell", for: indexPath)
        cell.textLabel?.text = Constant.pointLabels[indexPath.row]
        if let body_point = tableData[indexPath.row] {
            let pointText: String = "\(String(format: "%.3f", body_point.point.x)), \(String(format: "%.3f", body_point.point.y))"
            cell.detailTextLabel?.text = "(\(pointText)), [\(String(format: "%.3f", body_point.confidence))]"
        } else {
            cell.detailTextLabel?.text = "N/A"
        }
        return cell
    }
}


// MARK: - 📏(Performance Measurement) Delegate
extension ViewController: 📏Delegate {
    func updateMeasure(inferenceTime: Double, executionTime: Double, fps: Int) {
        //print(executionTime, fps)
        self.inferenceLabel.text = "inference: \(Int(inferenceTime*1000.0)) mm"
        self.etimeLabel.text = "execution: \(Int(executionTime*1000.0)) mm"
        self.fpsLabel.text = "fps: \(fps)"
    }
}


// MARK: - Constant
struct Constant {
    static let pointLabels = [
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
    
    static let connectingPointIndexs: [(Int, Int)] = [
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
    static let jointLineColor: UIColor = UIColor(displayP3Red: 87.0/255.0,
                                                 green: 255.0/255.0,
                                                 blue: 211.0/255.0,
                                                 alpha: 0.5)
    
    static let colors: [UIColor] = [
        .red,
        .green,
        .blue,
        .cyan,
        .yellow,
        .magenta,
        .orange,
        .purple,
        .brown,
        .black,
        .darkGray,
        .lightGray,
        .white,
        .gray,
        ]
}


class MovingAverageFilter {
    let maximumCount: Int = 3
    var pArray: [CGPoint?] = []
    
    func addPoint(point: CGPoint?) {
        pArray.append(point)
        if pArray.count > maximumCount {
            pArray.remove(at: 0)
        }
    }
    
    var point: CGPoint? {
        if pArray.count > 0 {
            var count: Int = 0
            var result: CGPoint = .zero
            for p in pArray {
                if let point: CGPoint = p {
                    count += 1
                    result = CGPoint(x: result.x + point.x, y: result.y + point.y)
                }
            }
            if count > 0 {
                return CGPoint(x: result.x / CGFloat(count), y: result.y / CGFloat(count))
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
}
