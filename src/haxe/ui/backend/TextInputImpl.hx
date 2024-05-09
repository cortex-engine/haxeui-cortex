package haxe.ui.backend;

import haxe.ui.events.UIEvent;
import haxe.ui.backend.cortex.TextField;
import haxe.ui.backend.cortex.FontHelper;
import haxe.ui.backend.cortex.StyleHelper;
import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;

class TextInputImpl extends TextBase {
    public var _tf:TextField;

    private var _textAlign:String;
    private var _fontSize:Float = 14;
    private var _fontName:String = "default";
    private var _color:Int = -1;
    private var _backgroundColor:Int = -1;
    
    public function new() {
        super();
        _tf = new TextField();
        _tf.notify(onTextChanged, onCaretMoved);
    }

    public override function focus() {
        registerEvents();
        _tf.focus();
    }
    
    public override function blur() {
        _tf.blur();
    }

    private var _eventsRegistered:Bool = false;
    private function registerEvents() {
        if (_eventsRegistered) {
            return;
        }
        _eventsRegistered = true;
        parentComponent.registerEvent(UIEvent.HIDDEN, onParentHidden);
    }

    private function unregisterEvents() {
        if (parentComponent != null) {
            parentComponent.unregisterEvent(UIEvent.HIDDEN, onParentHidden);
        }
        _eventsRegistered = false;
    }

    private function onParentHidden(_) {
        blur();
    }
    
    private function onTextChanged(text) {
        if (text == _text)
            return;

        _text = text;
        // measureText();
        if (_inputData.onChangedCallback != null) {
            _inputData.onChangedCallback();
        }
    }
    
    private function onCaretMoved(pos) {
        _inputData.hscrollPos = _tf.scrollLeft;
        _inputData.vscrollPos = _tf.scrollTop;
        if (_inputData.onScrollCallback != null) {
            _inputData.onScrollCallback();
        }
    }
    
    private override function validateData() {
        if (_text != null) {
            _tf.text = normalizeText(_text);
        }
        
        _tf.scrollLeft = _inputData.hscrollPos;
        _tf.scrollTop = Std.int(_inputData.vscrollPos);
    }
    
    private override  function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        // if (_textStyle != null) {
        //     _tf.multiline = _displayData.multiline;
        //     if (_tf.multiline == true) {
        //         offset = 4;
        //         measureTextRequired = true;
        //     }
        //     _tf.wordWrap = _displayData.wordWrap;
        //     _tf.password = _inputData.password;
            
        //     if (_textAlign != _textStyle.textAlign) {
        //         _textAlign = _textStyle.textAlign;
        //     }
            
        //     if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
        //         _fontSize = _textStyle.fontSize;
        //         _tf.fontSize = Std.int(_fontSize);
        //         measureTextRequired = true;
        //     }
            
        //     if (_fontName != _textStyle.fontName && _fontInfo != null) {
        //         _fontName = _textStyle.fontName;
        //         measureTextRequired = true;
        //     }
            
        //     if (_textStyle.color != null && _color != _textStyle.color) {
        //         _color = _textStyle.color;
        //         _tf.textColor = StyleHelper.col(_textStyle.color);
        //     }
            
        //     if (_textStyle.backgroundColor != null && _backgroundColor != _textStyle.backgroundColor) {
        //         _backgroundColor = _textStyle.backgroundColor;
        //         _tf.backgroundColor = StyleHelper.col(_textStyle.backgroundColor);
        //     }
            
        // }

        if (_textStyle != null) {
            _tf.multiline = _displayData.multiline;
            _tf.wordWrap = _displayData.wordWrap;
            _tf.password = _inputData.password;
            
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = _textStyle.fontSize;
                _tf.fontSize = Std.int(_fontSize);
                measureTextRequired = true;
            }
            
            if (_fontName != _textStyle.fontName && _fontInfo != null) {
                _fontName = _textStyle.fontName;
                // _font = _fontInfo.data;
                // _tf.font = _font;
                _tf.font = _fontName;
                measureTextRequired = true;
            }
            
            if (_textStyle.color != null && _color != _textStyle.color) {
                _color = _textStyle.color;
                _tf.textColor = StyleHelper.col(_textStyle.color);
            }
            
            if (_textStyle.backgroundColor != null && _backgroundColor != _textStyle.backgroundColor) {
                _backgroundColor = _textStyle.backgroundColor;
                _tf.backgroundColor = StyleHelper.col(_textStyle.backgroundColor);
            }
            
        }
        
        return measureTextRequired;
    }
    
    private override function validateDisplay() {
        if (_width > 0) {
            _tf.width = _width;
        }
        if (_height > 0) {
            _tf.height = _height;
        }
    }

    public function draw(x:Float, y:Float) {
        _tf.left = x + _left;
        _tf.top = y + _top + 1;
        _tf.draw();
    }
    
    var yOffset = 0.0;
    var xOffset = 0.0;
    private override function measureText() {
        if (_fontName == null) {
            return;
        }
        
        if (_text == null || _text.length == 0) {
            _textWidth = 0;
            _textHeight = Std.int(_fontSize);
            return;
        }

        Nvg.fontFaceId(NanovgHelper.vg, FontHelper.getFont('default'));
        Nvg.fontSize(NanovgHelper.vg, _fontSize * Toolkit.scale);

        if (_width <= 0) {
            var bounds:Array<cpp.Float32> = [0.0,0,0,0];
            Nvg.textBounds(NanovgHelper.vg, 0, 0, _text, null, bounds);
            _textWidth = bounds[2]-bounds[0];
            _textHeight = bounds[3]-bounds[1];
            xOffset = -bounds[0];
            yOffset = -bounds[1];
            return;
        }

        _tf.width = _width;
        _textWidth = _tf.requiredWidth;
        _textHeight = _tf.requiredHeight;

        if (_textHeight <= 0) {
            _textHeight = Std.int(_fontSize);
        }
        _textHeight += 2;
        
        _inputData.hscrollMax = _tf.requiredWidth - _tf.width;
        _inputData.hscrollPageSize = (_tf.width * _inputData.hscrollMax) / _tf.requiredWidth;
        
        _inputData.vscrollMax = _tf.numLines - _tf.maxVisibleLines;
        _inputData.vscrollPageSize = (_tf.maxVisibleLines * _inputData.vscrollMax) / _tf.numLines;
    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }

    public override function dispose() {
        unregisterEvents();

        // if (_tf != null) {
        //     _tf.destroy();
        //     _tf = null;
        // }

        super.dispose();
    }
}
