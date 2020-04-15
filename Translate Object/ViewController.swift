//
//  ViewController.swift
//  Translate Object
//
//  Created by Timothy Lee Long on 3/16/20.
//  Copyright © 2020 Timothy Lee Long. All rights reserved.
//

import UIKit
import AVKit
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var belowView: UIView!
    @IBOutlet weak var objectNameLabel: UILabel!
    @IBOutlet weak var accuracyLabel: UILabel!
    @IBOutlet weak var languagePickerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var languagePicker: UIPickerView!
    @IBOutlet weak var languageSelectorButton: UIButton!
    @IBOutlet weak var translatedText: UILabel!
    
    var model = Resnet50().model
    
    let languages = ["Spanish", "French", "Italian", "German", "Japanese", "Russian", "Arabic", "Hebrew", "Korean", "Latin", "Dutch"]
    let languageCodes = ["es", "fr", "it", "de", "ja", "ru", "ar", "he", "ko", "la", "nl"]
    
    var pickerVisible: Bool = false
    var targetCode = "es"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        configureLanguagePicker()
        
        
        //camera
        let captureSession = AVCaptureSession()
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        // The camera is now created!
        
        view.addSubview(belowView)
        
        belowView.clipsToBounds = true
        belowView.layer.cornerRadius = 15.0
        belowView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        
        let  dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
        
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        guard let model = try? VNCoreMLModel(for: model) else { return }
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else {return}
            guard let firstObservation = results.first else {return}
            
            let name: String = firstObservation.identifier
            let acc: Int = Int(firstObservation.confidence * 100)
            
            DispatchQueue.main.async {
                self.objectNameLabel.text = name
                self.accuracyLabel.text = "Accuracy: \(acc)%"
                self.translateText(detectedText: name)
            }
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Configuration
    func configureLanguagePicker() {
        languagePicker.dataSource = (self as UIPickerViewDataSource)
        languagePicker.delegate = (self as UIPickerViewDelegate)
    }
    
    
}

// MARK :- UIPickerViewDelegate
extension ViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return languages.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return languages[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        languageSelectorButton.setTitle(languages[row], for: .normal)
        targetCode = languageCodes[row]
    }
}

// MARK: - IBActions
extension ViewController {
    
    @IBAction func languageSelectorTapped(_ sender: Any) {
        
        if pickerVisible {
            languagePickerHeightConstraint.constant = 0
            pickerVisible = false
            translateText(detectedText: self.objectNameLabel.text ?? "")
        } else {
            languagePickerHeightConstraint.constant = 150
            pickerVisible = true
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutSubviews()
            self.view.updateConstraints()
        }
    }
    
}

// MARK: - Methods
extension ViewController {
    
    func translateText(detectedText: String) {
        
        guard !detectedText.isEmpty else {
            return
        }
        
        let task = try? GoogleTranslate.sharedInstance.translateTextTask(text: detectedText, targetLanguage: self.targetCode, completionHandler: { (translatedText: String?, error: Error?) in
            debugPrint(error?.localizedDescription as Any)
            
            DispatchQueue.main.async {
                self.translatedText.text = translatedText
            }
            
        })
        task?.resume()
    }
}
