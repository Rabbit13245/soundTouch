import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var recordAudioButton: UIButton!
    @IBOutlet weak var playOriginAudioButton: UIButton!
    @IBOutlet weak var playModifyAudioButton: UIButton!
    @IBOutlet weak var processAudioButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    var wasModified: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setup()
    }
    
    private func setupUI(){
        self.view.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        recordAudioButton.isEnabled = false
        playOriginAudioButton.isEnabled = false
        playModifyAudioButton.isEnabled = false
        processAudioButton.isEnabled = false
    }
    
    private func setup(){
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowAirPlay, .allowBluetoothA2DP])
            try recordingSession.setActive(true)
            
            recordingSession.requestRecordPermission(){ [unowned self] allowed in
                DispatchQueue.main.async(){
                    if (allowed){
                        self.loadRecordingUI()
                    }
                    else{
                        let ac = UIAlertController(title: "Error", message: "Audio access is denied", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                        self.present(ac, animated: true)
                    }
                }
            }
        }
        catch {
            print("setup:: error: \(error.localizedDescription)")
        }
    }
    
    private func loadRecordingUI(){
        recordAudioButton.isEnabled = true
        recordAudioButton.addTarget(self, action: #selector(recordAudioButtonTapped), for: .touchUpInside)
        playOriginAudioButton.addTarget(self, action: #selector(playOriginAudioButtonTapped), for: .touchUpInside)
        playModifyAudioButton.addTarget(self, action: #selector(playModifyAudioButtonTapped), for: .touchUpInside)
        processAudioButton.addTarget(self, action: #selector(processRecordedAudio), for: .touchUpInside)
    }
    
    private func startRecording(){
        self.view.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        recordAudioButton.setTitle("Tap to stop", for: .normal)
        wasModified = false
        let audioFilename = getDocumentsDirectory().appendingPathComponent("input.wav")
        let audioSettings = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        
        do{
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: audioSettings)
            audioRecorder.delegate = self
            audioRecorder.record()
            
            playOriginAudioButton.isEnabled = false
            playModifyAudioButton.isEnabled = false
            processAudioButton.isEnabled = false
        }
        catch{
            print("startRecording:: error: \(error.localizedDescription)")
            finishRecording(success: false)
        }
    }
    
    private func finishRecording(success: Bool){
        self.view.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        
        audioRecorder.stop()
        audioRecorder = nil
        if (success){
            recordAudioButton.setTitle("Tap to Re-record", for: .normal)
            
            playOriginAudioButton.isEnabled = true
            processAudioButton.isEnabled = true
        }
        else{
            recordAudioButton.setTitle("Tap to Record", for: .normal)
            
            let ac = UIAlertController(title: "Record failed", message: "There was a problem; please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        recordAudioButton.isEnabled = true
    }
    
    private func getDocumentsDirectory() -> URL{
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc private func recordAudioButtonTapped(){
        if (audioRecorder == nil){
            startRecording()
        }
        else{
            finishRecording(success: true)
        }
    }
    
    @objc private func playOriginAudioButtonTapped(){
        if (playOriginAudioButton.titleLabel?.text == "Play origin"){
            do{
                playOriginAudioButton.setTitle("Stop origin", for: .normal)
                recordAudioButton.isEnabled = false
                playModifyAudioButton.isEnabled = false
                processAudioButton.isEnabled = false
                
                audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent("input.wav"))
                audioPlayer.play()
                audioPlayer.volume = 10.0
                audioPlayer.delegate = self
            }
            catch{
                recordAudioButton.isEnabled = true
                playModifyAudioButton.isEnabled = true
                processAudioButton.isEnabled = wasModified
                let ac = UIAlertController(title: "Playback failed", message: "There was a problem; please try re-recording.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
        else{
            audioPlayer.stop()
            playOriginAudioButton.setTitle("Play origin", for: .normal)
            
            recordAudioButton.isEnabled = true
            playModifyAudioButton.isEnabled = wasModified
            processAudioButton.isEnabled = true
        }
    }
    

    @objc private func playModifyAudioButtonTapped(){
        if (playModifyAudioButton.titleLabel?.text == "Play modify"){
            do{
                playModifyAudioButton.setTitle("Stop modify", for: .normal)
                recordAudioButton.isEnabled = false
                playOriginAudioButton.isEnabled = false
                processAudioButton.isEnabled = false
                
                audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent("output.wav"), fileTypeHint: AVFileType.wav.rawValue)
                audioPlayer.play()
                audioPlayer.volume = 10.0
                audioPlayer.delegate = self
            }
            catch{
                recordAudioButton.isEnabled = true
                playOriginAudioButton.isEnabled = true
                processAudioButton.isEnabled = wasModified
                
                let ac = UIAlertController(title: "Playback failed", message: "There was a problem; please try re-recording.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
        else{
            audioPlayer.stop()
            playModifyAudioButton.setTitle("Play modify", for: .normal)
            recordAudioButton.isEnabled = true
            playOriginAudioButton.isEnabled = wasModified
            processAudioButton.isEnabled = true
        }
    }
    
    @objc private func processRecordedAudio(){
        recordAudioButton.isEnabled = false
        playOriginAudioButton.isEnabled = false
        playModifyAudioButton.isEnabled = false
        processAudioButton.isEnabled = false
        
        cppTestWrapper().testLaunch_wrapper()
        
        wasModified = true
        
        recordAudioButton.isEnabled = true
        playOriginAudioButton.isEnabled = true
        playModifyAudioButton.isEnabled = wasModified
        processAudioButton.isEnabled = true
    }
}

extension ViewController: AVAudioRecorderDelegate{
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if (!flag){
            finishRecording(success: false)
        }
    }
}

extension ViewController: AVAudioPlayerDelegate{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if(flag){
            playOriginAudioButton.setTitle("Play origin", for: .normal)
            playModifyAudioButton.setTitle("Play modify", for: .normal)
            
            recordAudioButton.isEnabled = true
            playOriginAudioButton.isEnabled = true
            playModifyAudioButton.isEnabled = wasModified
            processAudioButton.isEnabled = true
        }
        else{
            let ac = UIAlertController(title: "Playback failed", message: "There was a problem; please try re-recording.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        print("FFF")
        print(error?.localizedDescription)
    }
}


