package lime.app;

import lime.system.System;
import lime.utils.Log;

@:allow(lime.app.Promise)
/*@:generic*/ class Future<T> {
	public var error(default, null):Dynamic;
	public var isComplete(default, null):Bool;
	public var isError(default, null):Bool;
	public var value(default, null):T;

	private var __completeListeners:Array<T->Void>;
	private var __errorListeners:Array<Dynamic->Void>;
	private var __progressListeners:Array<Int->Int->Void>;

	public function new(work:Void->T = null) {
		if (work != null) {
			try {
				value = work();
				isComplete = true;
			} catch (e:Dynamic) {
				error = e;
				isError = true;
			}
		}
	}

	public function onComplete(listener:T->Void):Future<T> {
		if (listener != null) {
			if (isComplete) {
				listener(value);
			} else if (!isError) {
				if (__completeListeners == null) {
					__completeListeners = new Array();
				}

				__completeListeners.push(listener);
			}
		}

		return this;
	}

	public function onError(listener:Dynamic->Void):Future<T> {
		if (listener != null) {
			if (isError) {
				listener(error);
			} else if (!isComplete) {
				if (__errorListeners == null) {
					__errorListeners = new Array();
				}

				__errorListeners.push(listener);
			}
		}

		return this;
	}

	public function onProgress(listener:Int->Int->Void):Future<T> {
		if (listener != null) {
			if (__progressListeners == null) {
				__progressListeners = new Array();
			}

			__progressListeners.push(listener);
		}

		return this;
	}

	public function ready(waitTime:Int = -1):Future<T> {
		#if js
		if (isComplete || isError) {
			return this;
		} else {
			Log.warn("Cannot block thread in JavaScript");
			return this;
		}
		#else
		if (isComplete || isError) {
			return this;
		} else {
			var time = System.getTimer();
			var end = time + waitTime;

			while (!isComplete && !isError && time <= end) {
				#if sys
				Sys.sleep(0.01);
				#end

				time = System.getTimer();
			}

			return this;
		}
		#end
	}

	public function result(waitTime:Int = -1):Null<T> {
		ready(waitTime);

		if (isComplete) {
			return value;
		} else {
			return null;
		}
	}

	public function then<U>(next:T->Future<U>):Future<U> {
		if (isComplete) {
			return next(value);
		} else if (isError) {
			var future = new Future<U>();
			future.onError(error);
			return future;
		} else {
			var promise = new Promise<U>();

			onError(promise.error);
			onProgress(promise.progress);

			onComplete(function(val) {
				var future = next(val);
				future.onError(promise.error);
				future.onComplete(promise.complete);
			});

			return promise.future;
		}
	}

	public static function withError(error:Dynamic):Future<Dynamic> {
		var future = new Future<Dynamic>();
		future.isError = true;
		future.error = error;
		return future;
	}

	public static function withValue<T>(value:T):Future<T> {
		var future = new Future<T>();
		future.isComplete = true;
		future.value = value;
		return future;
	}
}
