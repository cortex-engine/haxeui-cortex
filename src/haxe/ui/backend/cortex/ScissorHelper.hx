package haxe.ui.backend.cortex;

import haxe.ui.geom.Rectangle;
// import RayLib.*;

import nanovg.Nvg;

typedef ScissorEntry = {
    var rect:Rectangle;
}

class ScissorHelper {
    private static var _stack:Array<ScissorEntry> = new Array<ScissorEntry>();
    private static var _pos:Int = 0;
     
    public static function pushScissor(x:Float, y:Float, w:Float, h:Float):Void {
        if (_pos + 1 > _stack.length) {
            _stack.push({
                rect: new Rectangle(),
            });
        }
        var entry = _stack[_pos];
        entry.rect.set(x, y, w, h);
        _pos++;
        
        applyScissor(x, y, w, h);
    }
    
    public static function popScissor():Void {
        _pos--;
        if (_pos == 0) {
            // EndScissorMode();
            Nvg.resetScissor(NanovgHelper.vg);
        } else {
            var entry = _stack[_pos - 1];
            applyScissor(Std.int(entry.rect.left), Std.int(entry.rect.top), Std.int(entry.rect.width), Std.int(entry.rect.height));
        }
    }
    
    private static var _cacheRect:Rectangle = new Rectangle();
    private static function applyScissor(x:Float, y:Float, w:Float, h:Float):Void {
        if (_pos > 1) {
            var entry = _stack[_pos - 2];
            _cacheRect.set(x, y, w, h);
            var intersection = entry.rect.intersection(_cacheRect);
            x = Math.ceil(intersection.left);
            y = Math.ceil(intersection.top);
            w = Math.ceil(intersection.width);
            h = Math.ceil(intersection.height);
            if (x < entry.rect.left) {
                x = Std.int(entry.rect.left);
            }
            if (y < entry.rect.top) {
                y = Std.int(entry.rect.top);
            }
        }
        // BeginScissorMode(x, y, w, h);
        Nvg.scissor(NanovgHelper.vg, x, y, w, h);
    }
}    
