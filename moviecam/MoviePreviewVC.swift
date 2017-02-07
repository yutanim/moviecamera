//
//  MoviePreviewVC.swift
//  moviecam
//
//  Created by Yuta Tanimura on 2017/02/03.
//  Copyright © 2017年 yutanim. All rights reserved.
//

import UIKit
import Rswift
import AVFoundation
import GPUImage

class MoviePreviewViewController: UIViewController {
    var moviePath: URL?
    var player : GPUImageMovie!
    @IBOutlet weak var previewView: GPUImageView!
    @IBOutlet weak var textButton: UIButton!
    var filter:GPUImageFilter!
    var blendFilter: GPUImageAlphaBlendFilter!
    var textInput : GPUImageUIElement?
    var vi: GPUImageUIElement?
    var textField :UITextField!
    
    
    
    class func instantiate(path: String) -> MoviePreviewViewController {
        guard let vc =  R.storyboard.moviePreviewViewController.instantiateInitialViewController() else {
            fatalError()
        }
        vc.moviePath = URL.init(fileURLWithPath: path, isDirectory: false)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = moviePath else {
            return
        }
        player = GPUImageMovie.init(url: url)
        filter = GPUImageBilateralFilter()
        blendFilter = GPUImageAlphaBlendFilter()
        blendFilter.mix = 1.0
        player.addTarget(filter)
        let item = AVPlayerItem(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(MoviePreviewViewController.playerDidFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:item)
        vi = GPUImageUIElement(view: UIView.init())
        player.playAtActualSpeed = true
        player.shouldRepeat = true
        filter = GPUImageFilter.init()
        player.addTarget(filter)
        filter.addTarget(blendFilter)
        vi?.addTarget(blendFilter)
        blendFilter.addTarget(previewView)
        textField = UITextField.init(frame: self.previewView.frame)
        textInput = GPUImageUIElement(view: textField)
        textInput?.addTarget(blendFilter)
        filter.frameProcessingCompletionBlock = { _ , _ in
            self.vi?.update()
            self.textInput?.update()
        }
        player.startProcessing()
    }
    
    @IBAction func textButtonDidTouchDown(_ sender: UIButton) {
        if textField?.isHidden ?? true {
            textField?.isHidden = false
            self.previewView.bringSubview(toFront: textField!)
        } else {
            textField?.isHidden = true
        }
    }
    
    
    @IBAction func closeButtonDidTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playerDidFinished(_: Notification) {
        
    }

}

