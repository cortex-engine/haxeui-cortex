package haxe.ui.backend.cortex;

// import RayLib.*;
// import RayLib.Font;
import cpp.NativeArray;
import haxe.io.Bytes;
import nanovg.Nvg;
import nanovg.Nvg;

class FontHelper {
    private static var _fonts:Map<String, Int> = new Map<String, Int>();

    public static function init() {

        // _fonts.set("default", Nvg.createFont(NanovgHelper.vg, "default", "testdata/kenvector_future_thin.ttf"));
        _fonts.set("default", Nvg.createFont(NanovgHelper.vg, "default", "testdata/Roboto-Regular.ttf"));
        // _fonts.set("default", Nvg.createFont(NanovgHelper.vg, "default", "testdata/Roboto-Regular.ttf"));
        // fontSansID = Nvg.createFont(cast vg, "sans", "testdata/Roboto-Regular.ttf");

        // fontIconsID = Nvg.createFont(cast vg, "icon", "testdata/entypo.ttf");
        // fontSansBoldID = Nvg.createFont(cast vg, "sans-bold", "testdata/Roboto-Bold.ttf");
    }

    public static function shutdown() {
        for (k=>v in _fonts)
            Nvg.freeFont(NanovgHelper.vg, v);
    }
    
    public static function getFont(id:String) {
        if (_fonts.exists(id) == false) {
            return null;
        }
        var f = _fonts.get(id);
        return f;
    }
    
    public static function setFont(id:String, font:Int) {
        _fonts.set(id, font);
    }
    
    public static function hasFont(id:String) {
        return _fonts.exists(id);
    }
    
    public static function setTtfFont(id:String, size:Int, font:Int) {
        _fonts.set(id, font);
    }
    
    public static function getTtfFont(id:String, size:Int) {
        return _fonts.get(id);
    }
    
    public static function hasTtfFont(id:String, size:Int) {
        return _fonts.exists(id);
    }
    
    public static function loadTtfFont(resourceId:String, size:Int) {
        trace(resourceId);
        // if (hasTtfFont(resourceId, size)) {
        //     return getTtfFont(resourceId, size);
        // }
        // var bytes:Bytes = Resource.getBytes(resourceId);
        // // var p = NativeArray.address(bytes.getData(), 0).constRaw;
        // // var font = LoadFontFromMemory(".ttf", p, bytes.length, 32, null, 255);
        // var font = Nvg.createFontMem(NanovgHelper.vg, resourceId, bytes.getData());
        // setTtfFont(resourceId, size, font);
        // return font;
        return _fonts.get('default');
    }
}