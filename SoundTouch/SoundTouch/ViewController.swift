import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var recordAudio: UIButton!
    @IBOutlet weak var playAudio: UIButton!
    @IBOutlet weak var playModifyButton: UIButton!
    
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setup()
    }
    
    private func setupUI(){
        self.view.backgroundColor = UIColor(red: 0, green: 0.5, blue: 0, alpha: 1)
        recordAudio.isEnabled = false
        playAudio.isEnabled = false
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
        recordAudio.isEnabled = true
        recordAudio.addTarget(self, action: #selector(recordAudioButtonTapped), for: .touchUpInside)
        playAudio.addTarget(self, action: #selector(playAudioButtonTapped), for: .touchUpInside)
        playModifyButton.addTarget(self, action: #selector(playAudioModifyButtonTapped), for: .touchUpInside)
    }
    
    private func startRecording(){
        self.view.backgroundColor = UIColor(red: 0.5, green: 0, blue: 0, alpha: 1)
        recordAudio.setTitle("Tap to stop", for: .normal)
        
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
            
            playAudio.isEnabled = false
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
            recordAudio.setTitle("Tap to Re-record", for: .normal)
        }
        else{
            recordAudio.setTitle("Tap to Record", for: .normal)
            
            let ac = UIAlertController(title: "Record failed", message: "There was a problem; please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
        
        recordAudio.isEnabled = true
        playAudio.isEnabled = true
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
    
    @objc private func playAudioButtonTapped(){
        if (playAudio.titleLabel?.text == "Play origin"){
            do{
                playAudio.setTitle("Stop origin", for: .normal)
                recordAudio.isEnabled = false
                playModifyButton.isEnabled = false
                audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent("input.wav"))
                audioPlayer.play()
                audioPlayer.volume = 10.0
                audioPlayer.delegate = self
            }
            catch{
                recordAudio.isEnabled = true
                playModifyButton.isEnabled = true
                let ac = UIAlertController(title: "Playback failed", message: "There was a problem; please try re-recording.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
        else{
            audioPlayer.stop()
            playAudio.setTitle("Play origin", for: .normal)
            recordAudio.isEnabled = true
            playModifyButton.isEnabled = true
        }
    }
    

    @objc private func playAudioModifyButtonTapped(){
        if (playModifyButton.titleLabel?.text == "Play modify"){
            do{
                playModifyButton.setTitle("Stop modify", for: .normal)
                recordAudio.isEnabled = false
                playAudio.isEnabled = false
                //audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent("output.wav"))
                audioPlayer = try AVAudioPlayer(contentsOf: getDocumentsDirectory().appendingPathComponent("output.wav"), fileTypeHint: AVFileType.wav.rawValue)
                audioPlayer.play()
                audioPlayer.volume = 10.0
                audioPlayer.delegate = self
            }
            catch{
                recordAudio.isEnabled = true
                playAudio.isEnabled = true
                let ac = UIAlertController(title: "Playback failed", message: "There was a problem; please try re-recording.", preferredStyle: .alert)
                ac.addAction(UIAlertAction(title: "OK", style: .default))
                present(ac, animated: true)
            }
        }
        else{
            audioPlayer.stop()
            playModifyButton.setTitle("Play modify", for: .normal)
            recordAudio.isEnabled = true
            playAudio.isEnabled = true
        }
    }
    
    
    @IBAction func callVoidFunc(_ sender: UIButton) {
        //cppTestWrapper().hello_world_cpp_wrapper()
        
        //cppTestWrapper().write_file_wrapper()
        
        //cppTestWrapper().read_file_wrapper()
        
        cppTestWrapper().testLaunch_wrapper()
    }
    
    @IBAction func callIntFunc(_ sender: UIButton) {
        let result = cppTestWrapper().sum_cpp_wrapper(55, 67)
        let ac = UIAlertController(title: "Result is \(result)", message: nil, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(ac, animated: true)
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
            playAudio.setTitle("Play origin", for: .normal)
            playModifyButton.setTitle("Play modify", for: .normal)
            recordAudio.isEnabled = true
            playAudio.isEnabled = true
            
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


