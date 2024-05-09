package haxe.ui.backend.cortex;

import haxe.ui.events.KeyboardEvent;
import cortex.input.KeyCode;
import cortex.input.ScanCode;
import cortex.input.Types;
import cortex.utils.Signal;

class KeyboardHelper {
    public static var onKeyUp = new Signal<KeyEvent->Void>();
    public static var onKeyDown = new Signal<KeyEvent->Void>();
    public static var onKeyPress = new Signal<KeyEvent->Void>();
    public static var onTextInput = new Signal<TextInputEvent->Void>();
    
    static var eventBuffer = [];
    public static function onInput(_evt:IInputEvent) {
        if (_evt is KeyEvent || _evt is TextInputEvent)
            eventBuffer.push(_evt);
    }    
    
    private static var _downKeys:Map<Int, Int> = new Map<Int, Int>();
    public static function update() {
        for (_evt in eventBuffer) {
            if (_evt is KeyEvent) {
                var ke:KeyEvent = cast _evt;
                if (ke.down) {
                    if (ke.repeat)
                        onKeyPress.emit(ke);
                    else
                        onKeyDown.emit(ke);
                } else
                    onKeyUp.emit(ke);
            } else if (_evt is TextInputEvent) {
                var te:TextInputEvent = cast _evt;
                onTextInput.emit(te);
            }
        }
        eventBuffer = [];

        // var keyCode = GetKeyPressed();
        // while (keyCode > 0) {
        //     var key = GetCharPressed();
        //     _downKeys.set(keyCode, key);
        //     onKeyDown(key, keyCode);
        //     keyCode = GetKeyPressed();  // Check next character in the queue
        // }
        
        // var newMap:Map<Int, Int> = new Map<Int, Int>();
        // for (downKeyCode in _downKeys.keys()) {
        //     var downKey = _downKeys.get(downKeyCode);
        //     if (IsKeyDown(downKeyCode) == false) {
        //         onKeyPress(downKey, downKeyCode);
        //         onKeyUp(downKey, downKeyCode);
        //     } else {
        //         newMap.set(downKeyCode, downKey);
        //     }
        // }
        
        // _downKeys = newMap;
    }

    // public static function notify(event:String, callback:KeyboardEvent->Void) {
    //     var list = _callbacks.get(event);
    //     if (list == null) {
    //         list = new Array<KeyboardEvent->Void>();
    //         _callbacks.set(event, list);
    //     }
        
    //     list.push(callback);
    // }
    
    // public static function remove(event:String, callback:KeyboardEvent->Void) {
    //     var list = _callbacks.get(event);
    //     if (list != null) {
    //         list.remove(callback);
    //         if (list.length == 0) {
    //             _callbacks.remove(event);
    //         }
    //     }
    // }
    
    // private static function onKeyDown(key:Int, keyCode:Int) {
    //     var list = _callbacks.get(KeyboardEvent.KEY_DOWN);
    //     if (list == null || list.length == 0) {
    //         return;
    //     }
        
    //     list = list.copy();
        
    //     var event = new KeyboardEvent(KeyboardEvent.KEY_DOWN);
    //     event.data = key;
    //     event.keyCode = keyCode;
    //     for (l in list) {
    //         l(event);
    //     }
    // }
    
    // private static function onKeyUp(key:Int, keyCode:Int) {
    //     var list = _callbacks.get(KeyboardEvent.KEY_UP);
    //     if (list == null || list.length == 0) {
    //         return;
    //     }
        
    //     list = list.copy();
        
    //     var event = new KeyboardEvent(KeyboardEvent.KEY_UP);
    //     event.data = key;
    //     event.keyCode = keyCode;
    //     for (l in list) {
    //         l(event);
    //     }
    // }
    
    // private static function onKeyPress(key:Int, keyCode:Int) {
    //     var list = _callbacks.get(KeyboardEvent.KEY_PRESS);
    //     if (list == null || list.length == 0) {
    //         return;
    //     }
        
    //     list = list.copy();

    //     var event = new KeyboardEvent(KeyboardEvent.KEY_PRESS);
    //     event.data = key;
    //     event.keyCode = keyCode;
    //     for (l in list) {
    //         l(event);
    //     }
    // }
}