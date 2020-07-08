//
//  CameraViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {

    @IBOutlet var recordButton: UIButton!
    @IBOutlet var cameraView: CameraPreviewView!

    var captureSession = AVCaptureSession()

    var fileOutPut = AVCaptureMovieFileOutput()
    
    private var player: AVPlayer?
    private var playerView: VideoPlayerView!

	override func viewDidLoad() {
		super.viewDidLoad()

		// Resize camera preview to fill the entire screen
		cameraView.videoPlayerView.videoGravity = .resizeAspectFill
        setUpCaptureSession()
	}
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession.startRunning()
    }
    
    func setUpCaptureSession() {
        // Let the capture session know we are going to be changing its settings (inputs, outputs)
        captureSession.beginConfiguration()
        
        // Camera
        let camera = bestCamera()
        
        guard let cameraInput = try? AVCaptureDeviceInput(device: camera),
            captureSession.canAddInput(cameraInput) else {
                // Future: Display the error that gets thrown so you understand why it doesn't work
                fatalError("Cannot create camera input")
        }
        
        captureSession.addInput(cameraInput)
        
        // Microphone
        let microphone = bestAudio()
        
        guard let audioInput = try? AVCaptureDeviceInput(device: microphone),
            captureSession.canAddInput(audioInput) else {
                fatalError("Can't create and add input for microphone")
        }
        
        captureSession.addInput(audioInput)
        
        // Quality Level
        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
        } else {
            fatalError("1920X1080 preset is unavailable")
        }
        
        // Output(s)
        guard captureSession.canAddOutput(fileOutPut) else {
            fatalError("Cannot add the movie recording output")
        }
        
        captureSession.addOutput(fileOutPut)
        
        // Begin to use the settings that we've configured above
        captureSession.commitConfiguration()
        
        // Give the camera view the session so it can show the camera preview to the user
        cameraView.session = captureSession
        
    }
    
    private func bestCamera() -> AVCaptureDevice {
        // Choose the ideal camera available for the device
        // FUTURE: we could add a button to let the user choose front/back camera
        if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
            return ultraWideCamera
        }
        
        if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideAngleCamera
        }
        
        fatalError("No camera available. Are you on a simulator?")
    }
    
    private func bestAudio() -> AVCaptureDevice {
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            return audioDevice
        }
        
        fatalError("No audio capture device present")
    }

    @IBAction func recordButtonPressed(_ sender: Any) {
        toggleRecording()
	}
    
    private func updateViews() {
        recordButton.isSelected = fileOutPut.isRecording
    }
    
    private func playMovie(at url: URL) {
        let player = AVPlayer(url: url)
        
        if playerView == nil {
            // Set up the player view the first time
            let playerView = VideoPlayerView()
            
            // Customize the frame
            
            var frame = view.bounds
            
            frame.size.height /= 4
            frame.size.width /= 4
            
            frame.origin.y = view.directionalLayoutMargins.top
            
            playerView.frame = frame
            
            view.addSubview(playerView)
            self.playerView = playerView
        }
        
        playerView.player = player
        player.play()
        // Make sure the player sticks around as long as needed
        self.player = player
    }
    
    private func toggleRecording() {
        if fileOutPut.isRecording {
            // Stop the recording
            fileOutPut.stopRecording()
            updateViews()
        } else {
            fileOutPut.startRecording(to: newRecordingURL(), recordingDelegate: self)
            updateViews()
        }
    }
	
	/// Creates a new file URL in the documents directory
	private func newRecordingURL() -> URL {
		let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime]

		let name = formatter.string(from: Date())
		let fileURL = documentsDirectory.appendingPathComponent(name).appendingPathExtension("mov")
		return fileURL
	}
}

extension CameraViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        print("Started recording at: \(fileURL)")
        updateViews()
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        updateViews()
        if let error = error {
            NSLog("Error saving movie: \(error)")
        }
        
        DispatchQueue.main.async {
            self.playMovie(at: outputFileURL)
        }
    }
}
