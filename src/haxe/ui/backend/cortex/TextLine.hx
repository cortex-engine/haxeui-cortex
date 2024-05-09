package haxe.ui.backend.cortex;

import cortex.math.MathUtils;
import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;

typedef GlyphArray = Array<Array<Float>>;

@:cppFileCode('#include "linc_bgfx.h"')
class TextLine {
    public var glyphs:GlyphArray = [];
    public var text:String = "";

    public var length(get, null):Int;
    private function get_length():Int return glyphs.length;

    public function new(_str:String) {
        setText(_str);
    }

    public function setText(_str:String) {
        text = _str;
        glyphs = Nvg.textGlyphPositions(NanovgHelper.vg, 0, 0, text, 2048);
        // var bounds = [];
        // Nvg.textBounds(NanovgHelper.vg, glyphs[_start][0], 0, text.substring(_start, _end), null, bounds);
        // trace(text);
        // trace(glyphs);
    }

    public function recalc()
    	glyphs = Nvg.textGlyphPositions(NanovgHelper.vg, 0, 0, text, 2048);

    public function getMaxx():Float 
        return glyphs[glyphs.length-1][2];

    public function getMinx():Float 
        return glyphs[0][1];

    public function getWidthFromTo(_start:Int, _end:Int):Float {
        if (glyphs.length == 0 || _start == _end) return 0;

        // x, minx, maxx
        var e = _end-1;

        var s = _start == 0 ? 0 : glyphs[_start][1]; // text.charCodeAt(_start)==' '.code ? 0 : 1
        var e = e == length-1 ? glyphs[e][2] : glyphs[e+1][1];
        return e-s;

        // return Nvg.textBounds(NanovgHelper.vg, glyphs[_start][0], 0, text.substring(_start, _end), null, []);
        // minx

        // if (_length == 0)
        //     return 0;
        // else {
        //     // var res = 0.0;
        //     // for (i in _start..._start+_length)
        //     //     res += glyphs[i][0];
        //     // return res;
        //     return glyphs[_start+_length-1][2] - glyphs[_start][0];
        // }
        // trace(text.substring(_start, length) + ' $_start, $_length');
        // return 
    }
}