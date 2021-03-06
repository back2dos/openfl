package openfl.display3D;

enum abstract Context3DWrapMode(Null<Int>) {
	public var CLAMP = 0;
	public var CLAMP_U_REPEAT_V = 1;
	public var REPEAT = 2;
	public var REPEAT_U_CLAMP_V = 3;

	@:from private static function fromString(value:String):Context3DWrapMode {
		return switch (value) {
			case "clamp": CLAMP;
			case "clamp_u_repeat_y": CLAMP_U_REPEAT_V;
			case "repeat": REPEAT;
			case "repeat_u_clamp_y": REPEAT_U_CLAMP_V;
			default: null;
		}
	}

	@:to private function toString():String {
		return switch (cast this) {
			case Context3DWrapMode.CLAMP: "clamp";
			case Context3DWrapMode.CLAMP_U_REPEAT_V: "clamp_u_repeat_y";
			case Context3DWrapMode.REPEAT: "repeat";
			case Context3DWrapMode.REPEAT_U_CLAMP_V: "repeat_u_clamp_y";
			default: null;
		}
	}
}
