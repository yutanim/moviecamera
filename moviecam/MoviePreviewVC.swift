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

class MoviePreviewViewController: UIViewController {
    var moviePath: URL?
    var player : AVPlayer?
    @IBOutlet weak var previewView: UIView!
    
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
        let item = AVPlayerItem(url: url)
        NotificationCenter.default.addObserver(self, selector: #selector(MoviePreviewViewController.playerDidFinished), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object:item)
        player = AVPlayer(playerItem: item)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = CGRect(x: 0, y: 0, width: self.previewView.frame.width, height: self.previewView.frame.height)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        self.previewView.layer.addSublayer(playerLayer)
        self.player?.play()
    }
    
    @IBAction func closeButtonDidTouchUpInside(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func playerDidFinished(_: Notification) {
        self.player?.play()
    }

}

