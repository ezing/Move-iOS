//
//  ScanCodeController.swift
//  Move App
//
//  Created by Vernon yellow on 17/2/13.
//  Copyright © 2017年 TCL Com. All rights reserved.
//

import UIKit
import AVFoundation

class ScanCodeController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        preferredStatusBarStyle = UIStatusBarStyle.LightContent
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        self.navigationController?.navigationBar.isHidden = true
        //扫描
        startScan()
    }
    
    private func startScan(){
        
        if !session.canAddInput(deviceInput)
        {
            return
        }
        
        if !session.canAddOutput(output)
        {
            return
        }
        
        session.addInput(deviceInput)
        session.addOutput(output)
        
        output.metadataObjectTypes = output.availableMetadataObjectTypes
        output.setMetadataObjectsDelegate(self, queue: DispatchQueue(label: "main"))
        
        previewLayer.frame = UIScreen.main.bounds
        view.layer.insertSublayer(previewLayer, at: 0)
        
        session.startRunning()
    }
    
    @IBAction func BackAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //会话
    private lazy var session: AVCaptureSession = AVCaptureSession()
    
    //输入设备
    private lazy var deviceInput: AVCaptureDeviceInput = {
        let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        do{
            let input = try AVCaptureDeviceInput(device: device)
            return input
        }catch{
            print(error)
            return AVCaptureDeviceInput()
        }
        
    }()
    //输出设备
    private lazy var output: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    
    //预览图层
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.session)
        return layer!
    }()
    
    @IBAction func openAbum(_ sender: AnyObject) {
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            
            let picker = UIImagePickerController()
            
            picker.delegate = self
            
            picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            picker.allowsEditing = true
            
            self.present(picker, animated: true, completion: { 
                
            })
        }
        else
            {
                print("读取相册错误")
            }
            
            
        
        
    }
    
    
   
}
extension ScanCodeController: AVCaptureMetadataOutputObjectsDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let image:UIImage!
        image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        let imageview = UIImageView()
        imageview.frame = CGRect(x: 50, y: 50, width: 100, height: 100)
        self.view .addSubview(imageview)
        imageview.image = image
        
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    
    //扫描代理方法：只要解析到数据就会调用
     func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!)
    {
        print(metadataObjects)
    }
    

}
