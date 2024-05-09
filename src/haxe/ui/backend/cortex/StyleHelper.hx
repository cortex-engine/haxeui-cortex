package haxe.ui.backend.cortex;

import haxe.ui.assets.ImageInfo;
import haxe.ui.filters.DropShadow;
import haxe.ui.filters.Filter;
import haxe.ui.styles.Style;
import haxe.ui.geom.Rectangle;
import haxe.ui.geom.Slice9;
import nanovg.Nvg;

@:unreflective
class StyleHelper {

    public static inline function col(c:Int, opacity:Float = 1) {
        return Nvg.rgba((c & 0xff0000) >> 16, (c & 0x00ff00) >> 8, (c & 0x0000ff), Std.int(opacity * 255));
    }

    public static function drawRectangle(_x:Float, _y:Float, _w:Float, _h:Float, _color:NvgColor, _borderRadius:Null<Float>) {
        Nvg.save(NanovgHelper.vg);
        Nvg.beginPath(NanovgHelper.vg);
        drawRect(_x, _y, _w, _h, _borderRadius);
        Nvg.fillColor(NanovgHelper.vg, _color);
        Nvg.fill(NanovgHelper.vg);
        Nvg.restore(NanovgHelper.vg);
    }

    inline static function drawRect(_x:Float, _y:Float, _w:Float, _h:Float, _borderRadius:Null<Float>) {
        if (_borderRadius != null && _borderRadius > 1) {
            var max = cortex.math.MathUtils.fmin(_borderRadius, cortex.math.MathUtils.fmin(_w, _h) * 0.5);
            Nvg.roundedRect(NanovgHelper.vg, _x, _y, _w, _h, max);
        }
        else
            Nvg.rect(NanovgHelper.vg, _x, _y, _w, _h);
    }

