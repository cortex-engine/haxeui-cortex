package haxe.ui.backend.cortex;

import haxe.ui.events.MouseEvent;
import cortex.input.Types;

class MouseHelper {
    private static var _callbacks:Map<String, Array<MouseEvent->Void>> = new Map<String, Array<MouseEvent->Void>>();
    
    public static var mouseX:Int = 0;
    public static var mouseY:Int = 0;

    static var eventBuffer = [];
    
    public static function onInput(_evt:IInputEvent) {
        if (_evt is MouseMotionEvent || _evt is MouseWheelEvent || _evt is MouseButtonEvent)
            eventBuffer.push(_evt);
    }

    public static function notify(event:String, callback:MouseEvent->Void) {
        var list = _callbacks.get(event);
        if (list == null) {
            list = new Array<MouseEvent->Void>();
            _callbacks.set(event, list);
        }
        
        if (!list.contains(callback)) {
            list.push(callback);
        }
    }
    
    public static function update() {
        for (_evt in eventBuffer) {
            if (_evt is MouseMotionEvent) {
                var me:MouseMotionEvent = cast _evt;
                if (me.x != mouseX || me.y != mouseY) {
                    mouseX = me.x;
                    mouseY = me.y;
                    onMouseMove(mouseX, mouseY);
                }
            } else if (_evt is MouseButtonEvent) {
                var be:MouseButtonEvent = cast _evt;
                mouseX = be.x;
                mouseY = be.y;
                // trace(be.button);
                if (be.down)
                    onMouseDown(be.button-1, mouseX, mouseY);
                else
                    onMouseUp(be.button-1, mouseX, mouseY);
            } else if (_evt is MouseWheelEvent) {
                var we:MouseWheelEvent = cast _evt;
                onMouseWheel(we.y);
            }
        }
        eventBuffer = [];
    }
    
    public static function remove(event:String, callback:MouseEvent->Void) {
        var list = _callbacks.get(event);
        if (list != null) {
            list.remove(callback);
            if (list.length == 0) {
                _callbacks.remove(event);
            }
        }
    }
    
    private static function onMouseDown(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_DOWN);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_DOWN);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseUp(button:Int, x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_UP);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_UP);
        event.screenX = x;
        event.screenY = y;
        event.data = button;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseMove(x:Int, y:Int) {
        var list = _callbacks.get(MouseEvent.MOUSE_MOVE);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_MOVE);
        event.screenX = x;
        event.screenY = y;
        for (l in list) {
            l(event);
        }
    }
    
    private static function onMouseWheel(delta:Float) {
        var list = _callbacks.get(MouseEvent.MOUSE_WHEEL);
        if (list == null || list.length == 0) {
            return;
        }
        
        list = list.copy();
        
        var event = new MouseEvent(MouseEvent.MOUSE_WHEEL);
        event.delta = delta;
        event.screenX = mouseX;
        event.screenY = mouseY;
        for (l in list) {
            l(event);
        }
    }
    
    private static var _cursor:String = null;
    public static var cursor(get, set):String;
    private static function get_cursor():String {
        return _cursor;
    }
    private static function set_cursor(value:String):String {
        if (_cursor == value) {
            return value;
        }
        
        _cursor = value;
        // if (_cursor == null) {
        //     SetMouseCursor(MouseCursor.DEFAULT);
        // } else {
        //     switch (_cursor) {
        //         case "pointer":
        //             SetMouseCursor(MouseCursor.POINTING_HAND);
        //     }
        // }
        
        return value;
    }
}