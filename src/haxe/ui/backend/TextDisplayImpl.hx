package haxe.ui.backend;

// import RayLib.*;
// import RayLib.Font;
// import RayLib.Vector2;
import haxe.ui.backend.cortex.FontHelper;
import haxe.ui.backend.cortex.StyleHelper;
import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;

// might want to port this: https://github.com/mattdesl/word-wrapper/blob/master/index.js

class TextDisplayImpl extends TextBase {
    private var _textAlign:String;
    private var _fontSize:Int = 13;
    private var _fontName:String;
    private var _color:Int;
    private var _currentFontName:String = "default";
    private var _currentFont:Int;
    
    public function new() {
        super();
        _currentFont = FontHelper.getFont(_currentFontName);
    }
    
    private override function validateData() {
        if (_text != null) {
            if (_dataSource == null) {
                _text = normalizeText(_text);
            }
        }
    }
    
    private override function validateStyle():Bool {
        var measureTextRequired:Bool = false;
        
        if (_textStyle != null) {
            if (_textAlign != _textStyle.textAlign) {
                _textAlign = _textStyle.textAlign;
                measureTextRequired = true;
            }
            
            if (_textStyle.color != null && _color != _textStyle.color) {
                _color = _textStyle.color;
            }
            
            if (_textStyle.fontSize != null && _fontSize != _textStyle.fontSize) {
                _fontSize = Std.int(_textStyle.fontSize);
                measureTextRequired = true;
            }
            
            if (_textStyle.fontName != null && _textStyle.fontName != _currentFontName && this._fontInfo != null && this._fontInfo.data != null) {
                _currentFontName = _textStyle.fontName;
                if (StringTools.endsWith(_currentFontName, ".ttf")) {
                    _currentFont = FontHelper.loadTtfFont(_currentFontName, _fontSize);
                } else {
                    _currentFont = this._fontInfo.data;
                }
                measureTextRequired = true;
            }
        }
        
        return measureTextRequired;
    }
    
    private override function validateDisplay() {
        if (_width == 0 && _textWidth > 0) {
            _width = _textWidth;
        }
        if (_height == 0 && _textHeight > 0) {
            _height = _textHeight;
        }
    }

    // private var _lines:Array<String>;
    var yOffset = 0.0;
    var xOffset = 0.0;
    private override function measureText() {

        Nvg.fontFaceId(NanovgHelper.vg, _currentFont);
        Nvg.fontSize(NanovgHelper.vg, _fontSize * Toolkit.scale);

        if (_text == null || _text.length == 0 ) {
            _textWidth = 0;
            _textHeight = _fontSize;
            return;
        }

        // var spacing = Std.int(_fontSize / _currentFont.baseSize);
        
        if (_width <= 0) {
            var bounds:Array<cpp.Float32> = [0.0,0,0,0];
            Nvg.textBounds(NanovgHelper.vg, 0, 0, _text, null, bounds);
            _textWidth = bounds[2]-bounds[0];
            _textHeight = bounds[3]-bounds[1];
            xOffset = -bounds[0];
            yOffset = -bounds[1];
            return;
        }
        _text = normalizeText(_text);

        var maxWidth:Float = _width * Toolkit.scale;
        var bounds:Array<cpp.Float32> = [0.0,0,0,0];
        Nvg.textBoxBounds(NanovgHelper.vg, 0, 0, maxWidth, _text, null, bounds);
        
        _textWidth = bounds[2]-bounds[0];
        _textHeight = bounds[3]-bounds[1];  
        xOffset = -bounds[0];
        yOffset = -bounds[1];
        
    }

    public function draw(x:Int, y:Int) {

        // trace(x);
        var align = 0x0;
        var tx:Float = x + xOffset;
        var ty:Float = y + yOffset;
        switch(_textAlign) {
            case "center":
                align |= NvgAlign.ALIGN_CENTER;
                tx += ((_width - _textWidth) * Toolkit.scale) / 2;

            case "right":
                align |= NvgAlign.ALIGN_RIGHT;
                tx += (_width - _textWidth) * Toolkit.scale;

            default:
                align |= NvgAlign.ALIGN_LEFT;
        }

        // align |= NvgAlign.ALIGN_TOP;

        // Nvg.beginPath(NanovgHelper.vg);
        // Nvg.rect(NanovgHelper.vg, x, y, _width, _height);
        // Nvg.fillColor(NanovgHelper.vg, Nvg.rgba(255,0,0,255));
        // Nvg.fill(NanovgHelper.vg);

        // Nvg.beginPath(NanovgHelper.vg);
        // Nvg.rect(NanovgHelper.vg, x, y, _textWidth, _textHeight);
        // Nvg.fillColor(NanovgHelper.vg, Nvg.rgba(0,255,0,255));
        // Nvg.fill(NanovgHelper.vg);

        Nvg.fontFaceId(NanovgHelper.vg, _currentFont);
        Nvg.fontSize(NanovgHelper.vg, _fontSize * Toolkit.scale);
        Nvg.fillColor(NanovgHelper.vg, StyleHelper.col(_color));
        Nvg.textAlign(NanovgHelper.vg, align);
        Nvg.textBox(NanovgHelper.vg, Math.ceil(tx), Math.ceil(ty), _textWidth+1, _text, null);

        // if (_lines != null) {
        //     var spacing = Std.int(_fontSize / _currentFont.baseSize);
        //     var ty:Float = y + _top;
        //     for (line in _lines) {
        //         var tx:Float = x;
        //         var lx:Int = Std.int(MeasureTextEx(_currentFont, line, _fontSize, spacing).x);
            
        //         switch(_textAlign) {
        //             case "center":
        //                 tx += ((_width - lx) * Toolkit.scale) / 2;

        //             case "right":
        //                 tx += (_width - lx) * Toolkit.scale;

        //             default:
        //                 tx += _left;
        //         }

        //         //DrawText(line, Std.int(tx), Std.int(ty), _fontSize, StyleHelper.col(_color));
        //         DrawTextEx(_currentFont, line, Vector2.create(Std.int(tx), Std.int(ty)), _fontSize, spacing, StyleHelper.col(_color));
        //         ty += _fontSize;
        //     }
        // }

    }
    
    private function normalizeText(text:String):String {
        text = StringTools.replace(text, "\\n", "\n");
        return text;
    }
}
