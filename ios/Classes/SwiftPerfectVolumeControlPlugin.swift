import Flutter
import UIKit
import MediaPlayer
import AVFoundation

public class SwiftPerfectVolumeControlPlugin: NSObject, FlutterPlugin {
    let volumeView = MPVolumeView();

    var channel: FlutterMethodChannel?;
    
    private var outputVolumeObserver: NSKeyValueObservation?

    override init() {
        super.init();
    }

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SwiftPerfectVolumeControlPlugin()
        instance.channel = FlutterMethodChannel(name: "perfect_volume_control", binaryMessenger: registrar.messenger())
        instance.bindListener()
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getVolume":
            self.getVolume(call, result: result);
            break;
        case "setVolume":
            self.setVolume(call, result: result);
            break;
        case "hideUI":
            self.hideUI(call, result: result);
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

    public func getVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
            result(AVAudioSession.sharedInstance().outputVolume);
        } catch let error as NSError {
            result(FlutterError(code: String(error.code), message: "\(error.localizedDescription)", details: "\(error.localizedDescription)"));
        }
    }

    public func setVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let volume = ((call.arguments as! [String: Any])["volume"]) as! Double;
        let fVolume = Float(volume)
        var slider: UISlider?;
        slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        if slider == nil {
            result(FlutterError(code: "-1", message: "Unable to get uislider", details: "Unable to get uislider"));
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = fVolume
            slider?.setValue(fVolume, animated: false)
        }

        result(nil);
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

    public func bindListener() {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("\(error)")
        }
        
        outputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] audioSession, _ in
            self?.channel?.invokeMethod("volumeChangeListener", arguments: audioSession.outputVolume)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents();
    }
    
    public func startListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            print("\(error)")
        }
        
        outputVolumeObserver = AVAudioSession.sharedInstance().observe(\.outputVolume) { [weak self] audioSession, _ in
            self?.channel?.invokeMethod("volumeChangeListener", arguments: audioSession.outputVolume)
        }
        
        UIApplication.shared.beginReceivingRemoteControlEvents();
        
        result(nil);
    }
    
    public func stopListeningVolume(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        outputVolumeObserver = nil
        result(nil);
    }
}
