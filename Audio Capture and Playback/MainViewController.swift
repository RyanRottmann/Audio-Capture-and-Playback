//
//  MainViewController.swift
//  Audio Capture and Playback
//
//  Created by Ryan on 10/11/19.
//  Copyright © 2019 Ryan Rottmann. All rights reserved.
//

import UIKit
import AVFoundation


class MainViewController: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    @IBOutlet weak var playButton: UIBarButtonItem!
    @IBOutlet weak var recordButton: UIBarButtonItem!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var m4aButton: UIBarButtonItem!
    @IBOutlet weak var wavButton: UIBarButtonItem!
    
    var audioRecorder: AVAudioRecorder!
    var audioSession: AVAudioSession!
    var audioPlayer: AVAudioPlayer!
    var settings = [String: Int]()
    var fileName = "audio.caf"
    var fileURL: URL?
    var documentDirectoryURL: URL?
    var fileFormatBool: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        
        m4aButton.isEnabled = false
        recordButton.isEnabled = false
        playButton.isEnabled = false
        volumeSlider.value = 1
        label.text = "Press the record button to record audio"
        
        // set up file storage
        let fileManager = FileManager.default
        let documentDirectoryPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        documentDirectoryURL = documentDirectoryPaths[0]
        fileURL = documentDirectoryURL?.appendingPathComponent(fileName)

        // set up audio session to play and record
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [])
        } catch {// if error in setting up audio session
            print("error setting up audio session " + error.localizedDescription)
        }
        
        settings = [// audioRecorder format settings default to .m4a
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        audioSession?.requestRecordPermission() {
            [unowned self] allowed in
            if allowed {
                self.initializeAudioRecorder()
                guard let _ = self.audioSession, let _ = self.audioRecorder else {// unable to initialize audio
                    print("unable to initialize audio")
                    return
                }
                self.recordButton.isEnabled = true
            } else {// microphone access denied
                self.presentAlert(message: "microphone access denied")
            }
        }
    }// end of viewDidLoad
    
    func initializeAudioRecorder() {
        
        guard let fileURL = fileURL else {// audio file url not avalible
            print("audio file url not avalible")
            return
        }
        
        do {
            try audioRecorder = AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
        } catch {// error initializing audio recorder
            print("error initializign audio recorder")
        }
    }
    
    @IBAction func playButtonPress(_ sender: Any) {
        guard let fileURL = fileURL else {// audio file not avalible
            print("audio file not avaliable")
            return
        }
        
        guard let audioRecorder = audioRecorder, audioRecorder.isRecording == false else {// cannot play audio while recording
            print("audio is recording. cannot play audio while recording")
            return
        }
        
        if let audioPlayer = audioPlayer {
            if (audioPlayer.isPlaying) {
                audioPlayer.stop()
                playButton.image = UIImage(named: "play")
                recordButton.isEnabled = true
                label.text = "Audio Stopped"
                return
            }
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: fileURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            recordButton.isEnabled = false
            playButton.image = UIImage(named: "stop")
            
        } catch {// error playing audio
            print("error playing audio")
        }
        label.text = "Playing Audio"
        wavButton.isEnabled = false
        m4aButton.isEnabled = false
    }
    
    @IBAction func recordButtonPress(_ sender: Any) {
        if (audioRecorder?.isRecording == false) {// audio is now recording
            playButton.isEnabled = false
            recordButton.image = UIImage(named: "stop")
            audioRecorder?.record()
            label.textColor = UIColor.red
            label.text = "Recording"
            wavButton.isEnabled = false
            m4aButton.isEnabled = false
        } else {// audio is finished recording
            playButton.isEnabled = true
            recordButton.image = UIImage(named: "record")
            audioRecorder?.stop()
            label.textColor = UIColor.black
            label.text = "Recording Complete"
            if (fileFormatBool == true){
                wavButton.isEnabled = true
            } else{
                m4aButton.isEnabled = true
            }
        }
    }
    
    @IBAction func m4aButtonPress(_ sender: Any) {
        m4aButton.isEnabled = false
        wavButton.isEnabled = true
        fileFormatBool = true
        settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
    }
    
    @IBAction func wavButtonPress(_ sender: Any) {
        m4aButton.isEnabled = true
        wavButton.isEnabled = false
        fileFormatBool = false
        settings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: 1
        ]
        
    }
    
    @IBAction func volumeSliderMoved(_ sender: Any) {
        audioPlayer.volume = volumeSlider.value
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {// audio finished playing
        recordButton.isEnabled = true
        playButton.image = UIImage(named: "play")
        label.text = "Audio Finished Playing"
        if (fileFormatBool == true){
            wavButton.isEnabled = true
        } else{
            m4aButton.isEnabled = true
        }
    }

    func presentAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
