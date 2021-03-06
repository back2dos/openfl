package lime.media;

import lime.app.Event;
import lime._backend.html5.HTML5AudioSource as AudioSourceBackend;

class AudioSource {
	public var onComplete = new Event<Void->Void>();

	public var buffer:AudioBuffer;
	public var currentTime(get, set):Int;
	public var gain(get, set):Float;
	public var length(get, set):Int;
	public var loops(get, set):Int;
	public var offset:Int;
	public var pan(get, set):Float;

	@:noCompletion private var backend:AudioSourceBackend;

	public function new(buffer:AudioBuffer = null, offset:Int = 0, length:Null<Int> = null, loops:Int = 0) {
		this.buffer = buffer;
		this.offset = offset;

		backend = new AudioSourceBackend(this);

		if (length != null && length != 0) {
			this.length = length;
		}

		this.loops = loops;

		if (buffer != null) {
			init();
		}
	}

	public function dispose():Void {
		backend.dispose();
	}

	private function init():Void {
		backend.init();
	}

	public function play():Void {
		backend.play();
	}

	public function pause():Void {
		backend.pause();
	}

	public function stop():Void {
		backend.stop();
	}

	// Get & Set Methods

	private function get_currentTime():Int {
		return backend.getCurrentTime();
	}

	private function set_currentTime(value:Int):Int {
		return backend.setCurrentTime(value);
	}

	private function get_gain():Float {
		return backend.getGain();
	}

	private function set_gain(value:Float):Float {
		return backend.setGain(value);
	}

	private function get_length():Int {
		return backend.getLength();
	}

	private function set_length(value:Int):Int {
		return backend.setLength(value);
	}

	private function get_loops():Int {
		return backend.getLoops();
	}

	private function set_loops(value:Int):Int {
		return backend.setLoops(value);
	}

	private function get_pan():Float {
		return backend.getPan();
	}

	private function set_pan(value:Float):Float {
		return backend.setPan(value);
	}
}
