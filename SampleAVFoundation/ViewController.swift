//
//  ViewController.swift
//  SampleAVFoundation
//
//  Created by 岩本康孝 on 2022/12/06.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var previewView: UIView!

    // inputsとoutputsの仲介役を行なっているのがAVCaptureSession
    private var captureSession = AVCaptureSession()

    // inputs: カメラやマイクなどデバイスからデータを取得する方法
    private var captureDeviceInput: AVCaptureDeviceInput!
    private var currentDevice: AVCaptureDevice?

    // outputs: 出力形式。入力されたデータをどのように出力するか
    private let photoOutput = AVCapturePhotoOutput()
    private var cameraPreviewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupDevice()
        setupInputOutput()
        setupPreviewLayer()
        captureSession.startRunning()
    }

    func setupDevice() {
        // デバイスの設定
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        self.currentDevice = deviceDiscoverySession.devices.first
    }

    func setupInputOutput() {
        do {
            // 入力(カメラ)と出力(画像)の設定
            guard let currentDevice = self.currentDevice else { return }
            self.captureDeviceInput = try AVCaptureDeviceInput(device: currentDevice)
            self.captureSession.addInput(self.captureDeviceInput)

            // 出力ファイルのフォーマットをjpegに指定する
            self.photoOutput.setPreparedPhotoSettingsArray(
                [AVCapturePhotoSettings(
                    format: [AVVideoCodecKey: AVVideoCodecType.jpeg]
                )]
            )

            //
            self.captureSession.addOutput(self.photoOutput)
        } catch {
            fatalError("\(error)")
        }
    }

    func setupPreviewLayer() {
        // previewの設定
        self.cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        self.captureSession.sessionPreset = .photo
        // videoGravity: カメラのプレビューをどこまで広げるか
        self.cameraPreviewLayer.videoGravity = .resizeAspectFill
//        self.cameraPreviewLayer.connection?.videoOrientation = .portrait
        DispatchQueue.main.async {
            self.cameraPreviewLayer.frame = self.previewView.bounds
            self.previewView.layer.addSublayer(self.cameraPreviewLayer)
        }
    }

    @IBAction func tappedTakePicture(_ sender: Any) {
        // 写真撮影の設定周り
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        self.photoOutput.capturePhoto(with: settings, delegate: self)
    }

    @IBAction func changeOutputPosition(_ sender: Any) {
        // 一旦previewを止める
        self.captureSession.stopRunning()

        // inputs, outputsをリセット
        self.captureSession.inputs.forEach { input in
            self.captureSession.removeInput(input)
        }
        self.captureSession.outputs.forEach { output in
            self.captureSession.removeOutput(output)
        }

        // prepare new camera preview
        let newCameraPosition: AVCaptureDevice.Position = self.currentDevice?.position == .front ? .back : .front
        self.setupCaptureSession(withPosition: newCameraPosition)

        let newVideoLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        newVideoLayer.frame = previewView.bounds
        newVideoLayer.videoGravity = .resizeAspectFill

        // horizontal flip
//        UIView.transition(with: self.view, duration: 0.3, options: [.transitionFlipFromLeft], animations: nil, completion: { _ in
            // replace camera preview with new one
        DispatchQueue.main.async {
            self.setupPreviewLayer()
            self.captureSession.startRunning()
        }
//        })
    }

    func setupCaptureSession(withPosition cameraPosition: AVCaptureDevice.Position) {
        self.currentDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: cameraPosition)
        self.captureSession = AVCaptureSession()

        // add video input to a capture session
        let videoInput = try! AVCaptureDeviceInput(device: self.currentDevice!)
        self.captureSession.addInput(videoInput)

        // add capture output
        let captureOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
        self.captureSession.addOutput(captureOutput)

        self.captureSession.startRunning()
    }
}

extension ViewController: AVCapturePhotoCaptureDelegate {
    // 写真が撮影される直前に呼ばれる
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1036)
    }

    // 写真のProcessingが終わった後
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        // data型に変更
        print(output)
        let imageData = photo.fileDataRepresentation()
        // 型変換
        guard let photo = UIImage(data: imageData!) else { return }
        //写真 ライブラリに画像を保存
        UIImageWriteToSavedPhotosAlbum(photo, self, nil, nil)
    }
}
