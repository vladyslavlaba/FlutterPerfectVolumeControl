package top.huic.perfect_volume_control.perfect_volume_control;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * PerfectVolumeControlPlugin
 */
public class PerfectVolumeControlPlugin implements FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private MethodChannel channel;

    private AudioManager audioManager;

    private Boolean hideUI = false;

    private VolumeReceiver volumeReceiver;

    private VolumeBoundariesKeeper volumeBoundariesKeeper;

    private FlutterPluginBinding binding;

    private int originalVolumeLevel;

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        binding = flutterPluginBinding;
        channel = new MethodChannel(binding.getBinaryMessenger(), "perfect_volume_control");
        channel.setMethodCallHandler(this);
        audioManager = (AudioManager) binding.getApplicationContext().getSystemService(Context.AUDIO_SERVICE);

        originalVolumeLevel = getVolume();
        volumeBoundariesKeeper = new VolumeBoundariesKeeper();
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "hideUI":
                this.hideUI(call, result);
                break;
            case "setVolumeBounds":
                this.setVolumeBounds(call, result);
                break;
            case "startListeningVolume":
                this.startListeningVolume(call, result);
                break;
            case "stopListeningVolume":
                this.stopListeningVolume(call, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        channel.setMethodCallHandler(null);
    }

    public int getVolume() {
        return audioManager.getStreamVolume(AudioManager.STREAM_MUSIC);
    }

    public void setVolume(int volume) {
        int flag = hideUI ? AudioManager.FLAG_REMOVE_SOUND_AND_VIBRATE : AudioManager.FLAG_SHOW_UI;
        audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, volume, flag);
    }

    public void hideUI(@NonNull MethodCall call, @NonNull Result result) {
        this.hideUI = call.argument("hide");
        result.success(null);
    }

    public void setVolumeBounds(@NonNull MethodCall call, @NonNull Result result) {
        Double lower = call.argument("lower");
        Double upper = call.argument("upper");
        Boolean shouldKeep = call.argument("shouldKeep");

        if (lower == null || upper == null || shouldKeep == null) {
            result.error("-1", "Should provide boundaries for volume", null);
            return;
        }

        volumeBoundariesKeeper = new VolumeBoundariesKeeper(lower, upper, shouldKeep);
        volumeBoundariesKeeper.keepVolume();

        result.success(null);
    }

    public void startListeningVolume(@NonNull MethodCall call, @NonNull Result result) {
        if (volumeReceiver == null) {
            volumeReceiver = new VolumeReceiver();
            IntentFilter filter = new IntentFilter();
            filter.addAction("android.media.VOLUME_CHANGED_ACTION");
            binding.getApplicationContext().registerReceiver(volumeReceiver, filter);
        }

        result.success(null);
    }

    public void stopListeningVolume(@NonNull MethodCall call, @NonNull Result result) {
        if (volumeReceiver != null) {
            binding.getApplicationContext().unregisterReceiver(volumeReceiver);
            volumeReceiver = null;
        }

        result.success(null);
    }

    public void upVolumePressed() {
        channel.invokeMethod("volumeKeyPressed", "up");
    }

    public void downVolumePressed() {
        channel.invokeMethod("volumeKeyPressed", "down");
    }

    private class VolumeReceiver extends BroadcastReceiver {
        private static final String VOLUME_CHANGED_ACTION = "android.media.VOLUME_CHANGED_ACTION";

        @Override
        public void onReceive(Context context, Intent intent) {

            if (intent.getAction().equals(VOLUME_CHANGED_ACTION)) {
                int current = getVolume();
                volumeBoundariesKeeper.keepVolume();

                if (originalVolumeLevel == current) return;

                if (current > originalVolumeLevel) {
                    upVolumePressed();
                } else {
                    downVolumePressed();
                }
            }
        }
    }

    private class VolumeBoundariesKeeper {
        final int lower;
        final int upper;
        final boolean shouldKeep;

        public VolumeBoundariesKeeper() {
            int max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);

            this.lower = (int) Math.round(max * 1.0);
            this.upper = (int) Math.round(max * 0.0);

            this.shouldKeep = false;
        }

        public VolumeBoundariesKeeper(double lower, double upper, boolean shouldKeep) {
            int max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC);

            this.lower = (int) Math.round(max * lower);
            this.upper = (int) Math.round(max * upper);

            this.shouldKeep = shouldKeep;
        }

        public void keepVolume() {
            if (!shouldKeep) return;

            int newVolume = originalVolumeLevel;

            if (newVolume > upper) {
                newVolume = upper;
            }
            if (newVolume < lower) {
                newVolume = lower;
            }

            int volume = getVolume();
            if (volume != newVolume) {
                setVolume(newVolume);
            }
        }
    }
}
