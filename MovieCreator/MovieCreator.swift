//
//  MovieCreator.swift
//  Robin
//
//  Created by 久保　玲於奈 on 2017/02/27.
//  Copyright © 2017年 uruly. All rights reserved.
//

import AVFoundation
import UIKit

class MovieCreator {
    
    //保存先のURL
    var url:URL?
    
    //フレーム数
    var frameCount = 0
    
    // FPS
    let fps: __int32_t = 60
    var time:Int = 60    // (time / fps)   VCからいじる
    
    var videoWriter:AVAssetWriter?
    var writerInput:AVAssetWriterInput?
    var adaptor:AVAssetWriterInputPixelBufferAdaptor!
    
    //適当に画像サイズ
    let imageSize = CGSize(width:1280,height:960)
    
    
    //イチバン最初はこれを呼び出す
    func createFirst(image:UIImage,size:CGSize){
        
        //保存先のURL
        url = NSURL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent("\(NSUUID().uuidString).mp4")
        // AVAssetWriter
        guard let firstVideoWriter = try? AVAssetWriter(outputURL: url!, fileType: AVFileTypeQuickTimeMovie) else {
            fatalError("AVAssetWriter error")
        }
        videoWriter = firstVideoWriter
        
        //画像サイズを変える
        let width = size.width
        let height = size.height
        
        // AVAssetWriterInput
        let outputSettings = [
            AVVideoCodecKey: AVVideoCodecH264,
            AVVideoWidthKey: width,
            AVVideoHeightKey: height
            ] as [String : Any]
        writerInput = AVAssetWriterInput(mediaType: AVMediaTypeVideo, outputSettings: outputSettings as [String : AnyObject])
        videoWriter!.add(writerInput!)
        
        // AVAssetWriterInputPixelBufferAdaptor
        adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: writerInput!,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: width,
                kCVPixelBufferHeightKey as String: height,
                ]
        )
        
        writerInput?.expectsMediaDataInRealTime = true
        
        // 動画の生成開始
        
        // 生成できるか確認
        if (!videoWriter!.startWriting()) {
            // error
            print("error videoWriter startWriting")
        }
        
        // 動画生成開始
        videoWriter!.startSession(atSourceTime: kCMTimeZero)
        
        // pixel bufferを宣言
        var buffer: CVPixelBuffer? = nil
        
        // 現在のフレームカウント
        frameCount = 0
        
        if (!adaptor.assetWriterInput.isReadyForMoreMediaData) {
            return
        }
        
        // 動画の時間を生成(その画像の表示する時間/開始時点と表示時間を渡す)
        let frameTime: CMTime = CMTimeMake(Int64(__int32_t(frameCount) * __int32_t(time)), fps)
        //時間経過を確認(確認用)
        let second = CMTimeGetSeconds(frameTime)
        print(second)
        
        //画像のリサイズと整形
        let resize = resizeImage(image: image, contentSize: imageSize)
        
        // CGImageからBufferを生成
        buffer = self.pixelBufferFromCGImage(cgImage: resize.cgImage!)
        
        // 生成したBufferを追加
        if (!adaptor.append(buffer!, withPresentationTime: frameTime)) {
            // Error!
            print("adaptError")
            print(videoWriter!.error!)
        }
        
        frameCount += 1
        
    }
    
    //２回め以降はこれを呼び出す
    func createSecond(image:UIImage){
        //videoWriterがなければ終了
        if videoWriter == nil{
            return
        }
        
        // pixel bufferを宣言
        var buffer: CVPixelBuffer? = nil
        
        if (!adaptor.assetWriterInput.isReadyForMoreMediaData) {
            return
        }
        
        // 動画の時間を生成(その画像の表示する時間/開始時点と表示時間を渡す)
        let frameTime: CMTime = CMTimeMake(Int64(__int32_t(frameCount) * __int32_t(time)), fps)
        //時間経過を確認(確認用)
        let second = CMTimeGetSeconds(frameTime)
        print(second)
        
        // CGImageからBufferを生成
        let resize = resizeImage(image: image, contentSize: imageSize)
        buffer = self.pixelBufferFromCGImage(cgImage: resize.cgImage!)
        
        // 生成したBufferを追加
        if (!adaptor.append(buffer!, withPresentationTime: frameTime)) {
            // Error!
            print(videoWriter!.error!)
        }
        
        print("frameCount :\(frameCount)")
        frameCount += 1
    }
    
    //終わったら後始末をしてURLを返す
    func finished(_ completion:@escaping (URL)->()){
        // 動画生成終了
        if writerInput != nil{
            writerInput!.markAsFinished()
            if videoWriter != nil {
                videoWriter!.endSession(atSourceTime: CMTimeMake(Int64((__int32_t(frameCount)) *  __int32_t(time)), fps))
                videoWriter!.finishWriting(completionHandler: {
                    // Finish!
                    print("movie created.")
                    self.writerInput = nil
                    if self.url != nil {
                        completion(self.url!)
                    }
                })
            }
        }
    }
    
    //ピクセルバッファへの変換
    func pixelBufferFromCGImage(cgImage: CGImage) -> CVPixelBuffer {
        
        let options = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true
        ]
        
        var pxBuffer: CVPixelBuffer? = nil
        
        let width = cgImage.width
        let height = cgImage.height
        
        CVPixelBufferCreate(kCFAllocatorDefault,
                            width,
                            height,
                            kCVPixelFormatType_32ARGB,
                            options as CFDictionary?,
                            &pxBuffer)
        
        CVPixelBufferLockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        let pxdata = CVPixelBufferGetBaseAddress(pxBuffer!)
        
        let bitsPerComponent: size_t = 8
        let bytesPerRow: size_t = 4 * width
        
        let rgbColorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata,
                                width: width,
                                height: height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: rgbColorSpace,
                                bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.draw(cgImage, in: CGRect(x:0, y:0, width:CGFloat(width),height:CGFloat(height)))
        
        CVPixelBufferUnlockBaseAddress(pxBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pxBuffer!
    }
    
    
    //リサイズが必要なら
    func resizeImage(image:UIImage,contentSize:CGSize) -> UIImage{
        // リサイズ処理
        let origWidth  = Int(image.size.width)
        let origHeight = Int(image.size.height)
        var resizeWidth:Int = 0, resizeHeight:Int = 0
        if (origWidth < origHeight) {
            resizeWidth = Int(contentSize.width)
            resizeHeight = origHeight * resizeWidth / origWidth
        } else {
            resizeHeight = Int(contentSize.height)
            resizeWidth = origWidth * resizeHeight / origHeight
        }
        
        let resizeSize = CGSize(width:CGFloat(resizeWidth), height:CGFloat(resizeHeight))
        UIGraphicsBeginImageContext(resizeSize)
        
        image.draw(in: CGRect(x:0,y: 0,width: CGFloat(resizeWidth), height:CGFloat(resizeHeight)))
        
        let resizeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // 切り抜き処理
        
        let cropRect  = CGRect(
            x:CGFloat((resizeWidth - Int(contentSize.width)) / 2),
            y:CGFloat((resizeHeight - Int(contentSize.height)) / 2),
            width:contentSize.width, height:contentSize.height)
        let cropRef   = (resizeImage?.cgImage)!.cropping(to: cropRect)
        let cropImage = UIImage(cgImage: cropRef!)
        
        return cropImage
    }
    
}
