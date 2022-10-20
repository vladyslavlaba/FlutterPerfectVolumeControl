import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class SwiftPerfectVolumeControlPlugin: NSObject, FlutterPlugin {
    let volumeView = MPVolumeView();

    var channel: FlutterMethodChannel?;
    
    private var outputVolumeObserver: NSKeyValueObservation?
    
    private var lowerBound: Float = 0.0
    private var upperBound: Float = 1.0
    private var shouldKeepVolumeInBounds: Bool = false
    
    private var lastVolumeUpdate: Float? {
        didSet {
            let oldValue = oldValue
            if oldValue != lastVolumeUpdate, lastVolumeUpdate != nil, oldValue != nil {
                if oldValue! < lastVolumeUpdate! {
                    upVolumePressed()
                } else if oldValue! > lastVolumeUpdate! {
                    downVolumePressed()
                }
            }
            keepVolumeInBounds()
        }
    }

    override init() {
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftPerfectVolumeControlPlugin()
        instance.channel = FlutterMethodChannel(name: "perfect_volume_control", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "hideUI":
            self.hideUI(call, result: result);
            break;
        case "setVolumeBounds":
            self.setVolumeBounds(call, result: result);
            break;
        case "startListeningVolume":
            self.startListeningVolume(call, result: result);
            break;
        case "stopListeningVolume":
            self.stopListeningVolume(call, result: result);
            break;
        default:
            result(FlutterMethodNotImplemented);
        }

    }

//    public func getVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//        do {
//            try AVAudioSession.sharedInstance().setActive(true)
//            result(AVAudioSession.sharedInstance().outputVolume);
//        } catch let error as NSError {
//            result(FlutterError(code: String(error.code), message: "\(error.localizedDescription)", details: "\(error.localizedDescription)"));
//        }
//    }
//
//    public func setVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
//        let volume = ((call.arguments as! [String: Any])["volume"]) as! Double;
//        let fVolume = Float(volume)
//        var slider: UISlider?;
//        slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
//
//        if slider == nil {
//            result(FlutterError(code: "-1", message: "Unable to get uislider", details: "Unable to get uislider"));
//            return;
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
//            slider?.value = fVolume
//            slider?.setValue(fVolume, animated: false)
//        }
//
//        result(nil);
//    }

    public func hideUI(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let hide = ((call.arguments as! [String: Any])["hide"]) as! Bool;
        
        if hide {
            volumeView.frame = .zero
            volumeView.clipsToBounds = true
            UIApplication.shared.delegate!.window!?.rootViewController!.view.addSubview(volumeView);
        } else {
            volumeView.removeFromSuperview();
        }
        
        result(nil);
    }
    
    public func setVolumeBounds(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let shouldKeep = ((call.arguments as! [String: Any])["shouldKeep"]) as! Bool;
        let lower = ((call.arguments as! [String: Any])["lower"]) as! Double;
        let upper = ((call.arguments as! [String: Any])["upper"]) as! Double;
        
        shouldKeepVolumeInBounds = shouldKeep
        lowerBound = Float(lower)
        upperBound = Float(upper)
        
        keepVolumeInBounds()
        
        result(nil);
    }
    
    public func startListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("\(error)")
        }
        
        outputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] audioSession, _ in
            print(audioSession.currentRoute)
            self?.lastVolumeUpdate = audioSession.outputVolume
//            self?.channel?.invokeMethod("volumeChangeListener", arguments: audioSession.outputVolume)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents();
        
        result(nil);
    }
    
    public func stopListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        outputVolumeObserver = nil
        
        result(nil);
    }
    
    public func upVolumePressed() {
        channel?.invokeMethod("volumeKeyPressed", arguments: "up")
    }
    
    public func downVolumePressed() {
        channel?.invokeMethod("volumeKeyPressed", arguments: "down")
    }
    
    public func keepVolumeInBounds() {
        if !shouldKeepVolumeInBounds { return; }
        
        let volume = AVAudioSession.sharedInstance().outputVolume;
        
        if volume > upperBound { setVolume(upperBound) }
        if volume < lowerBound { setVolume(lowerBound) }
    }
    
    public func setVolume(_ volume: Float) {
        var slider: UISlider?;
        slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        if slider == nil { return; }
        
        slider?.value = volume
        slider?.setValue(volume, animated: false)
    }
}
