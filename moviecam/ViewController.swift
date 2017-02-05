//
//  ViewController.swift
//  moviecam
//
//  Created by Yuta Tanimura on 2017/02/03.
//  Copyright © 2017年 yutanim. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {
    
    var camera:GPUImageVideoCamera?
    var filter:GPUImageFilter?
    
    var vm =  FilterCollectionViewModel()
    var movieWriter: GPUImageMovieWriter?
    var videoPath: String?
    @IBOutlet weak var filterCollectionView: UICollectionView!
    @IBOutlet weak var imageView: GPUImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        camera = GPUImageVideoCamera.init(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: .back)
        camera?.outputImageOrientation = .portrait
        camera?.horizontallyMirrorRearFacingCamera = false
        camera?.horizontallyMirrorFrontFacingCamera = false
        filter = GPUImageFilter.init()
        camera?.addTarget(filter)
        filter?.addTarget(imageView as GPUImageView)
        camera?.startCapture()
    }
    
    func updateFilter(_ f: GPUImageFilter?) {
        filter?.removeAllTargets()
        camera?.removeAllTargets()
        self.filter = f
        camera?.addTarget(f)
        f?.addTarget(imageView as GPUImageView)
    }
    
    func initMovieWriter() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd h:m:s"
        let videoName = dateFormatter.string(from: Date())
        
        videoPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
        videoPath?.append("/\(videoName).mp4")
        
        let movieURL = URL(fileURLWithPath: videoPath!)
        
        movieWriter = GPUImageMovieWriter(movieURL: movieURL, size: CGSize(width: self.imageView.frame.width, height: self.imageView.frame.height))
        movieWriter?.encodingLiveVideo = true
        filter?.addTarget(movieWriter)
        camera?.audioEncodingTarget = movieWriter
        movieWriter?.shouldPassthroughAudio = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func captureStart() {
        if movieWriter == nil {
            initMovieWriter()
            movieWriter?.startRecording()
        } else {
            movieWriter?.finishRecording()
            filter?.removeTarget(movieWriter)
            let vc = MoviePreviewViewController.instantiate(path: videoPath!)
            self.present(vc, animated: true, completion: nil)
            movieWriter = nil
        }
        
        
    }
    @IBAction func CaptureButtonDidTouchUpInside(_ sender: UIButton) {
        self.captureStart()
    }
}

extension ViewController : UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(vm.filters.filterCount())
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = filterCollectionView.dequeueReusableCell(withReuseIdentifier: "FilterCell", for: indexPath) as! FilterCell
        cell.filter = vm.filters.filter(at: UInt(indexPath.row))
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.updateFilter(vm.filters.filter(at: UInt(indexPath.row)) as? GPUImageFilter)
        
    }
}





class FilterCollectionViewModel {
    var filters : GPUImageFilterGroup
    
    init() {
        let group = GPUImageFilterGroup.init()
        group.addFilter(GPUImageSepiaFilter())
        group.addFilter(GPUImageHueFilter())
        group.addFilter(GPUImageToonFilter())
        group.addFilter(GPUImageGammaFilter())
        group.addFilter(GPUImageErosionFilter())
        group.addFilter(GPUImageSharpenFilter())
        group.addFilter(GPUImagePolkaDotFilter())
        self.filters = group
    }

}

class FilterCell: UICollectionViewCell {
    @IBOutlet weak var image: UIImageView!
    let i = GPUImagePicture.init(image:  R.image.linusJpg())
    var filter: GPUImageOutput? {
        didSet {
            self.i?.addTarget(filter as! GPUImageInput!)
            filter?.useNextFrameForImageCapture()
            i?.processImage()
            let filterdImage = filter?.imageFromCurrentFramebuffer()
            self.image.image = filterdImage
//            UIImage(name: "linus.jpg")
//            self.image.image =
        }
    }
    
    override func awakeFromNib() {
    }
}
