//
//  ViewController.swift
//  VideoRecorder
//
//  Created by Paul Solt on 10/2/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
        
		
		
		
	}
    
    private func requestPermissionAndShowCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            showCamera()
        case .denied:
            // Take the user to the settings app (or show a custom onboarding screen explaining why we need camera access
            fatalError("Camera permission denied")
        case .notDetermined:

            AVCaptureDevice.requestAccess(for: .video) { granted in
                guard granted else {
                    fatalError("Camera permission denied")
                }
                DispatchQueue.main.async {
                    self.showCamera()
                }
            }
        case .restricted:
            // Parental Controls (Inform the user they don't have access. Maybe ask the parent?)
            fatalError("Camera permission restricted")
        @unknown default:
            fatalError("Unexpected enum value that isn't being handled")
        }
    }
	
	private func showCamera() {
		performSegue(withIdentifier: "ShowCamera", sender: self)
	}
}
