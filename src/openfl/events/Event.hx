package openfl.events;

class Event {
	public static inline var ACTIVATE:EventType<Event> = "activate";
	public static inline var ADDED:EventType<Event> = "added";
	public static inline var ADDED_TO_STAGE:EventType<Event> = "addedToStage";
	public static inline var CANCEL:EventType<Event> = "cancel";
	public static inline var CHANGE:EventType<Event> = "change";
	public static inline var CLEAR:EventType<Event> = "clear";
	public static inline var CLOSE:EventType<Event> = "close";
	public static inline var COMPLETE:EventType<Event> = "complete";
	public static inline var CONNECT:EventType<Event> = "connect";
	public static inline var CONTEXT3D_CREATE:EventType<Event> = "context3DCreate";
	public static inline var COPY:EventType<Event> = "copy";
	public static inline var CUT:EventType<Event> = "cut";
	public static inline var DEACTIVATE:EventType<Event> = "deactivate";
	public static inline var ENTER_FRAME:EventType<Event> = "enterFrame";
	public static inline var EXIT_FRAME:EventType<Event> = "exitFrame";
	public static inline var FRAME_CONSTRUCTED:EventType<Event> = "frameConstructed";
	public static inline var FRAME_LABEL:EventType<Event> = "frameLabel";
	public static inline var FULLSCREEN:EventType<Event> = "fullScreen";
	public static inline var ID3:EventType<Event> = "id3";
	public static inline var INIT:EventType<Event> = "init";
	public static inline var MOUSE_LEAVE:EventType<Event> = "mouseLeave";
	public static inline var OPEN:EventType<Event> = "open";
	public static inline var PASTE:EventType<Event> = "paste";
	public static inline var REMOVED:EventType<Event> = "removed";
	public static inline var REMOVED_FROM_STAGE:EventType<Event> = "removedFromStage";
	public static inline var RENDER:EventType<Event> = "render";
	public static inline var RESIZE:EventType<Event> = "resize";
	public static inline var SCROLL:EventType<Event> = "scroll";
	public static inline var SELECT:EventType<Event> = "select";
	public static inline var SELECT_ALL:EventType<Event> = "selectAll";
	public static inline var SOUND_COMPLETE:EventType<Event> = "soundComplete";
	public static inline var TAB_CHILDREN_CHANGE:EventType<Event> = "tabChildrenChange";
	public static inline var TAB_ENABLED_CHANGE:EventType<Event> = "tabEnabledChange";
	public static inline var TAB_INDEX_CHANGE:EventType<Event> = "tabIndexChange";
	public static inline var TEXTURE_READY:EventType<Event> = "textureReady";
	public static inline var UNLOAD:EventType<Event> = "unload";

	public var bubbles(default, null):Bool;
	public var cancelable(default, null):Bool;
	public var currentTarget(default, null):#if (haxe_ver >= "3.4.2") Any #else IEventDispatcher #end;
	public var eventPhase(default, null):EventPhase;
	public var target(default, null):#if (haxe_ver >= "3.4.2") Any #else IEventDispatcher #end;
	public var type(default, null):String;

	private var __isCanceled:Bool;
	private var __isCanceledNow:Bool;
	private var __preventDefault:Bool;

	public function new(type:String, bubbles:Bool = false, cancelable:Bool = false) {
		this.type = type;
		this.bubbles = bubbles;
		this.cancelable = cancelable;
		eventPhase = EventPhase.AT_TARGET;
	}

	public function clone():Event {
		var event = new Event(type, bubbles, cancelable);
		event.eventPhase = eventPhase;
		event.target = target;
		event.currentTarget = currentTarget;
		return event;
	}

	public function formatToString(className:String, ?p1:String, ?p2:String, ?p3:String, ?p4:String, ?p5:String):String {
		var parameters = [];
		if (p1 != null)
			parameters.push(p1);
		if (p2 != null)
			parameters.push(p2);
		if (p3 != null)
			parameters.push(p3);
		if (p4 != null)
			parameters.push(p4);
		if (p5 != null)
			parameters.push(p5);

		return Reflect.callMethod(this, __formatToString, [className, parameters]);
	}

	public function isDefaultPrevented():Bool {
		return __preventDefault;
	}

	public function preventDefault():Void {
		if (cancelable) {
			__preventDefault = true;
		}
	}

	public function stopImmediatePropagation():Void {
		__isCanceled = true;
		__isCanceledNow = true;
	}

	public function stopPropagation():Void {
		__isCanceled = true;
	}

	public function toString():String {
		return __formatToString("Event", ["type", "bubbles", "cancelable"]);
	}

	private function __formatToString(className:String, parameters:Array<String>):String {
		// TODO: Make this a macro function, and handle at compile-time, with rest parameters?

		var output = '[$className';
		var arg:Dynamic = null;

		for (param in parameters) {
			arg = Reflect.field(this, param);

			if (Std.is(arg, String)) {
				output += ' $param="$arg"';
			} else {
				output += ' $param=$arg';
			}
		}

		output += "]";
		return output;
	}
}
