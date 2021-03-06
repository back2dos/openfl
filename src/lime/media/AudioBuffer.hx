package lime.media;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import lime.app.Future;
import lime.app.Promise;
import lime.utils.Log;
import lime.utils.UInt8Array;
#if howlerjs
import lime.media.howlerjs.Howl;
#end
#if (js && html5)
import js.html.Audio;
#end

class AudioBuffer {
	public var bitsPerSample:Int;
	public var channels:Int;
	public var data:UInt8Array;
	public var sampleRate:Int;
	public var src(get, set):Dynamic;

	@:noCompletion private var __srcAudio:#if (js && html5) Audio #else Dynamic #end;
	@:noCompletion private var __srcHowl:#if howlerjs Howl #else Dynamic #end;

	public function new() {}

	public function dispose():Void {
		#if (js && html5 && howlerjs)
		__srcHowl.unload();
		#end
	}

	public static function fromBase64(base64String:String):AudioBuffer {
		if (base64String == null)
			return null;

		#if (js && html5 && howlerjs)
		// if base64String doesn't contain codec data, add it.
		if (base64String.indexOf(",") == -1) {
			base64String = "data:" + __getCodec(Base64.decode(base64String)) + ";base64," + base64String;
		}

		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: [base64String], html5: true, preload: false});
		return audioBuffer;
		#end

		return null;
	}

	public static function fromBytes(bytes:Bytes):AudioBuffer {
		if (bytes == null)
			return null;

		#if (js && html5 && howlerjs)
		var audioBuffer = new AudioBuffer();
		audioBuffer.src = new Howl({src: ["data:" + __getCodec(bytes) + ";base64," + Base64.encode(bytes)], html5: true, preload: false});

		return audioBuffer;
		#end

		return null;
	}

	public static function fromFile(path:String):AudioBuffer {
		if (path == null)
			return null;

		#if (js && html5 && howlerjs)
		var audioBuffer = new AudioBuffer();
		audioBuffer.__srcHowl = new Howl({src: [path], preload: false});
		return audioBuffer;
		#else
		return null;
		#end
	}

	public static function fromFiles(paths:Array<String>):AudioBuffer {
		#if (js && html5 && howlerjs)
		var audioBuffer = new AudioBuffer();
		audioBuffer.__srcHowl = new Howl({src: paths, preload: false});
		return audioBuffer;
		#else
		var buffer = null;

		for (path in paths) {
			buffer = AudioBuffer.fromFile(path);
			if (buffer != null)
				break;
		}

		return buffer;
		#end
	}

	public static function loadFromFile(path:String):Future<AudioBuffer> {
		var promise = new Promise<AudioBuffer>();

		var audioBuffer = AudioBuffer.fromFile(path);

		if (audioBuffer != null) {
			#if howlerjs
			if (audioBuffer != null) {
				audioBuffer.__srcHowl.on("load", function() {
					promise.complete(audioBuffer);
				});

				audioBuffer.__srcHowl.on("loaderror", function(id, msg) {
					promise.error(msg);
				});

				audioBuffer.__srcHowl.load();
			}
			#else
			promise.complete(audioBuffer);
			#end
		} else {
			promise.error(null);
		}

		return promise.future;
	}

	public static function loadFromFiles(paths:Array<String>):Future<AudioBuffer> {
		var promise = new Promise<AudioBuffer>();

		#if (js && html5 && howlerjs)
		var audioBuffer = AudioBuffer.fromFiles(paths);

		if (audioBuffer != null) {
			audioBuffer.__srcHowl.on("load", function() {
				promise.complete(audioBuffer);
			});

			audioBuffer.__srcHowl.on("loaderror", function() {
				promise.error(null);
			});

			audioBuffer.__srcHowl.load();
		} else {
			promise.error(null);
		}
		#else
		promise.completeWith(new Future<AudioBuffer>(function() return fromFiles(paths)));
		#end

		return promise.future;
	}

	private static function __getCodec(bytes:Bytes):String {
		var signature = bytes.getString(0, 4);

		switch (signature) {
			case "OggS":
				return "audio/ogg";
			case "fLaC":
				return "audio/flac";
			case "RIFF" if (bytes.getString(8, 4) == "WAVE"):
				return "audio/wav";
			default:
				switch ([bytes.get(0), bytes.get(1), bytes.get(2)]) {
					case [73, 68, 51] | [255, 251, _] | [255, 250, _]: return "audio/mp3";
					default:
				}
		}

		Log.error("Unsupported sound format");
		return null;
	}

	// Get & Set Methods

	private function get_src():Dynamic {
		#if howlerjs
		return __srcHowl;
		#else
		return __srcAudio;
		#end
	}

	private function set_src(value:Dynamic):Dynamic {
		#if howlerjs
		return __srcHowl = value;
		#else
		return __srcAudio = value;
		#end
	}
}
