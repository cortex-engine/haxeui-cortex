package haxe.ui.backend;

import cortex.Cortex;
import cortex.window.Window;
import haxe.ui.backend.cortex.FontHelper;
import haxe.ui.backend.cortex.KeyboardHelper;
import haxe.ui.backend.cortex.MouseHelper;
import haxe.ui.core.Component;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

class ScreenImpl extends ScreenBase {
    private var _mapping:Map<String, UIEvent->Void>;
    
    public function new() {
        _mapping = new Map<String, UIEvent->Void>();
    }
    
    public override function get_width():Float {
        return Cortex.mainWindow.rect.w / Toolkit.scaleX;
    }

    public override function get_height() {
        return Cortex.mainWindow.rect.h / Toolkit.scaleY;
    }

    private override function get_actualWidth():Float {
        return Cortex.mainWindow.rect.w;
    }

    private override function get_actualHeight():Float {
        return Cortex.mainWindow.rect.h;
    }

    public function init() {
        FontHelper.init();
        Cortex.mainWindow.onEvent.connect(_onWindowEvent);
        Cortex.onInput.connect(haxe.ui.backend.cortex.MouseHelper.onInput);
        Cortex.onInput.connect(haxe.ui.backend.cortex.KeyboardHelper.onInput);
    }
    public function shutdown() {
        FontHelper.shutdown();
        Toolkit.assets.clear();
        Cortex.onInput.disconnect(haxe.ui.backend.cortex.KeyboardHelper.onInput);
        Cortex.onInput.disconnect(haxe.ui.backend.cortex.MouseHelper.onInput);
        Cortex.mainWindow.onEvent.disconnect(_onWindowEvent);
    }

    function _onWindowEvent(_evt:IWindowEvent) {
        if (_evt is WindowEventResized)
            resizeRootComponents();
    }
    
    public override function addComponent(component:Component):Component {
        // @:privateAccess component.recursiveReady();
        rootComponents.push(component);
        resizeComponent(component);
        return component;
    }

    public override function removeComponent(component:Component, dispose:Bool = true, invalidate:Bool = true):Component {
        rootComponents.remove(component);
        // if (component.inBounds(MouseHelper.mouseX, MouseHelper.mouseY)) {
        //     setCursor(null);
        // }
        return component;
    }
    
    public function draw() {
        for (c in rootComponents)
            c.draw();
    }
    
    public function update() {
        MouseHelper.update();
        KeyboardHelper.update();
        TimerImpl.update();
    }

    private override function supportsEvent(type:String):Bool {
        if (type == MouseEvent.MOUSE_MOVE
            || type == MouseEvent.MOUSE_DOWN
            || type == MouseEvent.MOUSE_UP) {
                return true;
            }
        return false;
    }
    
    private override function mapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_MOVE, __onMouseMove);
                }
                
            case MouseEvent.MOUSE_DOWN:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_DOWN, __onMouseDown);
                }
                
            case MouseEvent.MOUSE_UP:
                if (_mapping.exists(type) == false) {
                    _mapping.set(type, listener);
                    MouseHelper.notify(MouseEvent.MOUSE_UP, __onMouseUp);
                }
        }

    }

    private override function unmapEvent(type:String, listener:UIEvent->Void) {
        switch (type) {
            case MouseEvent.MOUSE_MOVE:
                _mapping.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_MOVE, __onMouseMove);
                
            case MouseEvent.MOUSE_DOWN:
                _mapping.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_DOWN, __onMouseDown);
                
            case MouseEvent.MOUSE_UP:
                _mapping.remove(type);
                MouseHelper.remove(MouseEvent.MOUSE_UP, __onMouseUp);
        }
    }
    
    private function __onMouseMove(event:MouseEvent) {
        if (_mapping.exists(MouseEvent.MOUSE_MOVE) == false) {
            return;
        }

        var x = event.screenX;
        var y = event.screenY;
        
        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_MOVE);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(haxe.ui.events.MouseEvent.MOUSE_MOVE)(mouseEvent);
    }

    private function __onMouseDown(event:MouseEvent) {
        if (_mapping.exists(MouseEvent.MOUSE_DOWN) == false) {
            return;
        }

        var x = event.screenX;
        var y = event.screenY;
        
        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_DOWN);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(haxe.ui.events.MouseEvent.MOUSE_DOWN)(mouseEvent);
    }

    private function __onMouseUp(event:MouseEvent) {
        if (_mapping.exists(MouseEvent.MOUSE_UP) == false) {
            return;
        }

        var x = event.screenX;
        var y = event.screenY;
        
        var mouseEvent = new MouseEvent(MouseEvent.MOUSE_UP);
        mouseEvent.screenX = x / Toolkit.scaleX;
        mouseEvent.screenY = y / Toolkit.scaleY;
        _mapping.get(MouseEvent.MOUSE_UP)(mouseEvent);
    }
}