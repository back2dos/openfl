package openfl.display;

import lime.ui.MouseCursor;
import lime.utils.ObjectPool;
import openfl.Vector;
import openfl._internal.Lib;
import openfl._internal.renderer.RenderSession;
import openfl._internal.renderer.canvas.CanvasBitmap;
import openfl._internal.renderer.canvas.CanvasDisplayObject;
import openfl._internal.renderer.canvas.CanvasGraphics;
import openfl._internal.renderer.canvas.CanvasRenderSession;
import openfl._internal.renderer.opengl.GLBitmap;
import openfl._internal.renderer.opengl.GLDisplayObject;
import openfl._internal.renderer.opengl.GLRenderSession;
import openfl.display.Stage;
import openfl.errors.TypeError;
import openfl.events.Event;
import openfl.events.EventDispatcher;
import openfl.events.EventPhase;
import openfl.events.MouseEvent;
import openfl.events.TouchEvent;
import openfl.filters.BitmapFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.Transform;

@:access(openfl.events.Event)
@:access(openfl.display.Bitmap)
@:access(openfl.display.DisplayObjectContainer)
@:access(openfl.display.Graphics)
@:access(openfl.display.Stage)
@:access(openfl.filters.BitmapFilter)
@:access(openfl.geom.ColorTransform)
@:access(openfl.geom.Matrix)
@:access(openfl.geom.Rectangle)
class DisplayObject extends EventDispatcher implements IBitmapDrawable {
	private static var __broadcastEvents = new Map<String, Array<DisplayObject>>();
	private static var __initStage:Stage;
	private static var __instanceCount = 0;
	private static var __tempStack = new ObjectPool<Vector<DisplayObject>>(function() {
		return new Vector<DisplayObject>();
	}, function(stack) {
		stack.length = 0;
	});
	private static var __tempBoundsRectangle = new Rectangle();

	@:keep public var alpha(get, set):Float;
	public var blendMode(get, set):BlendMode;
	public var cacheAsBitmap(get, set):Bool;
	public var cacheAsBitmapMatrix(get, set):Matrix;
	public var filters(get, set):Array<BitmapFilter>;
	@:keep public var height(get, set):Float;
	public var loaderInfo(get, never):LoaderInfo;
	public var mask(get, set):DisplayObject;
	public var mouseX(get, never):Float;
	public var mouseY(get, never):Float;
	public var name(get, set):String;
	public var opaqueBackground:Null<Int>;
	public var parent(default, null):DisplayObjectContainer;
	public var root(get, never):DisplayObject;
	@:keep public var rotation(get, set):Float;
	public var scale9Grid:Rectangle;
	@:keep public var scaleX(get, set):Float;
	@:keep public var scaleY(get, set):Float;
	public var scrollRect(get, set):Rectangle;
	public var stage(default, null):Stage;
	@:keep public var transform(get, set):Transform;
	public var visible(get, set):Bool;
	@:keep public var width(get, set):Float;
	@:keep public var x(get, set):Float;
	@:keep public var y(get, set):Float;

	private var __alpha:Float;
	private var __blendMode:BlendMode;
	private var __cacheAsBitmap:Bool;
	private var __cacheAsBitmapMatrix:Matrix;
	private var __cacheBitmap:Bitmap;
	private var __cacheBitmapBackground:Null<Int>;
	private var __cacheBitmapColorTransform:ColorTransform;
	private var __cacheBitmapData:BitmapData;
	private var __cacheBitmapRender:Bool;
	private var __children:Array<DisplayObject>;
	private var __filters:Array<BitmapFilter>;
	private var __graphics:Graphics;
	private var __isMask(get,never):Bool;
	private var __loaderInfo:LoaderInfo;
	private var __mask:DisplayObject;
	private var __maskTarget:DisplayObject;
	private var __name:String;
	private var __objectTransform:Transform;
	private var __renderable:Bool;
	private var __renderDirty:Bool;
	private var __renderTransform:Matrix;
	private var __rotation:Float;
	private var __rotationCosine:Float;
	private var __rotationSine:Float;
	private var __scaleX:Float;
	private var __scaleY:Float;
	private var __scrollRect:Rectangle;
	private var __transform:Matrix;
	private var __updateDirty:Bool;
	private var __visible:Bool;
	private var __worldAlpha:Float;
	private var __worldBlendMode:BlendMode;
	private var __worldColorTransform:ColorTransform;
	private var __worldTransform:Matrix;
	private var __worldTransformInvalid:Bool;
	private var __pixelSnapping:PixelSnapping;

