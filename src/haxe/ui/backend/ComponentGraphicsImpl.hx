package haxe.ui.backend;

import cpp.NativeArray;
import haxe.io.Bytes;
import haxe.ui.core.Component;
import haxe.ui.geom.Point;
// import RayLib.*;
// import RayLib.Vector2;
// import RayLib.Image;
// import RayLib.ImageRef;
// import RayLib.Colors;
// import RayLib.Texture;
// import RayLib.TextureRef;
// import RayLib.PixelFormat;
import haxe.ui.util.Color;
import haxe.ui.backend.cortex.StyleHelper;
import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;


class ComponentGraphicsImpl extends ComponentGraphicsBase {
    public function new(component:Component) {
        super(component);
    }

    private var _image:Int = -1;
    private var _lastBytes:Bytes = null;

    public function draw() {
        var currentPosition:Point = new Point();
        var currentStrokeColor:Color = -1;
        var currentStrokeThickness:Float = 1;
        var currentStrokeAlpha:Int = 255;
        var currentFillColor:Color = -1;
        var currentFillAlpha:Int = 255;

        var sx = Std.int(_component.screenLeft);
        var sy = Std.int(_component.screenTop);
        var w = Std.int(_component.width);
        var h = Std.int(_component.height);

        Nvg.save(NanovgHelper.vg);
        Nvg.translate(NanovgHelper.vg, sx, sy);

        for (command in _drawCommands) {
            switch (command) {
                case Clear:
                    // Nvg.beginPath(NanovgHelper.vg);
                    // Nvg.rect(NanovgHelper.vg, sx, sy, w, h);
                    // Nvg.fillColor(NanovgHelper.vg, Nvg.rgbaf(0,0,0,0.1));
                    // Nvg.fill(NanovgHelper.vg);
        //             DrawRectangle(sx,
        //                           sy,
        //                           w,
        //                           h,
        //                           RayLib.Colors.RAYWHITE);
                case MoveTo(x, y):
                    Nvg.beginPath(NanovgHelper.vg);
                    Nvg.moveTo(NanovgHelper.vg, x, y);

                case LineTo(x, y):
                    Nvg.lineTo(NanovgHelper.vg, x, y);
                    Nvg.stroke(NanovgHelper.vg);

                case ClosePath:
                    Nvg.closePath(NanovgHelper.vg);

                case StrokeStyle(color, thickness, alpha):
                    if (thickness != null)
                        Nvg.strokeWidth(NanovgHelper.vg, thickness);
                    if (color != null) {
                        Nvg.strokeColor(NanovgHelper.vg, StyleHelper.col(color, alpha != null ? alpha : 1));
                        currentStrokeColor = color;
                    } else {
                        Nvg.strokeColor(NanovgHelper.vg, Nvg.rgbaf(0,0,0,0));
                        currentStrokeColor = -1;
                    }

                case FillStyle(color, alpha):
                    // trace(color);
                    // trace(alpha);
                    if (color != null) {
                        Nvg.fillColor(NanovgHelper.vg, StyleHelper.col(color, alpha != null ? alpha : 1));
                        currentFillColor = color;
                    } else {
                        Nvg.fillColor(NanovgHelper.vg, Nvg.rgbaf(0,0,0,0));
                        currentFillColor = -1;
                    }

                case Circle(x, y, radius):
                    if (currentFillColor != -1) {
                        Nvg.save(NanovgHelper.vg);
                        Nvg.beginPath(NanovgHelper.vg);
                        Nvg.circle(NanovgHelper.vg, x, y, radius);
                        // Nvg.fillColor(NanovgHelper.vg, StyleHelper.col(currentFillColor, 1));
                        Nvg.fill(NanovgHelper.vg);
                        Nvg.restore(NanovgHelper.vg);
                    }
                    if (currentStrokeColor != -1) {
                        Nvg.save(NanovgHelper.vg);
                        Nvg.beginPath(NanovgHelper.vg);
                        Nvg.circle(NanovgHelper.vg, x, y, radius);
                        // Nvg.strokeColor(NanovgHelper.vg, Nvg.rgbaf(1, 0, 0, 1));
                        Nvg.stroke(NanovgHelper.vg);
                        Nvg.restore(NanovgHelper.vg);
                    }

                case CurveTo(controlX, controlY, anchorX, anchorY):
                    Nvg.quadTo(NanovgHelper.vg, controlX, controlY, anchorX, anchorY);
                    Nvg.stroke(NanovgHelper.vg);

                case CubicCurveTo(controlX1, controlY1, controlX2, controlY2, anchorX, anchorY):
                    Nvg.bezierTo(NanovgHelper.vg, controlX1, controlY1, controlX2, controlY2, anchorX, anchorY);
                    Nvg.stroke(NanovgHelper.vg);

                case Rectangle(x, y, width, height):
                    if (currentFillColor != -1) {
                        Nvg.save(NanovgHelper.vg);
                        Nvg.beginPath(NanovgHelper.vg);
                        Nvg.rect(NanovgHelper.vg, sx + x, sy + y, width, height);
                        Nvg.fillColor(NanovgHelper.vg, Nvg.rgbaf(currentFillColor.r,
                                                     currentFillColor.g,
                                                     currentFillColor.b,
                                                     currentFillAlpha));
                        Nvg.fill(NanovgHelper.vg);
                        Nvg.restore(NanovgHelper.vg);
                    }
               case SetPixel(x, y, color):
               case SetPixels(pixels):
                   if (_image == -1) {
                       _image = Nvg.createImageRGBA(NanovgHelper.vg, Std.int(_component.width), Std.int(_component.height), 0x0, pixels.getData());
                       _lastBytes = pixels;
                    } else /*if (_lastBytes != pixels)*/ {
                       _lastBytes = pixels;
                       Nvg.updateImage(NanovgHelper.vg, _image, pixels.getData());
                    }
                    
                    Nvg.save(NanovgHelper.vg);
                    var imagePattern = Nvg.imagePattern(NanovgHelper.vg, 0, 0, _component.width, _component.height, 0, _image, 1.0);

                    Nvg.beginPath(NanovgHelper.vg);
                    Nvg.rect(NanovgHelper.vg, 0, 0, _component.width, _component.height);
                    Nvg.fillPaint(NanovgHelper.vg, imagePattern);
                    Nvg.fill(NanovgHelper.vg);
                    Nvg.restore(NanovgHelper.vg);


        //        case Image(resource, x, y, width, height):
                default:
            }
        }
        Nvg.restore(NanovgHelper.vg);
    }
}