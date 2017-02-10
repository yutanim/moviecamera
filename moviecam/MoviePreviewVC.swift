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
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var textButton: UIButton!
    var filter:GPUImageFilter!
    var blendFilter: GPUImageAlphaBlendFilter!
    var textInput : GPUImageUIElement?
    var vi: GPUImageUIElement?
    var textField :UITextField!
    var composition = AVMutableComposition()
    let textLayer = CATextLayer()
    let overlayLayer = CALayer()
    let videoLayer = CALayer()
    var mixComp = AVMutableComposition()
    var comp = AVMutableVideoComposition()
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!
    var compositionVideoTrack: AVMutableCompositionTrack!
    
    
    class func instantiate(path: String) -> MoviePreviewViewController {
        guard let vc =  R.storyboard.moviePreviewViewController.instantiateInitialViewController() else {
            fatalError()
        }
        vc.moviePath = URL(fileURLWithPath: path, isDirectory: false)
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = moviePath else {
            return
        }
        self.compositeVideo(url: url)
        self.previewView.frame = CGRect(x: 0, y: 60, width: self.view.frame.width, height: self.view.frame.width * 4/3)
        
        NotificationCenter.default.addObserver(self, selector: #selector(MoviePreviewViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(MoviePreviewViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        self.previewView.layer.addSublayer(videoLayer)
        self.previewView.layer.addSublayer(playerLayer)
        self.previewView.layer.addSublayer(overlayLayer)
    }
    
    
    func compositeVideo(url: URL){
        let asset = AVURLAsset(url: url)
        compositionVideoTrack = mixComp.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        try! compositionVideoTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, end: asset.duration), of: videoTrack!, at: kCMTimeZero)
        
        compositionVideoTrack.preferredTransform = asset.tracks(withMediaType: AVMediaTypeVideo).flatMap{$0.preferredTransform}.first!
        
        textLayer.string = "testing"
        textLayer.fontSize = 36
        textLayer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)
        textLayer.alignmentMode = kCAAlignmentCenter
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = UIColor.cyan.cgColor
        
        textLayer.masksToBounds = true
        
        let videoLayer = CALayer()
        videoLayer.frame = CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)
        overlayLayer.frame = CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)

        overlayLayer.addSublayer(textLayer)
        
        comp.renderSize = CGSize(width: self.previewView.frame.width, height:self.previewView.frame.width * 4/3 )
        comp.frameDuration = CMTimeMake(1, 30)
        let instruction = AVMutableVideoCompositionInstruction()
        
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, end: mixComp.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        instruction.layerInstructions = [layerInstruction]
        comp.instructions = [instruction]
        

        let item = AVPlayerItem(asset: mixComp)
        NotificationCenter.default.addObserver(self, selector: #selector(MoviePreviewViewController.didItemFinish), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        item.videoComposition = comp
        player = AVPlayer(playerItem: item)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
        playerLayer.frame =  CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)

        
        player.play()

    }
    
    func didItemFinish(){
        let asset = AVURLAsset(url: moviePath!)
        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        compositionVideoTrack.removeTimeRange(CMTimeRange(start: kCMTimeZero, end: asset.duration))
        try! compositionVideoTrack.insertTimeRange(CMTimeRange(start: kCMTimeZero, end: asset.duration), of: videoTrack!, at: kCMTimeZero)
        compositionVideoTrack.preferredTransform = asset.tracks(withMediaType: AVMediaTypeVideo).flatMap{$0.preferredTransform}.first!
        
        comp.renderSize = CGSize(width: self.view.frame.width, height:self.view.frame.width * 4/3 )
        comp.frameDuration = CMTimeMake(1, 30)
        videoLayer.frame = CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: kCMTimeZero, end: mixComp.duration)
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack!)
        instruction.layerInstructions = [layerInstruction]
        comp.instructions = [instruction]
        player.seek(to: kCMTimeZero)
        player.play()

    }
    
    @IBAction func textButtonDidTouchDown(_ sender: UIButton) {
        if textLayer.isHidden {
            self.textLayer.isHidden = false
        } else {
            textLayer.isHidden = true
        }
    }
    
    @IBAction func saveButtonDidTouchUpInside(_ sender: UIButton) {
        comp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: self.previewView.layer)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:m:s"
        let videoName = dateFormatter.string(from: Date())
        let assetExport = AVAssetExportSession(asset: mixComp, presetName: AVAssetExportPreset640x480)
        assetExport?.videoComposition = comp
        
        var outputPathString = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        outputPathString?.append("/\(videoName).mp4")
        assetExport?.outputURL = URL(fileURLWithPath: outputPathString!)
        assetExport?.outputFileType = AVFileTypeMPEG4
        assetExport?.exportAsynchronously { handler -> Void in
            switch assetExport!.status {
            case AVAssetExportSessionStatus.failed:
                break
            default :
                print("export has done!")
                UISaveVideoAtPathToSavedPhotosAlbum(outputPathString!, nil, nil, nil)
                break
            }
            
        }

    }
    
    @IBAction func closeButtonDidTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playerDidFinished(_: Notification) {
        
    }

}



extension MoviePreviewViewController {
    
    func keyboardWillHide(_ notification: Notification) {
    }
    
    func keyboardWillShow(_ notification: Notification) {
       let frame = notification.userInfo?[UIKeyboardFrameBeginUserInfoKey]
    }
    
    func closeKeyboard(_ gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}
    