	private function new() {
		super();

		if (__initStage != null) {
			this.stage = __initStage;
			__initStage = null;
		}

		__alpha = 1;
		__blendMode = NORMAL;
		__cacheAsBitmap = false;
		__transform = new Matrix();
		__visible = true;

		__rotation = 0;
		__rotationSine = 0;
		__rotationCosine = 1;
		__scaleX = 1;
		__scaleY = 1;

		__worldAlpha = 1;
		__worldBlendMode = NORMAL;
		__worldTransform = new Matrix();
		__worldColorTransform = new ColorTransform();
		__renderTransform = new Matrix();

		name = "instance" + (++__instanceCount);
	}

	public override function addEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false, priority:Int = 0,
			useWeakReference:Bool = false):Void {
		switch (type) {
			case Event.ACTIVATE, Event.DEACTIVATE, Event.ENTER_FRAME, Event.EXIT_FRAME, Event.FRAME_CONSTRUCTED, Event.RENDER:
				if (!__broadcastEvents.exists(type)) {
					__broadcastEvents.set(type, []);
				}

				var dispatchers = __broadcastEvents.get(type);

				if (dispatchers.indexOf(this) == -1) {
					dispatchers.push(this);
				}

			default:
		}

		super.addEventListener(type, listener, useCapture, priority, useWeakReference);
	}

	public override function dispatchEvent(event:Event):Bool {
		if (Std.is(event, MouseEvent)) {
			var mouseEvent:MouseEvent = cast event;
			mouseEvent.stageX = __getRenderTransform().__transformX(mouseEvent.localX, mouseEvent.localY);
			mouseEvent.stageY = __getRenderTransform().__transformY(mouseEvent.localX, mouseEvent.localY);
		} else if (Std.is(event, TouchEvent)) {
			var touchEvent:TouchEvent = cast event;
			touchEvent.stageX = __getRenderTransform().__transformX(touchEvent.localX, touchEvent.localY);
			touchEvent.stageY = __getRenderTransform().__transformY(touchEvent.localX, touchEvent.localY);
		}

		return __dispatchWithCapture(event);
	}

	public function getBounds(targetCoordinateSpace:DisplayObject):Rectangle {
		var matrix = Matrix.__pool.get();

		if (targetCoordinateSpace != null && targetCoordinateSpace != this) {
			matrix.copyFrom(__getWorldTransform());

			var targetMatrix = Matrix.__pool.get();

			targetMatrix.copyFrom(targetCoordinateSpace.__getWorldTransform());
			targetMatrix.invert();

			matrix.concat(targetMatrix);

			Matrix.__pool.release(targetMatrix);
		} else {
			matrix.identity();
		}

		var bounds = new Rectangle();
		__getBounds(bounds, matrix);

		Matrix.__pool.release(matrix);

		return bounds;
	}

	public function getRect(targetCoordinateSpace:DisplayObject):Rectangle {
		// should not account for stroke widths, but is that possible?
		return getBounds(targetCoordinateSpace);
	}

	public function globalToLocal(pos:Point):Point {
		return __globalToLocal(pos, new Point());
	}

	public function hitTestObject(obj:DisplayObject):Bool {
		if (obj != null && obj.parent != null && parent != null) {
			var currentBounds = getBounds(this);
			var targetBounds = obj.getBounds(this);

			return currentBounds.intersects(targetBounds);
		}

		return false;
	}

	public function hitTestPoint(x:Float, y:Float, shapeFlag:Bool = false):Bool {
		if (stage != null) {
			return __hitTest(x, y, shapeFlag, null, true, this);
		} else {
			return false;
		}
	}

	public function localToGlobal(point:Point):Point {
		return __getRenderTransform().transformPoint(point);
	}

	public override function removeEventListener(type:String, listener:Dynamic->Void, useCapture:Bool = false):Void {
		super.removeEventListener(type, listener, useCapture);

		switch (type) {
			case Event.ACTIVATE, Event.DEACTIVATE, Event.ENTER_FRAME, Event.EXIT_FRAME, Event.FRAME_CONSTRUCTED, Event.RENDER:
				if (!hasEventListener(type)) {
					if (__broadcastEvents.exists(type)) {
						__broadcastEvents.get(type).remove(this);
					}
				}

			default:
		}
	}

	private static inline function __calculateAbsoluteTransform(local:Matrix, parentTransform:Matrix, target:Matrix):Void {
		target.a = local.a * parentTransform.a + local.b * parentTransform.c;
		target.b = local.a * parentTransform.b + local.b * parentTransform.d;
		target.c = local.c * parentTransform.a + local.d * parentTransform.c;
		target.d = local.c * parentTransform.b + local.d * parentTransform.d;
		target.tx = local.tx * parentTransform.a + local.ty * parentTransform.c + parentTransform.tx;
		target.ty = local.tx * parentTransform.b + local.ty * parentTransform.d + parentTransform.ty;
	}

	private function __cleanup():Void {
		if (__graphics != null) {
			__graphics.__cleanup();
		}

		if (__cacheBitmap != null) {
			__cacheBitmap.__cleanup();
			__cacheBitmap = null;
		}

		if (__cacheBitmapData != null) {
			__cacheBitmapData.dispose();
			__cacheBitmapData = null;
		}
	}

	private function __dispatch(event:Event):Bool {
		if (__eventMap != null && hasEventListener(event.type)) {
			var result = super.__dispatchEvent(event);

			if (event.__isCanceled) {
				return true;
			}

			return result;
		}

		return true;
	}

	private function __dispatchChildren(event:Event):Void {}

	private override function __dispatchEvent(event:Event):Bool {
		var tmpParent = null;

		if (event.bubbles) {
			tmpParent = parent;
		}

		var result = super.__dispatchEvent(event);

		if (event.__isCanceled) {
			return true;
		}

		if (tmpParent != null && tmpParent != this) {
			event.eventPhase = EventPhase.BUBBLING_PHASE;

			if (event.target == null) {
				event.target = this;
			}

			tmpParent.__dispatchEvent(event);
		}

		return result;
	}

	private function __dispatchWithCapture(event:Event):Bool {
		if (event.target == null) {
			event.target = this;
		}

		if (parent != null) {
			event.eventPhase = CAPTURING_PHASE;

			if (parent == stage) {
				parent.__dispatch(event);

				if (event.__isCanceled) {
					return true;
				}
			} else {
				var stack = __tempStack.get();
				var parent = parent;
				var i = 0;

				while (parent != null) {
					stack[i] = parent;
					parent = parent.parent;
					i++;
				}

				var canceled = false;

				for (j in 0...i) {
					stack[i - j - 1].__dispatch(event);

					if (event.__isCanceled) {
						canceled = true;
						break;
					}
				}

				__tempStack.release(stack);

				if (canceled) {
					return true;
				}
			}
		}

		event.eventPhase = AT_TARGET;

		return __dispatchEvent(event);
	}

	private function __forceRenderDirty():Void {
		__renderDirty = true;

		if (__graphics != null) {
			__graphics.__dirty = true;
		}

		if (__cacheBitmap != null) {
			__cacheBitmap.__forceRenderDirty();
		}
	}

	private function __getBounds(rect:Rectangle, matrix:Matrix):Void {
		if (__graphics != null) {
			__graphics.__getBounds(rect, matrix);
		}
	}

	private function __getCursor():MouseCursor {
		return null;
	}

	private function __getFilterBounds(rect:Rectangle, matrix:Matrix):Void {
		// TODO: Should this be __getRenderBounds, to account for scrollRect?

		__getBounds(rect, matrix);

		if (__hasFilters()) {
			var extension = DisplayObject.__tempBoundsRectangle;
			extension.setEmpty();

			for (filter in __filters) {
				extension.__expand(-filter.__leftExtension,
					-filter.__topExtension, filter.__leftExtension
					+ filter.__rightExtension,
					filter.__topExtension
					+ filter.__bottomExtension);
			}

			rect.width += extension.width;
			rect.height += extension.height;
			rect.x += extension.x;
			rect.y += extension.y;
		}
	}

	private function __getInteractive(stack:Array<DisplayObject>):Bool {
		return false;
	}

	private function __getLocalBounds(rect:Rectangle):Void {
		// var cacheX = __transform.tx;
		// var cacheY = __transform.ty;
		// __transform.tx = __transform.ty = 0;

		__getBounds(rect, __transform);

		// __transform.tx = cacheX;
		// __transform.ty = cacheY;

		rect.x -= __transform.tx;
		rect.y -= __transform.ty;
	}

	private function __getRenderBounds(rect:Rectangle, matrix:Matrix):Void {
		if (__scrollRect == null) {
			__getBounds(rect, matrix);
		} else {
			var r = DisplayObject.__tempBoundsRectangle;
			__scrollRect.__transform(r, matrix);
			rect.__expand(matrix.tx, matrix.ty, r.width, r.height);
		}
	}

	private function __getRenderTransform():Matrix {
		__getWorldTransform();
		return __renderTransform;
	}

	private function __getWorldTransform():Matrix {
		if (__worldTransformInvalid) {
			if (parent == null) {
				__updateTransforms();
			} else {
				var list = [];
				var current = this;

				do {
					list.push(current);
					current = current.parent;
				} while (current != null && current.__worldTransformInvalid);

				var i = list.length;
				while (--i >= 0) {
					current = list[i];
					current.__updateTransforms();
				}
			}
		}

		return __worldTransform;
	}

	private function __globalToLocal(global:Point, local:Point):Point {
		__getRenderTransform();

		if (global == local) {
			__renderTransform.__transformInversePoint(global);
		} else {
			local.x = __renderTransform.__transformInverseX(global.x, global.y);
			local.y = __renderTransform.__transformInverseY(global.x, global.y);
		}

		return local;
	}

	private inline function __hasFilters():Bool {
		return __filters != null && __filters.length > 0;
	}

	private function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool, hitObject:DisplayObject,
			hitTestWhenMouseDisabled:Bool = false):Bool {
		if (__graphics != null) {
			if (!hitObject.visible || __isMask)
				return false;
			if (mask != null && !mask.__hitTestMask(x, y))
				return false;

			if (__graphics.__hitTest(x, y, shapeFlag, __getRenderTransform())) {
				if (stack != null && !interactiveOnly && !hitTestWhenMouseDisabled) {
					stack.push(hitObject);
				}

				return true;
			}
		}

		return false;
	}

	private function __hitTestMask(x:Float, y:Float):Bool {
		if (__graphics != null) {
			if (__graphics.__hitTest(x, y, true, __getRenderTransform())) {
				return true;
			}
		}

		return false;
	}

	private function __mouseThroughAllowed():Bool {
		return false;
	}

	private function __readGraphicsData(graphicsData:Vector<IGraphicsData>, recurse:Bool):Void {
		if (__graphics != null) {
			__graphics.__readGraphicsData(graphicsData);
		}
	}

	private function __renderCanvas(renderSession:CanvasRenderSession):Void {
		if (mask == null || (mask.width > 0 && mask.height > 0)) {
			__updateCacheBitmap(renderSession, !__worldColorTransform.__isDefault());

			if (__cacheBitmap != null && !__cacheBitmapRender) {
				CanvasBitmap.render(__cacheBitmap, renderSession);
			} else {
				CanvasDisplayObject.render(this, renderSession);
			}
		}
	}

	private function __renderCanvasMask(renderSession:CanvasRenderSession):Void {
		if (__graphics != null) {
			CanvasGraphics.renderMask(__graphics, renderSession);
		}
	}

	private function __renderGL(renderSession:GLRenderSession):Void {
		__updateCacheBitmap(renderSession, false);

		if (__cacheBitmap != null && !__cacheBitmapRender) {
			GLBitmap.render(__cacheBitmap, renderSession);
		} else {
			GLDisplayObject.render(this, renderSession);
		}
	}

	private function __renderGLMask(renderSession:GLRenderSession):Void {
		__updateCacheBitmap(renderSession, false);

		if (__cacheBitmap != null && !__cacheBitmapRender) {
			GLBitmap.renderMask(__cacheBitmap, renderSession);
		} else {
			GLDisplayObject.renderMask(this, renderSession);
		}
	}

	private function __setParentRenderDirty():Void {
		var parent = this.parent;

		while (parent != null && !parent.__renderDirty) {
			parent.__renderDirty = true;
			parent = parent.parent;
		}
	}

	private inline function __setRenderDirty():Void {
		if (!__renderDirty) {
			__renderDirty = true;
			if (__maskTarget != null) {
				// we want to re-render the mask target as well as update it
				// so it recalculates its `__renderable` considering mask's visibility
				__maskTarget.__setRenderDirty();
			} else {
				__setParentRenderDirty();
			}
		}
		__setUpdateDirty();
	}

	private function __setStageReference(stage:Stage):Void {
		this.stage = stage;
	}

	private function __setTransformDirty():Void {
		__setWorldTransformInvalid();
		__setParentRenderDirty();
		__setUpdateDirty();
	}

	private inline function __setUpdateDirty():Void {
		if (!__updateDirty) {
			__updateDirty = true;

			// As this DisplayObject needs to be updated, we need to flag all parents to be traversed
			__setParentUpdateTraverse();
		}
	}

	private function __setParentUpdateTraverse():Void {
		var parent = this.parent;

		while (parent != null && !parent.__updateTraverse) {
			parent.__updateTraverse = true;
			parent = parent.parent;
		}
	}

	private function __setWorldTransformInvalid():Void {
		__worldTransformInvalid = true;
	}

	private function __stopAllMovieClips():Void {}

	private function __traverse():Void {
		if (__updateDirty) {
			__update(true);
		}
	}

	public function __update(resetUpdateDirty:Bool):Void {
		if (resetUpdateDirty) {
			__updateDirty = false;
		}

		var renderParent:DisplayObject = parent;
		if (__isMask && renderParent == null)
			renderParent = __maskTarget;
		__renderable = (visible && !__isScaledToZero() && !__isMask && (renderParent == null || !renderParent.__isMask) && (__mask == null || !__mask.__isScaledToZero()));
		__updateTransforms();

		if (!__worldColorTransform.__equals(transform.colorTransform)) {
			__worldColorTransform = transform.colorTransform.__clone();
		}

		if (renderParent != null) {
			__worldAlpha = alpha * renderParent.__worldAlpha;

			__worldColorTransform.__combine(renderParent.__worldColorTransform);

			if (__blendMode == null || __blendMode == NORMAL) {
				// TODO: Handle multiple blend modes better
				__worldBlendMode = renderParent.__blendMode;
			} else {
				__worldBlendMode = __blendMode;
			}
		} else {
			__worldAlpha = alpha;
		}

		if (mask != null) {
			mask.__update(resetUpdateDirty);
		}
	}

	inline function __isScaledToZero():Bool {
		return __scaleX == 0 || __scaleY == 0;
	}

	private function __updateCacheBitmap(renderSession:RenderSession, force:Bool):Bool {
		if (__cacheBitmapRender)
			return false;

		if (force || cacheAsBitmap) {
			var rect = null;

			// if (!renderSession.lockTransform) __getWorldTransform ();

			var needRender = (__cacheBitmap == null || __cacheBitmapNeedsRender());
			var updateTransform = (needRender || !__cacheBitmap.__worldTransform.equals(__renderTransform));
			var hasFilters = __hasFilters();
			var pixelRatio = renderSession.pixelRatio;

			if (hasFilters && !needRender) {
				for (filter in __filters) {
					if (filter.__renderDirty) {
						needRender = true;
						break;
					}
				}
			}

			var bitmapWidth = 0, bitmapHeight = 0;

			if (updateTransform || needRender) {
				rect = Rectangle.__pool.get();

				__getFilterBounds(rect, __renderTransform);

				bitmapWidth = Math.ceil(rect.width * pixelRatio);
				bitmapHeight = Math.ceil(rect.height * pixelRatio);

				if (!needRender && __cacheBitmap != null && (bitmapWidth != __cacheBitmap.width || bitmapHeight != __cacheBitmap.height)) {
					needRender = true;
				}
			}

			if (needRender) {
				__cacheBitmapBackground = opaqueBackground;
				var color = opaqueBackground != null ? (0xFF << 24) | opaqueBackground : 0;

				if (rect.width >= 0.5 && rect.height >= 0.5) {
					if (__cacheBitmap == null || bitmapWidth != __cacheBitmap.width || bitmapHeight != __cacheBitmap.height) {
						__cacheBitmapData = new BitmapData(bitmapWidth, bitmapHeight, true, color);
						@:privateAccess __cacheBitmapData.__pixelRatio = pixelRatio;
						// __cacheBitmapData.disposeImage ();

						if (__cacheBitmap == null)
							__cacheBitmap = new Bitmap();
						__cacheBitmap.__bitmapData = __cacheBitmapData;
					} else {
						__cacheBitmapData.fillRect(__cacheBitmapData.rect, color);
					}
				} else {
					__cacheBitmap = null;
					__cacheBitmapData = null;
					return true;
				}
			}

			if (updateTransform || needRender) {
				__cacheBitmap.__worldTransform.copyFrom(__renderTransform);

				__cacheBitmap.__renderTransform.identity();
				__cacheBitmap.__renderTransform.tx = rect.x;
				__cacheBitmap.__renderTransform.ty = rect.y;
				__cacheBitmap.__batchQuadDirty = true;
			}

			__cacheBitmap.smoothing = false;
			__cacheBitmap.__renderable = __renderable;
			__cacheBitmap.__worldAlpha = __worldAlpha;
			__cacheBitmap.__worldBlendMode = __worldBlendMode;
			__cacheBitmap.__scrollRect = __scrollRect;
			// __cacheBitmap.filters = filters;
			__cacheBitmap.mask = __mask;

			if (needRender) {
				__cacheBitmapRender = true;

				var matrix = Matrix.__pool.get();
				matrix.copyFrom(__renderTransform);
				matrix.tx -= Math.round(rect.x);
				matrix.ty -= Math.round(rect.y);

				@:privateAccess __cacheBitmapData.__draw(this, matrix, NORMAL, null, renderSession.allowSmoothing, true);

				Matrix.__pool.release(matrix);

				if (hasFilters) {
					var needSecondBitmapData = false;
					var needCopyOfOriginal = false;

					for (filter in __filters) {
						if (filter.__needSecondBitmapData) {
							needSecondBitmapData = true;
						}
						if (filter.__preserveObject) {
							needCopyOfOriginal = true;
						}
					}

					var bitmapData = __cacheBitmapData;
					var bitmapData2 = null;
					var bitmapData3 = null;

					// TODO: Cache if used repeatedly

					if (needSecondBitmapData) {
						bitmapData2 = new BitmapData(bitmapData.width, bitmapData.height, true, 0);
						@:privateAccess bitmapData2.__pixelRatio = pixelRatio;
					} else {
						bitmapData2 = bitmapData;
					}

					if (needCopyOfOriginal) {
						bitmapData3 = new BitmapData(bitmapData.width, bitmapData.height, true, 0);
						@:privateAccess bitmapData3.__pixelRatio = pixelRatio;
					}

					var sourceRect = bitmapData.rect;
					var destPoint = new Point(); // TODO: ObjectPool
					var cacheBitmap, lastBitmap;

					for (filter in __filters) {
						if (filter.__preserveObject) {
							bitmapData3.copyPixels(bitmapData, bitmapData.rect, destPoint);
						}

						lastBitmap = filter.__applyFilter(bitmapData2, bitmapData, sourceRect, destPoint);

						if (filter.__preserveObject) {
							lastBitmap.draw(bitmapData3, null, transform.colorTransform);
						}
						filter.__renderDirty = false;

						if (needSecondBitmapData && lastBitmap == bitmapData2) {
							cacheBitmap = bitmapData;
							bitmapData = bitmapData2;
							bitmapData2 = cacheBitmap;
						}
					}

					__cacheBitmapData = bitmapData;
					__cacheBitmap.bitmapData = bitmapData;
				}

				__cacheBitmapRender = false;

				if (__cacheBitmapColorTransform == null)
					__cacheBitmapColorTransform = new ColorTransform();
				__cacheBitmapColorTransform.__copyFrom(__worldColorTransform);

				if (!__cacheBitmapColorTransform.__isDefault()) {
					__cacheBitmapData.colorTransform(__cacheBitmapData.rect, __cacheBitmapColorTransform);
				}
			}

			if (updateTransform || needRender) {
				Rectangle.__pool.release(rect);
			}

			return updateTransform;
		} else if (__cacheBitmap != null) {
			__cacheBitmap = null;
			__cacheBitmapData = null;
			__cacheBitmapColorTransform = null;

			return true;
		}

		return false;
	}

	private function __cacheBitmapNeedsRender():Bool {
		return (__renderDirty
			&& ((__children != null && __children.length > 0) // TODO: this is the only place we use __children in DisplayObject, we can probably move this check in a DisplayObjectContainer override along with __children
				|| (__graphics != null && __graphics.__dirty) // TODO: not sure if this ever holds, because graphics dirty flag is reset before we end up here
			))
			|| opaqueBackground != __cacheBitmapBackground
			|| !__cacheBitmapColorTransform.__equals(__worldColorTransform);
	}

	extern inline function get___isMask():Bool {
		return __maskTarget != null;
	}

	private function __renderToBitmap(renderSession:CanvasRenderSession, matrix:Matrix, blendMode:BlendMode) {
		var cacheMaskTarget = __maskTarget;
		var cacheVisible = __visible;
		var cacheRenderable = __renderable;
		var cacheWorldAlpha = __worldAlpha;
		var cacheBlendMode = __worldBlendMode;

		var cacheWorldTransform = Matrix.__pool.get();
		var cacheRenderTransform = Matrix.__pool.get();
		cacheWorldTransform.copyFrom(__worldTransform);
		cacheRenderTransform.copyFrom(__renderTransform);

		__maskTarget = null;
		__visible = true;
		__renderable = true;
		__worldAlpha = 1;
		__worldBlendMode = blendMode;
		__worldTransform.copyFrom(matrix);
		__renderTransform.copyFrom(matrix);
		__adjustRenderTransform();

		__updateChildrenForRenderToBitmap();
		__renderCanvas(renderSession);

		__maskTarget = cacheMaskTarget;
		__visible = cacheVisible;
		__renderable = cacheRenderable;
		__worldAlpha = cacheWorldAlpha;
		__worldBlendMode = cacheBlendMode;

		__worldTransform.copyFrom(cacheWorldTransform);
		__renderTransform.copyFrom(cacheRenderTransform);
		Matrix.__pool.release(cacheWorldTransform);
		Matrix.__pool.release(cacheRenderTransform);

		__updateChildrenForRenderToBitmap();
	}

	function __updateChildrenForRenderToBitmap():Void {}

	function __updateTransforms():Void {
		if (parent != null) {
			__calculateAbsoluteTransform(__transform, parent.__worldTransform, __worldTransform);
			__calculateAbsoluteTransform(__transform, parent.__renderTransform, __renderTransform);
		} else {
			__worldTransform.copyFrom(__transform);
			__renderTransform.copyFrom(__transform);
		}

		__adjustRenderTransform();

		__worldTransformInvalid = false;
	}

	function __adjustRenderTransform() {
		if (__scrollRect != null) {
			__renderTransform.__translateTransformed(-__scrollRect.x, -__scrollRect.y);
		}
	}

	private inline function __snapToPixel():Bool {
		return switch __pixelSnapping {
			case null | NEVER: false;
			case ALWAYS: true;
			case AUTO: Math.abs(__renderTransform.a) == 1 && Math.abs(__renderTransform.d) == 1; // only snap when not scaled/rotated/skewed
		}
	}

	// Get & Set Methods

	inline function get_pixelSnapping() {
		return __pixelSnapping;
	}

	function set_pixelSnapping(value) {
		if (__pixelSnapping != value) {
			__pixelSnapping = value;
			__setRenderDirty();
		}

		return value;
	}

	private function get_alpha():Float {
		return __alpha;
	}

	private function set_alpha(value:Float):Float {
		if (value > 1.0)
			value = 1.0;
		if (value != __alpha)
			__setRenderDirty();
		return __alpha = value;
	}

	private function get_blendMode():BlendMode {
		return __blendMode;
	}

	private function set_blendMode(value:BlendMode):BlendMode {
		if (value == null)
			value = NORMAL;
		if (value != __blendMode)
			__setRenderDirty();
		return __blendMode = value;
	}

	private function get_cacheAsBitmap():Bool {
		return (__filters == null ? __cacheAsBitmap : true);
	}

	private function set_cacheAsBitmap(value:Bool):Bool {
		__setRenderDirty();
		return __cacheAsBitmap = value;
	}

	private function get_cacheAsBitmapMatrix():Matrix {
		return __cacheAsBitmapMatrix;
	}

	private function set_cacheAsBitmapMatrix(value:Matrix):Matrix {
		__setRenderDirty();
		return __cacheAsBitmapMatrix = value.clone();
	}

	private function get_filters():Array<BitmapFilter> {
		if (__filters == null) {
			return new Array();
		} else {
			return __filters.copy();
		}
	}

	private function set_filters(value:Array<BitmapFilter>):Array<BitmapFilter> {
		if (value != null && value.length > 0) {
			__filters = value;
			// __updateFilters = true;
		} else {
			__filters = null;
			// __updateFilters = false;
		}

		__setRenderDirty();

		return value;
	}

	private function get_height():Float {
		var rect = Rectangle.__pool.get();
		__getLocalBounds(rect);
		var height = rect.height;
		Rectangle.__pool.release(rect);
		return height;
	}

	private function set_height(value:Float):Float {
		var rect = Rectangle.__pool.get();
		var matrix = Matrix.__pool.get();
		matrix.identity();

		__getBounds(rect, matrix);

		if (value != rect.height) {
			scaleY = value / rect.height;
		} else {
			scaleY = 1;
		}

		Rectangle.__pool.release(rect);
		Matrix.__pool.release(matrix);

		return value;
	}

	private function get_loaderInfo():LoaderInfo {
		if (stage != null) {
			return Lib.current.__loaderInfo;
		}

		return null;
	}

	private function get_mask():DisplayObject {
		return __mask;
	}

	private function set_mask(value:DisplayObject):DisplayObject {
		if (value == __mask) {
			return value;
		}

		if (value != __mask) {
			__setTransformDirty();
			__setRenderDirty();
		}

		if (__mask != null) {
			__mask.__maskTarget = null;
			__mask.__setTransformDirty();
			__mask.__setRenderDirty();
		}

		if (value != null) {
			value.__maskTarget = this;
			value.__setWorldTransformInvalid();
		}

		if (__cacheBitmap != null && __cacheBitmap.mask != value) {
			__cacheBitmap.mask = value;
		}

		return __mask = value;
	}

	private function get_mouseX():Float {
		var mouseX = (stage != null ? stage.__mouseX : Lib.current.stage.__mouseX);
		var mouseY = (stage != null ? stage.__mouseY : Lib.current.stage.__mouseY);

		return __getRenderTransform().__transformInverseX(mouseX, mouseY);
	}

	private function get_mouseY():Float {
		var mouseX = (stage != null ? stage.__mouseX : Lib.current.stage.__mouseX);
		var mouseY = (stage != null ? stage.__mouseY : Lib.current.stage.__mouseY);

		return __getRenderTransform().__transformInverseY(mouseX, mouseY);
	}

	private function get_name():String {
		return __name;
	}

	private function set_name(value:String):String {
		return __name = value;
	}

	private function get_root():DisplayObject {
		if (stage != null) {
			return Lib.current;
		}

		return null;
	}

	private function get_rotation():Float {
		return __rotation;
	}

	private function set_rotation(value:Float):Float {
		value = __normalizeAngle(value);

		if (value != __rotation) {
			__rotation = value;
			var radians = __rotation * (Math.PI / 180);
			__rotationSine = Math.sin(radians);
			__rotationCosine = Math.cos(radians);

			__transform.a = __rotationCosine * __scaleX;
			__transform.b = __rotationSine * __scaleX;
			__transform.c = -__rotationSine * __scaleY;
			__transform.d = __rotationCosine * __scaleY;

			__setTransformDirty();
		}

		return value;
	}

	private static inline function __normalizeAngle(value:Float):Float {
		var normalized:Float = value % 360;

		if (normalized > 180) {
			normalized -= 360;
		} else if (normalized < -180) {
			normalized += 360;
		}

		return normalized;
	}

	@:keep private function get_scaleX():Float {
		return __scaleX;
	}

	@:keep private function set_scaleX(value:Float):Float {
		if (value != __scaleX) {
			__scaleX = value;

			if (__transform.b == 0) {
				if (value != __transform.a)
					__setTransformDirty();
				__transform.a = value;
			} else {
				var a = __rotationCosine * value;
				var b = __rotationSine * value;

				if (__transform.a != a || __transform.b != b) {
					__setTransformDirty();
				}

				__transform.a = a;
				__transform.b = b;
			}
		}

		return value;
	}

	@:keep private function get_scaleY():Float {
		return __scaleY;
	}

	@:keep private function set_scaleY(value:Float):Float {
		if (value != __scaleY) {
			__scaleY = value;

			if (__transform.c == 0) {
				if (value != __transform.d)
					__setTransformDirty();
				__transform.d = value;
			} else {
				var c = -__rotationSine * value;
				var d = __rotationCosine * value;

				if (__transform.d != d || __transform.c != c) {
					__setTransformDirty();
				}

				__transform.c = c;
				__transform.d = d;
			}
		}

		return value;
	}

	private function get_scrollRect():Rectangle {
		if (__scrollRect == null) {
			return null;
		}

		return __scrollRect.clone();
	}

	private function set_scrollRect(value:Rectangle):Rectangle {
		var dirty = false;
		if (value == null) {
			dirty = __scrollRect != null;

			__scrollRect = null;
		} else if (__scrollRect == null) {
			__scrollRect = value.clone();

			dirty = true;
		} else if (!__scrollRect.equals(value)) {
			__scrollRect.copyFrom(value);

			dirty = true;
		}

		if (dirty) {
			__setTransformDirty();
		}

		return __scrollRect;
	}

	private function get_transform():Transform {
		if (__objectTransform == null) {
			__objectTransform = new Transform(this);
		}

		return __objectTransform;
	}

	private function set_transform(value:Transform):Transform {
		if (value == null) {
			throw new TypeError("Parameter transform must be non-null.");
		}

		if (__objectTransform == null) {
			__objectTransform = new Transform(this);
		}

		__setTransformDirty();
		__objectTransform.matrix = value.matrix;
		__objectTransform.colorTransform = value.colorTransform.__clone();

		return __objectTransform;
	}

	private function get_visible():Bool {
		return __visible;
	}

	private function set_visible(value:Bool):Bool {
		if (value != __visible)
			__setRenderDirty();
		return __visible = value;
	}

	private function get_width():Float {
		var rect = Rectangle.__pool.get();
		__getLocalBounds(rect);
		var width = rect.width;
		Rectangle.__pool.release(rect);
		return width;
	}

	private function set_width(value:Float):Float {
		var rect = Rectangle.__pool.get();
		var matrix = Matrix.__pool.get();
		matrix.identity();

		__getBounds(rect, matrix);

		if (value != rect.width) {
			scaleX = value / rect.width;
		} else {
			scaleX = 1;
		}

		Rectangle.__pool.release(rect);
		Matrix.__pool.release(matrix);

		return value;
	}

	private function get_x():Float {
		return __transform.tx;
	}

	private function set_x(value:Float):Float {
		if (value != __transform.tx)
			__setTransformDirty();
		return __transform.tx = value;
	}

	private function get_y():Float {
		return __transform.ty;
	}

	private function set_y(value:Float):Float {
		if (value != __transform.ty)
			__setTransformDirty();
		return __transform.ty = value;
	}
}