    public static function drawStyle(style:Style, xpos:Float, ypos:Float, width:Float, height:Float, opacity:Float = 1):Void {
        var x = Math.ceil(xpos * Toolkit.scale);
        var y = Math.ceil(ypos * Toolkit.scale);
        var w = Math.ceil(width * Toolkit.scale);
        var h = Math.ceil(height * Toolkit.scale);

        if (w == 0 || height == 0) {
            return;
        }

        var innerShadow:DropShadow = null;

        if (style.filter != null) {
            var f:Filter = style.filter[0];
            if (f is DropShadow) {
                var dropShadow:DropShadow = cast(f, DropShadow);
                if (dropShadow.inner == true)
                    innerShadow = dropShadow;
                else
                    drawDropShadow(x, y, w, h, style, dropShadow);
            }
        }

        Nvg.save(NanovgHelper.vg);
        if (style.backgroundColor != null) {
            var backgroundOpacity:Float = opacity;
            if (style.backgroundOpacity != null) {
                backgroundOpacity = style.backgroundOpacity;
            }
            if (style.backgroundColorEnd != null && style.backgroundColor != style.backgroundColorEnd) {
                var gradientType:String = "vertical";
                if (style.backgroundGradientStyle != null) {
                    gradientType = style.backgroundGradientStyle;
                }

                Nvg.beginPath(NanovgHelper.vg);
                var gradient:NvgPaint = new NvgPaint();
                if (gradientType == "vertical") {
                    // DrawRectangleGradientV(x, y, w, h, col(style.backgroundColor), col(style.backgroundColorEnd, backgroundOpacity));
                    gradient = Nvg.linearGradient(NanovgHelper.vg, x,y,x,y+h, col(style.backgroundColor, backgroundOpacity), col(style.backgroundColorEnd, backgroundOpacity));
                } else /*if (gradientType == "horizontal")*/ {
                    gradient = Nvg.linearGradient(NanovgHelper.vg, x+w,y,x,y, col(style.backgroundColorEnd, backgroundOpacity), col(style.backgroundColor, backgroundOpacity));
                }
                drawRect(x, y, w, h, style.borderRadius);
                Nvg.fillPaint(NanovgHelper.vg, gradient);
                Nvg.fill(NanovgHelper.vg);
            } else {
                // DrawRectangle(x, y, w, h, col(style.backgroundColor, backgroundOpacity));
                Nvg.beginPath(NanovgHelper.vg);
                drawRect(x, y, w, h, style.borderRadius);
                Nvg.fillColor(NanovgHelper.vg, col(style.backgroundColor, backgroundOpacity));
                Nvg.fill(NanovgHelper.vg);
            }
        }

        if (style.backgroundImage != null) {
            Toolkit.assets.getImage(style.backgroundImage, function(_imageInfo:ImageInfo) {
                if (_imageInfo == null) {
                    return;
                }

                // var imageRect:Rectangle = new Rectangle(0, 0, _imageInfo.width, _imageInfo.height);
                var slice:Rectangle = null;
                if (style.backgroundImageSliceTop != null &&
                    style.backgroundImageSliceLeft != null &&
                    style.backgroundImageSliceBottom != null &&
                    style.backgroundImageSliceRight != null) {
                    slice = new Rectangle(style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceTop,
                                          style.backgroundImageSliceRight - style.backgroundImageSliceLeft,
                                          style.backgroundImageSliceBottom - style.backgroundImageSliceTop);
                }

                var ix = x;
                var iy = y;

                var iw = w;
                var ih = h;

                // var cols = [0xFF0000, 0x00FF00, 0x0000FF, 0xFF00FF, 0xFFFFFF, 0x000000, 0xCD0000, 0x00CD00];

                if (slice != null) {
                    var rects:Slice9Rects = Slice9.buildRects(w, h, _imageInfo.width, _imageInfo.height, slice);

                    Nvg.save(NanovgHelper.vg);
                    Nvg.translate(NanovgHelper.vg, x, y);

                    for (i in 0...rects.src.length) {
                        // trace('$i: ${rects.dst[i]}');

                        var ax = rects.dst[i].width / rects.src[i].width;
                        var ay = rects.dst[i].height / rects.src[i].height;

                        var imagePattern = Nvg.imagePattern(NanovgHelper.vg,
                            rects.dst[i].left - rects.src[i].left * ax,
                            rects.dst[i].top - rects.src[i].top * ay,
                            _imageInfo.width * ax,
                            _imageInfo.height * ay,
                            0, _imageInfo.data.nvgImg, 1.0
                        );
                        Nvg.beginPath(NanovgHelper.vg);
                        Nvg.rect(NanovgHelper.vg,
                            rects.dst[i].left,
                            rects.dst[i].top,
                            rects.dst[i].width,
                            rects.dst[i].height
                        );
                        Nvg.fillPaint(NanovgHelper.vg, imagePattern);

                        // if (i < 0) {
                        //     // trace('$i: ${rects.src[i]}');
                        //     // trace('$i: ${rects.dst[i]}');
                        //     Nvg.fillPaint(NanovgHelper.vg, imagePattern);
                        // }
                        // else
                        //     Nvg.fillColor(NanovgHelper.vg, col(cols[i]));
                        Nvg.fill(NanovgHelper.vg);
                    }
                    Nvg.restore(NanovgHelper.vg);

                } else {
                    Nvg.save(NanovgHelper.vg);
                    // DrawTexture(_texture, Std.int(ix), Std.int(iy), WHITE);
                    Nvg.translate(NanovgHelper.vg, x, y);

                    // var imgHeight = t.height * (image.h / t.height);
                    var imagePattern = Nvg.imagePattern(NanovgHelper.vg,
                        0, 0,
                        iw,
                        ih,
                        0, _imageInfo.data.nvgImg, 1.0 //_alpha
                    );

                    Nvg.beginPath(NanovgHelper.vg);
                    Nvg.rect(NanovgHelper.vg, 0, 0, w, h);
                    Nvg.fillPaint(NanovgHelper.vg, imagePattern);
                    Nvg.fill(NanovgHelper.vg);
                    Nvg.restore(NanovgHelper.vg);
                }
            });
        }

        if (style.borderLeftSize != null &&
            style.borderLeftSize == style.borderRightSize &&
            style.borderLeftSize == style.borderBottomSize &&
            style.borderLeftSize == style.borderTopSize

            && style.borderLeftColor != null
            && style.borderLeftColor == style.borderRightColor
            && style.borderLeftColor == style.borderBottomColor
            && style.borderLeftColor == style.borderTopColor) { // full border

            var borderSize:Float = style.borderLeftSize;
            var bsize = (borderSize*2);

            Nvg.beginPath(NanovgHelper.vg);
            Nvg.pathWinding(NanovgHelper.vg, NvgSolidity.SOLID);
            drawRect(x+borderSize, y+borderSize, w-bsize, h-bsize, style.borderRadius);
            Nvg.pathWinding(NanovgHelper.vg, NvgSolidity.HOLE);
            drawRect(x, y, w, h, style.borderRadius);
            Nvg.fillColor(NanovgHelper.vg, col(style.borderLeftColor));
            Nvg.fill(NanovgHelper.vg);

            // DrawRectangle(x, y, w, borderSize, col(style.borderLeftColor)); // top
            // DrawRectangle(x, y + h - borderSize, w, borderSize, col(style.borderLeftColor)); // bottom
            // DrawRectangle(x, y, borderSize, h, col(style.borderLeftColor)); // left
            // DrawRectangle(x + w - borderSize, y, borderSize, h, col(style.borderLeftColor)); // right
        } else { // compound border
            if (style.borderTopSize != null && style.borderTopSize > 0) {
                Nvg.beginPath(NanovgHelper.vg);
                Nvg.rect(NanovgHelper.vg, x, y, w, Std.int(style.borderTopSize));
                Nvg.fillColor(NanovgHelper.vg, col(style.borderTopColor));
                Nvg.fill(NanovgHelper.vg);
                // DrawRectangle(x, y, w, Std.int(style.borderTopSize), col(style.borderTopColor)); // top
            }

            if (style.borderBottomSize != null && style.borderBottomSize > 0) {
                Nvg.beginPath(NanovgHelper.vg);
                Nvg.rect(NanovgHelper.vg, x, y + h - Std.int(style.borderBottomSize), w, Std.int(style.borderBottomSize));
                Nvg.fillColor(NanovgHelper.vg, col(style.borderBottomColor));
                Nvg.fill(NanovgHelper.vg);
                // DrawRectangle(x, y + h - Std.int(style.borderBottomSize), w, Std.int(style.borderBottomSize), col(style.borderBottomColor)); // bottom
            }

            if (style.borderLeftSize != null && style.borderLeftSize > 0) {
                Nvg.beginPath(NanovgHelper.vg);
                Nvg.rect(NanovgHelper.vg, x, y, Std.int(style.borderLeftSize), h);
                Nvg.fillColor(NanovgHelper.vg, col(style.borderLeftColor));
                Nvg.fill(NanovgHelper.vg);
                // DrawRectangle(x, y, Std.int(style.borderLeftSize), h, col(style.borderLeftColor)); // left
            }

            if (style.borderRightSize != null && style.borderRightSize > 0) {
                Nvg.beginPath(NanovgHelper.vg);
                Nvg.rect(NanovgHelper.vg, x + w - Std.int(style.borderRightSize), y, Std.int(style.borderRightSize), h);
                Nvg.fillColor(NanovgHelper.vg, col(style.borderRightColor));
                Nvg.fill(NanovgHelper.vg);
                // DrawRectangle(x + w - Std.int(style.borderRightSize), y, Std.int(style.borderRightSize), h, col(style.borderRightColor)); // right
            }
        }
        Nvg.restore(NanovgHelper.vg);

        if (innerShadow != null)
            drawDropShadow(x,y,w,h,style,innerShadow);
    }

