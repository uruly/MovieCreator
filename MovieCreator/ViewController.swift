//
//  ViewController.swift
//  MovieCreator
//
//  Created by 久保　玲於奈 on 2017/09/04.
//  Copyright © 2017年 Reona Kubo. All rights reserved.
//

//- ボタンを用意し、それを押した時点で画像を動画につぎ足す

import UIKit
import MediaPlayer
import AVKit

class ViewController: UIViewController {
    
    let movieCreator = MovieCreator()
    
    //動画を表示するやつ
    var avPlayerVC:AVPlayerViewController!
    
    //１枚めの画像かどうか
    var isFirstTap = true
    
    //画像のサイズ
    let imageSize = CGSize(width:1280,height:960)
    
    //ラベル
    var timeLabel:UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let width = self.view.frame.width
        let height = self.view.frame.height
        
        let btnWidth = width / 4
        let btnHeight = btnWidth
        
        
        //動画を表示するビュー
        avPlayerVC = AVPlayerViewController()
        avPlayerVC.view.frame = CGRect(x:0,y:0,width:imageSize.width / 4,height:imageSize.height / 4)
        avPlayerVC.view.center = CGPoint(x:width / 2,y:height / 4)
        avPlayerVC.view.backgroundColor = UIColor.gray
        self.addChildViewController(avPlayerVC)
        self.view.addSubview(avPlayerVC.view)
        
        /***  １枚の画像を表示する時間を決める time / 60 **/
        //timeをいじるスライダー time / 60
        let slider = UISlider(frame: CGRect(x:0,y:0,width:200,height:50))
        slider.center = CGPoint(x:width / 2,y:height / 2 + 25)
        slider.minimumValue = 1
        slider.maximumValue = 60
        slider.value = 60
        slider.addTarget(self, action: #selector(sliderValueChanged(sender:)), for: .valueChanged)
        self.view.addSubview(slider)
        
        //timeを表示するラベル
        timeLabel = UILabel(frame:CGRect(x:0,y:0,width:200,height:50))
        timeLabel.center = CGPoint(x:width / 2,y:height / 2)
        timeLabel.text = "１枚の表示時間\(Int(slider.value)) / 60秒"
        timeLabel.font = UIFont.systemFont(ofSize: 14)
        timeLabel.textAlignment = .center
        self.view.addSubview(timeLabel)
        
        
        //説明ラベル
        let imgLabel = UILabel(frame:CGRect(x:10,y:slider.frame.maxY,width:width - 20,height:50))
        imgLabel.text = "タップした画像を繋ぎ合わせて動画を生成します。"
        imgLabel.textAlignment = .center
        imgLabel.font = UIFont.systemFont(ofSize: 14)
        self.view.addSubview(imgLabel)
        
        //画像を選択するボタン
        for x in 0 ..< 4{
            let button = UIButton()
            button.frame = CGRect(x:btnWidth * CGFloat(x),y:imgLabel.frame.maxY,width:btnWidth,height:btnHeight)
            //button.setImage(UIImage(named:"Sprite-000\(tag).png"), for: .normal)
            button.setImage(UIImage(named:"cat\(x + 1).jpg"),for:.normal)
            button.imageView?.contentMode = .scaleAspectFill
            button.addTarget(self, action: #selector(self.btnTapped(sender:)), for: .touchUpInside)
            button.tag = x
            self.view.addSubview(button)
        }
        
        //createボタン
        let createBtn = UIButton()
        createBtn.frame = CGRect(x:0,y:0,width:width,height: 50)
        createBtn.center = CGPoint(x:width / 2,y:height - 25)
        createBtn.backgroundColor = UIColor.brown
        createBtn.setTitle("動画を生成", for: .normal)
        createBtn.addTarget(self,action:#selector(self.createBtnTapped),for:.touchUpInside)
        self.view.addSubview(createBtn)
        
    }
    
    
    //ボタンを押した時の処理 ボタンの画像を押すたびに動画に継ぎ足し
    @objc func btnTapped(sender:UIButton){
        //ボタンの画像があるかをチェック
        if let image = sender.imageView?.image{
            //１枚目の画像だけセットアップを含む
            if isFirstTap {
                movieCreator.createFirst(image: image, size: CGSize(width:image.size.width,
                                                                    height:image.size.height))
                isFirstTap = false
            }else{
                movieCreator.createSecond(image: image)
            }

        }
        
    }
    
    //動画を生成する
    @objc func createBtnTapped(){
        //動画生成終了を呼び出してURLを得る -> Playerにのせる
        movieCreator.finished { (url) in
            DispatchQueue.main.async{
                let avPlayer = AVPlayer(url:url)
                self.avPlayerVC.player = avPlayer
                avPlayer.play()
            }
        }
        isFirstTap = true
    }
    
    //スライダーの値が変わったとき
    @objc func sliderValueChanged(sender:UISlider){
        movieCreator.time = Int(sender.value)
        timeLabel.text = "１枚の表示時間\(Int(sender.value)) / 60秒"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

