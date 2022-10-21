import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class SwiftPerfectVolumeControlPlugin: NSObject, FlutterPlugin {
    let volumeView = MPVolumeView();

    var channel: FlutterMethodChannel?;
    
    private var outputVolumeObserver: NSKeyValueObservation?
    
    private(set) lazy var originalVolume: Float = {
        return AVAudioSession.sharedInstance().outputVolume
    }()
    
    private var lowerBound: Float = 0.0
    private var upperBound: Float = 1.0
    private var shouldKeepVolume: Bool = false

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
        
        shouldKeepVolume = shouldKeep
        lowerBound = Float(lower)
        upperBound = Float(upper)
        
        if originalVolume > upperBound { originalVolume = upperBound }
        if originalVolume < lowerBound { originalVolume = lowerBound }
        
        keepVolume()
        
        result(nil);
    }
    
    public func startListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("\(error)")
        }
        
        outputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] audioSession, _ in
            self?.handleVolumeChange(audioSession.outputVolume)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents();
        
        result(nil);
    }
    
    public func stopListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        outputVolumeObserver = nil
        
        result(nil);
    }
    
    public func handleVolumeChange(_ volume: Float) {
        keepVolume()
        if volume == originalVolume { return; }
        
        if originalVolume < volume {
            upVolumePressed()
        } else if originalVolume > volume {
            downVolumePressed()
        }
    }
    
    public func upVolumePressed() {
        channel?.invokeMethod("volumeKeyPressed", arguments: "up")
    }
    
    public func downVolumePressed() {
        channel?.invokeMethod("volumeKeyPressed", arguments: "down")
    }
    
    public func keepVolume() {
        if !shouldKeepVolume { return; }
        
        let volume = AVAudioSession.sharedInstance().outputVolume;
        var newVolume = originalVolume;
        
        if volume != originalVolume {
            newVolume = originalVolume
        }
        
        if newVolume > upperBound { newVolume = upperBound }
        if newVolume < lowerBound { newVolume = lowerBound }
        
        setVolume(newVolume)
    }
    
    public func setVolume(_ volume: Float) {
        var slider: UISlider?;
        volumeView.subviews.forEach({ print($0) })
        slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        if slider == nil { return; }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
            slider?.setValue(volume, animated: false)
        }
    }
}