    private static function drawDropShadow(x:Float, y:Float, w:Float, h:Float, _style:Style, _shadowSpec:DropShadow):Void {
        if (_shadowSpec.alpha == 0)
            _shadowSpec.alpha = 0.15;
        var shadowColor = col(_shadowSpec.color, _shadowSpec.alpha);
        var cornerMax = cortex.math.MathUtils.fmin(_style.borderRadius, cortex.math.MathUtils.fmin(w, h) * 0.5);

        if (_shadowSpec.inner == false) {
            // get shadow params
            var hOffset = _shadowSpec.distance;
            var vOffset = _shadowSpec.distance + 2;
            var blur = _shadowSpec.blurX;
            var spread = _shadowSpec.blurY;

            // setup the gradient
            var shadowPaint:NvgPaint = Nvg.boxGradient(NanovgHelper.vg,
                x + hOffset - spread,
                y + vOffset - spread,
                w+2*spread,
                h+2*spread,
                cornerMax + spread,
                blur,
                shadowColor,
                Nvg.rgba(0, 0, 0, 0)
            );

            // setup quad coords
            var sx = x + hOffset - spread - blur;
            var sy = y + vOffset - spread - blur;
            var sw = w + 2 * spread + 2 * blur;
            var sh = h + 2 * spread + 2 * blur;

            // lets draw
            Nvg.beginPath(NanovgHelper.vg);
            Nvg.pathWinding(NanovgHelper.vg, NvgSolidity.SOLID);
            drawRect(sx, sy, sw, sh, cornerMax);
            Nvg.fillPaint(NanovgHelper.vg, shadowPaint);
            Nvg.fill(NanovgHelper.vg);

        } else {
            // get shadow params
            var hOffset = _shadowSpec.distance;
            var vOffset = _shadowSpec.distance + 2;
            var blur = _shadowSpec.blurX;
            var spread = _shadowSpec.blurY;

            // setup the gradient
            var shadowPaint:NvgPaint = Nvg.boxGradient(NanovgHelper.vg,
                x + hOffset + spread,
                y + vOffset + spread - blur,
                w+2*spread,
                h+2*spread,
                cornerMax + spread,
                blur,
                Nvg.rgba(0, 0, 0, 0),
                shadowColor,
            );

            Nvg.beginPath(NanovgHelper.vg);
            drawRect(x, y, w, h, cornerMax);
            Nvg.fillPaint(NanovgHelper.vg, shadowPaint);
            Nvg.fill(NanovgHelper.vg);
        }

        // size = Std.int(size * Toolkit.scale);
        // if (inset == false) {
        //     for (i in 0...size) {
        //         // DrawRectangle(x + i + 1, y + h + 1 + i, w + 0, 1, Fade(col(color), .1)); // bottom
        //         // DrawRectangle(x + w + 1 + i, y + i + 1, 1, h + 1, Fade(col(color), .1)); // right
        //     }
        // } else {
        //     for (i in 0...size) {
        //         // DrawRectangle(x + i, y + i, w - i, 1, Fade(col(color), .1)); // top
        //         // DrawRectangle(x + i, y + i, 1, h - i, Fade(col(color), .1)); // left
        //     }
        // }
    }

    
}