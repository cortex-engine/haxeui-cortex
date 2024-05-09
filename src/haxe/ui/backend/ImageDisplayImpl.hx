package haxe.ui.backend;

// import RayLib.*;
// import RayLib.Texture2D;
// import RayLib.Colors.*;
// import RayLib.Rectangle;
// import RayLib.Vector2;

import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;

class ImageDisplayImpl extends ImageBase {
    // private var _texture:Texture2D;
    
    private override function validateData() {
        if (_imageInfo != null) {
            dispose();
            // _texture = _imageInfo.data.texture;
            if (_imageWidth <= 0) {
                _imageWidth = _imageInfo.width;
            }
            if (_imageHeight <= 0) {
                _imageHeight = _imageInfo.height;
            }
            aspectRatio = _imageInfo.width / _imageInfo.height;
        } else {
            dispose();
            _imageWidth = 0;
            _imageHeight = 0;
        }
    }
    
    public function draw(x:Int, y:Int) {
        var ix = x + _left;
        var iy = y + _top;

         Nvg.save(NanovgHelper.vg);

        if (_imageWidth != _imageInfo.width || _imageHeight != _imageInfo.height) {
            // var source = Rectangle.create(0, 0, _imageInfo.width, _imageInfo.height);
            // var dest = Rectangle.create(Std.int(ix), Std.int(iy), _imageWidth, _imageHeight);
            // var origin = Vector2.create(0, 0);
            // DrawTexturePro(_texture, source, dest, origin, 0, WHITE);


        } else {
            // DrawTexture(_texture, Std.int(ix), Std.int(iy), WHITE);
            Nvg.translate(NanovgHelper.vg, ix, iy);
            
            // var imgHeight = t.height * (image.h / t.height);
            var imagePattern = Nvg.imagePattern(NanovgHelper.vg, 
                0, 0, 
                _imageInfo.width, 
                _imageInfo.height, 
                0, _imageInfo.data.nvgImg, 1.0 //_alpha
            );

            Nvg.beginPath(NanovgHelper.vg);
            Nvg.rect(NanovgHelper.vg, 0, 0, _imageInfo.width, _imageInfo.height);
            // the following allows to modulate the color of the image
            // imagePattern.innerColor = Nvg.rgbaf(
            //     1,
            //     0,
            //     0,
            //     1
            // );
            Nvg.fillPaint(NanovgHelper.vg, imagePattern);
            // Nvg.fillColor(NanovgHelper.vg, Nvg.rgba(255,0,0,255));
            Nvg.fill(NanovgHelper.vg);
        }

        Nvg.restore(NanovgHelper.vg);
    }
}
