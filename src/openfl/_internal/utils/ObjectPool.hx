package openfl._internal.utils;

import lime.utils.Log;

class ObjectPool<T:{}> {
  final construct:()->T;
  final cache:Array<T> = [];
  #if debug
  final status = new Map<T, Bool>();
  #end

  public var size(default, set):Null<Int>;
    function set_size(param) {
      this.size = param;
      if (param != null && param > cache.length)
        cache.resize(param);
      return param;
    }

  public dynamic function clean(object:T) {}

  public function new(construct:()->T, ?clean:T->Void, ?size:Int) {
    this.construct = construct;
    if (clean != null)
      this.clean = clean;
    this.size = size;
  }

  public function get()
    return switch cache.pop() {
      case null: construct();
      case o:
        #if debug
        status[o] = true;
        #end
        o;
    }

  static inline var RIDICULOUSLY_LARGE = 1 << 30;

  public function release(o:T) {
    #if debug
    switch status[o] {
      case null:
        Log.error('Object is not a member of the pool');
      case false:
        Log.error('Object has already been released');
      default:
    }
    #end
    var size = switch size {
      case null: RIDICULOUSLY_LARGE;
      case v: v;
    }
    if (cache.length < size) {
      cache.push(o);
      #if debug
      status[o] = false;
      #end
    }
    else {
      #if debug
      status.remove(o);
      #end
    }
    clean(o);
  }
}