package haxe.ui.backend.cortex;

import cortex.input.ModState;
import cortex.input.KeyCode;
import cortex.input.ScanCode;
import cortex.input.Types;
import haxe.ui.backend.cortex.KeyboardHelper;
import haxe.ui.backend.cortex.MouseHelper;
import haxe.ui.backend.cortex.StyleHelper;
import haxe.ui.backend.cortex.FontHelper;
import haxe.ui.events.MouseEvent;
import haxe.ui.util.Timer;
import haxe.ui.backend.cortex.NanovgHelper;
import nanovg.Nvg;

typedef NvgH = NanovgHelper;


// import kha.Color;
// import kha.Font;
// import kha.Scheduler;
// import kha.StringExtensions;
// import kha.graphics2.Graphics;
// import kha.input.KeyCode;
// import kha.input.Keyboard;
// import kha.input.Mouse;
// import kha.System;

// @:structInit
// class CharPosition {
//     public var row:Int;
//     public var column:Int;
// }

@:structInit
class CharPosition {
    public var row:Int;
    public var column:Int;
    public var visible:Bool = false;
    public var force:Bool = false;
    // public var timerId:Int;

    public function toString():String {
        return haxe.Json.stringify({
            visible: visible,
            force: force,
            row: row,
            column: column
        }, null, '  ');
    }
}

typedef CaretInfo = CharPosition;

@:structInit
class SelectionInfo {
    public var start:CharPosition;
    public var end:CharPosition;
    public function toString():String
        return '(${start.column}, ${start.row}) -> (${end.column}, ${end.row})';
}

class TextField {
    public var id:String = null; // for debugging

    public static inline var SPACE:Int = 32;
    public static inline var CR:Int = 10;
    public static inline var LF:Int = 13;

    private var _selectionInfo:SelectionInfo = {start: {row: -1, column: -1}, end: {row: -1, column: -1}};
    private var _caretInfo:CaretInfo = {row: -1, column: -1, visible: false, force: false};

    private static var _hasCutCopyPasteListner:Bool = false;
    public function new() {
        // if (!_hasCutCopyPasteListner) {
        //     _hasCutCopyPasteListner = true;
        //     // Only one cutCopyPaste is set at once, as opposed to the listener list for keyboard/mouse.
        //     // these functions are overriden by any component stealing focus
        //     System.notifyOnCutCopyPaste(onCut, onCopy, onPaste);
        // }

        // MouseHelper.notify(MouseEvent.MOUSE_DOWN, onMouseDown);
        KeyboardHelper.onKeyDown.connect(onKeyDown);
        KeyboardHelper.onKeyPress.connect(onKeyPress);
        KeyboardHelper.onKeyUp.connect(onKeyUp);
        KeyboardHelper.onTextInput.connect(onTextInput);

        recalc();
    }

    //*****************************************************************************************************************//
    // PUBLIC API                                                                                                      //
    //*****************************************************************************************************************//
    public var left:Float = 0;
    public var top:Float = 0;

    public var editable:Bool = true;

    public var textColor = StyleHelper.col(0x0);
    public var backgroundColor = StyleHelper.col(0xFFFFFF);

    public var selectedTextColor = StyleHelper.col(0xFFFFFF);
    public var selectedBackgroundColor = StyleHelper.col(0xFF3390FF);

    public var scrollTop:Int = 0;
    public var scrollLeft:Float = 0;

    private var _textChanged:Array<String->Void> = [];
    private var _caretMoved:Array<CharPosition->Void> = [];
    public function notify(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.push(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.push(caretMoved);
        }
    }

    public function remove(textChanged:String->Void, caretMoved:CharPosition->Void) {
        if (textChanged != null) {
            _textChanged.remove(textChanged);
        }
        if (caretMoved != null) {
            _caretMoved.remove(caretMoved);
        }
    }
    
    private function notifyTextChanged() {
        for (l in _textChanged) {
            l(_text);
        }
    }

    private function notifyCaretMoved() {
        for (l in _caretMoved) {
            l(_caretInfo);
        }
    }

    private var _lines:Array<TextLine> = null;
    private var _text:String = "";
    public var text(get, set):String;
    private function get_text():String {
        return _text;
    }
    private function set_text(value:String):String {
        if (value == _text) {
            return value;
        }

        _text = value;
        if (value == null || value.length == 0) {
            if (isActive == true) {
                _caretInfo.row = 0;
                _caretInfo.column = 0;
            } else {
                _caretInfo.row = -1;
                _caretInfo.column = -1;
            }
            resetSelection();
        }

        recalc();
        notifyTextChanged();
        return value;
    }

    private var _width:Float = 200;
    public var width(get, set):Float;
    private function get_width():Float {
        return _width;
    }
    private function set_width(value:Float):Float {
        if (value == _width) {
            return value;
        }

        _width = value;
        recalc();
        return value;
    }

    private var _height:Float = 100;
    public var height(get, set):Float;
    private function get_height():Float {
        return _height;
    }
    private function set_height(value:Float):Float {
        if (value == _height) {
            return value;
        }

        _height = value;
        recalc();
        return value;
    }

    private var _password:Bool = false;
    public var password(get, set):Bool;
    private function get_password():Bool {
        return _password;
    }
    private function set_password(value:Bool):Bool {
        if (value == _password) {
            return value;
        }

        _password = value;
        recalc();
        return value;
    }

    private var _font:String;
    public var font(get, set):String;
    private function get_font():String {
        return _font;
    }
    private function set_font(value:String):String {
        if (value == _font) {
            return value;
        }

        _font = value;
        recalc();
        return value;
    }

    private var _fontSize:Int = 14;
    public var fontSize(get, set):Int;
    private function get_fontSize():Int {
        return _fontSize;
    }
    private function set_fontSize(value:Int):Int {
        if (value == _fontSize) {
            return value;
        }

        _fontSize = value;
        recalc();
        return value;
    }

    private var _multiline:Bool = true;
    public var multiline(get, set):Bool;
    private function get_multiline():Bool {
        return _multiline;
    }
    private function set_multiline(value:Bool):Bool {
        if (value == _multiline) {
            return value;
        }

        _multiline = value;
        recalc();
        return value;
    }

    private var _wordWrap:Bool = true;
    public var wordWrap(get, set):Bool;
    private function get_wordWrap():Bool {
        return _wordWrap;
    }
    private function set_wordWrap(value:Bool):Bool {
        if (value == _wordWrap) {
            return value;
        }

        _wordWrap = value;
        recalc();
        return value;
    }

    private var _autoHeight:Bool;
    public var autoHeight(get, set):Bool;
    private function get_autoHeight():Bool {
        return _autoHeight;
    }
    private function set_autoHeight(value:Bool):Bool {
        if (value == _autoHeight) {
            return value;
        }

        _autoHeight = value;
        recalc();
        return value;
    }

    public var maxVisibleLines(get, null):Int;
    private inline function get_maxVisibleLines():Int {
        return Math.round(height / fontSize);
    }

    public var numLines(get, null):Int;
    private inline function get_numLines():Int {
        return _lines.length;
    }

    private function resetSelection() {
        _selectionInfo.start.row = -1;
        _selectionInfo.start.column = -1;
        _selectionInfo.end.row = -1;
        _selectionInfo.end.column = -1;
    }

    public var hasSelection(get, null):Bool;
    private function get_hasSelection():Bool {
        return (_selectionInfo.start.row > -1 && _selectionInfo.start.column > -1
                && _selectionInfo.end.row > -1 && _selectionInfo.end.column > -1);
    }

    public var selectionStart(get, null):Int;
    private function get_selectionStart():Int {
        return posToIndex(_selectionInfo.start);
    }

    public var selectionEnd(get, null):Int;
    private function get_selectionEnd():Int {
        return posToIndex(_selectionInfo.end);
    }

    public var caretPosition(get, set):Int;
    private function get_caretPosition():Int {
        return posToIndex(_caretInfo);
    }
    private function set_caretPosition(value:Int):Int {
        var pos = indexToPos(value);
        _caretInfo.row = pos.row;
        _caretInfo.column = pos.column;

        trace(value);
        trace(_caretInfo);

        scrollToCaret();
        return value;
    }

    //*****************************************************************************************************************//
    // HELPERS                                                                                                         //
    //*****************************************************************************************************************//
    private static var _currentFocus:TextField;
    public var isActive(get, null):Bool;
    private function get_isActive():Bool {
        return (_currentFocus == this);
    }

    private function recalc() {
        splitLines();
        if (autoHeight == true) {
            height = requiredHeight;
        }
    }

    private function inBounds(x:Float, y:Float):Bool {
        if (x >= left && y >= top && x <= left + width && y <= top + height) {
            return true;
        }
        return false;
    }

    public var requiredWidth(get, null):Float;
    private function get_requiredWidth():Float {
        var rw:Float = 0;
        for (line in _lines) {
            var lineWidth = line.getWidthFromTo(0, line.length);
            if (lineWidth > rw) {
                rw = lineWidth;
            }
        }
        return rw;
    }

    public var requiredHeight(get, null):Float;
    private function get_requiredHeight():Float {
        return _lines.length * fontSize;
    }

    private function moveCaretRight() {
        if (_caretInfo.row >= _lines.length) {
            return;
        }
        if (_caretInfo.column < _lines[_caretInfo.row].length) {
            _caretInfo.column++;
        } else if (_caretInfo.row < _lines.length - 1) {
            _caretInfo.column = 0;
            _caretInfo.row++;
        }
    }

    private function moveCaretLeft() {
        if (_caretInfo.column > 0) {
            _caretInfo.column--;
        } else if (_caretInfo.row > 0) {
            _caretInfo.row--;
            _caretInfo.column = _lines[_caretInfo.row].length;
        }
    }

    private function handleNegativeSelection() {
        if (caretPosition <= selectionStart) {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        } else {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        }
    }

    private function handlePositiveSelection() {
        if (caretPosition >= selectionEnd) {
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        } else {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
        }
    }

    private function performKeyOperation(code:Int) {

        trace(_selectionInfo);
        trace(_caretInfo);

        var orginalCaretPos:CharPosition = { row: _caretInfo.row, column: _caretInfo.column };

        switch (code) {
            case KeyCode.ENTER, KeyCode.KP_ENTER:
                if (multiline) {
                    insertText("\n");
                }

            case KeyCode.LEFT:
                moveCaretLeft();

                if (mod.ctrl) {
                    while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) == SPACE) {
                        moveCaretLeft();
                    }
                    while((_caretInfo.column > 0 || _caretInfo.row > 0) && _text.charCodeAt(posToIndex(_caretInfo)-1) != SPACE) {
                        moveCaretLeft();
                    }
                }

                scrollToCaret();

                if (mod.shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case KeyCode.RIGHT:
                moveCaretRight();

                if (mod.ctrl) {
                    while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) != SPACE) {
                        moveCaretRight();
                    }
                    while((_caretInfo.column < _lines[_caretInfo.row].length && _caretInfo.row < _lines.length) && _text.charCodeAt(posToIndex(_caretInfo)) == SPACE) {
                        moveCaretRight();
                    }
                }

                scrollToCaret();

                if (mod.shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }

            case KeyCode.UP:
                if (_caretInfo.row > 0) {
                    _caretInfo.column = findClosestColumn(_caretInfo, -1);
                    _caretInfo.row--;
                }
                scrollToCaret();

                if (mod.shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case KeyCode.DOWN:
                if (_caretInfo.row < _lines.length - 1) {
                    _caretInfo.column = findClosestColumn(_caretInfo, 1);
                    _caretInfo.row++;
                }
                scrollToCaret();

                if (mod.shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }

            case KeyCode.BACKSPACE:
                if (_text.length > 0) {
                    if (hasSelection) {
                        insertText("");
                    } else {
                        if (mod.ctrl) {
                            var caretIndex = posToIndex(_caretInfo);
                            var caretDisplacement = 0;
                            while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) == SPACE)
                                caretDisplacement--;
                            while (caretIndex+caretDisplacement > 0 && _text.charCodeAt(caretIndex+caretDisplacement-1) != SPACE)
                                caretDisplacement--;

                            deleteCharsFromCaret(caretDisplacement);
                            scrollToCaret();
                        } else {
                            deleteCharsFromCaret(-1);
                        }
                    }
                }

            case KeyCode.DELETE:
                if (_text.length > 0) {
                    if (hasSelection) {
                        insertText("");
                    } else {
                        if (mod.ctrl) {
                            // Delete until the start of the next word
                            var caretIndex = posToIndex(_caretInfo);
                            var caretDisplacement = 0;
                            while (_text.charCodeAt(caretIndex+caretDisplacement) != SPACE && caretIndex+caretDisplacement < _text.length)
                                caretDisplacement++;
                            while (_text.charCodeAt(caretIndex+caretDisplacement) == SPACE && caretIndex+caretDisplacement < _text.length)
                                caretDisplacement++;

                            deleteCharsFromCaret(caretDisplacement, false);
                            caretPosition = caretIndex; // Updates _caretInfo (text changes may alter row/column, for instance after wrapping)
                            scrollToCaret();

                        } else {
                            deleteCharsFromCaret(1, false);
                        }
                    }
                }

            case KeyCode.HOME:
                scrollLeft = 0;
                _caretInfo.column = 0;
                scrollToCaret();

                if (mod.shift == true) {
                    handleNegativeSelection();
                } else {
                    resetSelection();
                }

            case KeyCode.END:
                var line = _lines[_caretInfo.row];
                scrollLeft = line.getWidthFromTo(0, line.length) - width + caretWidth;
                if (scrollLeft < 0) {
                    scrollLeft = 0;
                }
                _caretInfo.column = line.length;
                scrollToCaret();

                if (mod.shift == true) {
                    handlePositiveSelection();
                } else {
                    resetSelection();
                }
            case KeyCode.KEY_A:
                if (mod.ctrl) {
                    _selectionInfo.start.row = 0;
                    _selectionInfo.start.column = 0;
                    
                    var line = _lines[_lines.length-1];
                    
                    _caretInfo.row = _lines.length-1;
                    _caretInfo.column = line.length;
                    _selectionInfo.end.row = _lines.length-1;
                    _selectionInfo.end.column = line.length;
                    scrollToCaret();
                }

            case _:
        }

        if (_caretInfo.row != orginalCaretPos.row || _caretInfo.column != orginalCaretPos.column) {
           notifyCaretMoved();
        }
    }

    private function insertText(s:String) {
        var start:CharPosition = _caretInfo;
        var end:CharPosition = _caretInfo;
        if (_selectionInfo.start.row != -1 && _selectionInfo.start.column != -1) {
            start = _selectionInfo.start;
        }
        if (_selectionInfo.end.row != -1 && _selectionInfo.end.column != -1) {
            end = _selectionInfo.end;
        }


        var startIndex = posToIndex(start);
        var endIndex = posToIndex(end);

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + s + after;
        var delta = s.length - (endIndex - startIndex);

        resetSelection();

        caretPosition = endIndex + delta;
        notifyCaretMoved();
        scrollToCaret();

        trace(caretPosition);
        
        // Scheduler.addBreakableTimeTask(function () {
        //     caretPosition = endIndex + delta;
        //     notifyCaretMoved();
        //     scrollToCaret();
        
        //     return false;
        // }, .001);
    }

    private var caretLeft(get, null):Float;
    private function get_caretLeft():Float {
        var line = _lines[_caretInfo.row];
        var xpos:Float = -scrollLeft;
        if (line == null) {
            return xpos;
        }
        return xpos + line.getWidthFromTo(0, _caretInfo.column);
    }

    private var caretTop(get, null):Float;
    private function get_caretTop():Float {
        var ypos:Float = 0;
        return ypos + ((_caretInfo.row - scrollTop) * fontSize);
    }

    private var caretWidth(get, null):Float;
    private function get_caretWidth():Float {
        return Math.round(_fontSize * 0.1);
    }

    private var caretHeight(get, null):Float;
    private function get_caretHeight():Float {
        return fontSize;
    }

    //*****************************************************************************************************************//
    // EVENTS                                                                                                          //
    //*****************************************************************************************************************//
    var mod = new ModState();
    
    private static function onCut() {
        if (_currentFocus == null) {
            return "";
        }

        if (_currentFocus.password) {
            return "";
        }

        if (_currentFocus.hasSelection) {
            var cutText = _currentFocus._text.substring(_currentFocus.posToIndex(_currentFocus._selectionInfo.start), _currentFocus.posToIndex(_currentFocus._selectionInfo.end));
            _currentFocus.insertText("");
            return cutText;
        }

        return "";
    }

    private static function onCopy() {
        if (_currentFocus == null) {
            return "";
        }

        if (_currentFocus.password) {
            return "";
        }

        if (_currentFocus.hasSelection) {
            return _currentFocus._text.substring(_currentFocus.posToIndex(_currentFocus._selectionInfo.start), _currentFocus.posToIndex(_currentFocus._selectionInfo.end));
        }

        return "";
    }
    
    private static function onPaste(text:String) {
        if (_currentFocus == null) {
            return;
        }

        _currentFocus.insertText(text);
    }
    
    private function onKeyDown(event:KeyEvent) {
        mod = event.mod;

        if (!isActive) return;

        // if ((code == CR || code == LF) && multiline == false)
        //     return;

        if (mod.shift && !hasSelection) {
            _selectionInfo.start.row = _caretInfo.row;
            _selectionInfo.start.column = _caretInfo.column;
            _selectionInfo.end.row = _caretInfo.row;
            _selectionInfo.end.column = _caretInfo.column;
        }

        _caretInfo.force = true;
        _caretInfo.visible = true;
        performKeyOperation(event.keycode);
    }

    // private function onKeyDown(code:KeyCode) {
    //     if (isActive == false) {
    //         return;
    //     }

    //     if ((code == CR || code == LF) && multiline == false) {
    //         return;
    //     }

    //     switch (code) {
    //         case Shift:
    //             if (!hasSelection) {
    //                 _selectionInfo.start.row = _caretInfo.row;
    //                 _selectionInfo.start.column = _caretInfo.column;
    //                 _selectionInfo.end.row = _caretInfo.row;
    //                 _selectionInfo.end.column = _caretInfo.column;
    //             }
    //             mod.shift = true;
    //         case Control:
    //             mod.ctrl = true;
    //         case _:
    //     }

    //     _downKey = code;
    //     _caretInfo.force = true;
    //     _caretInfo.visible = true;

    //     performKeyOperation(code);

    //     Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
    //     Scheduler.addTimeTaskToGroup(REPEAT_TIMER_GROUP, function() {
    //         if (_downKey != KeyCode.Unknown) {
    //             Scheduler.addTimeTaskToGroup(REPEAT_TIMER_GROUP, onKeyRepeat, 0, 1 / 30);
    //         }
    //     }, .6);
    // }

    // private function onKeyRepeat() {
    //     if (_downKey != KeyCode.Unknown) {
    //         performKeyOperation(_downKey);
    //     }
    // }

    private function onKeyPress(event:KeyEvent) {
        mod = event.mod;

        if (!isActive) return;

        // if ((character.charCodeAt(0) == CR || character.charCodeAt(0) == LF) && multiline == false)
        //     return;

        _caretInfo.force = false;
        _caretInfo.visible = true;
        performKeyOperation(event.keycode);
    }
    // private function onKeyPress(character:String) {
    //     if (isActive == false) {
    //         return;
    //     }

    //     if ((character.charCodeAt(0) == CR || character.charCodeAt(0) == LF) && multiline == false) {
    //         return;
    //     }

    //     insertText(character);

    //     _caretInfo.force = false;
    //     _caretInfo.visible = true;
    //     _downKey = KeyCode.Unknown;
    //     Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
    // }

    private function onKeyUp(event:KeyEvent) {
        mod = event.mod;

        if (!isActive) return;

        _caretInfo.force = false;
        _caretInfo.visible = true;
    }

    // private function onKeyUp(code:KeyCode) {
    //     if (isActive == false) {
    //         return;
    //     }

    //     switch (code) {
    //         case Shift:
    //             mod.shift = false;
    //         case Control:
    //             mod.ctrl = false;
    //         case _:
    //     }

    //     _caretInfo.force = false;
    //     _caretInfo.visible = true;
    //     _downKey = KeyCode.Unknown;
    //     Scheduler.removeTimeTask(_repeatTimerId);
    //     Scheduler.removeTimeTasks(REPEAT_TIMER_GROUP);
    // }

    private function onTextInput(event:TextInputEvent) {
        mod = event.mod;
        if (!isActive) return;

        insertText(event.text);
        _caretInfo.force = true;
        _caretInfo.visible = true;
    }

    // private var _mouseDownPos:CharPosition = null;
    // private function onMouseDown(button:Int, x:Int, y:Int) {
    //     if (_font == null || inBounds(x, y) == false) {
    //         return;
    //     }

    //     /*
    //     if (_currentFocus != null && _currentFocus != this) {
    //         _currentFocus.onBlur();
    //     }
    //     _currentFocus = this;
    //     */

    //     var localX = x - left + scrollLeft;
    //     var localY = y - top;

    //     resetSelection();
    //     var pos = coordsToPos(localX, localY);
    //     if (pos != null) {
    //         _caretInfo.row = pos.row;
    //         _caretInfo.column = pos.column;
    //         scrollToCaret();
    //         if (_currentFocus != null) {
    //             _currentFocus.onFocus();
    //         }
    //     }
    //     _mouseDownPos = pos;

    // }

    // private function coordsToPos(localX:Float, localY:Float):CharPosition {
    //     var pos = {
    //         row: 0,
    //         column: 0
    //     }

    //     pos.row = scrollTop + Std.int(localY / fontSize);
    //     if (pos.row > _lines.length - 1) {
    //         pos.row = _lines.length - 1;
    //     }
    //     var line = _lines[pos.row];
    //     if (line == null) {
    //         return null;
    //     }
    //     var totalWidth:Float = 0;
    //     var i = 0;
    //     var inText = false;
    //     for (ch in line) {
    //         var charWidth = font.widthOfCharacters(fontSize, [ch], 0, 1);
    //         if (totalWidth + charWidth > localX) {
    //             pos.column = i;
    //             var delta = localX - totalWidth;
    //             if (delta > charWidth * 0.6) {
    //                 pos.column++;
    //             }
    //             inText = true;
    //             break;
    //         } else {
    //             totalWidth += charWidth;
    //         }
    //         i++;
    //     }

    //     if (inText == false) {
    //         pos.column = line.length;
    //     }

    //     return pos;
    // }

    // private function onMouseUp(button:Int, x:Int, y:Int) {
    //     _mouseDownPos = null;
    // }

    // private function onMouseMove(x:Int, y:Int, moveX:Int, moveY:Int) {
    //     if (_font == null) {
    //         return;
    //     }

    //     if (_mouseDownPos == null) {
    //         return;
    //     }

    //     if (isActive == false) {
    //         return;
    //     }

    //     if (inBounds(x, y) == false) {
    //         if (y < top && scrollTop == 0) {
    //             y = Std.int(top);
    //         } else if (y > top + height) {
    //             y = Std.int(top + height);
    //         }
    //     }

    //     var localX = x - left + scrollLeft;
    //     var localY = y - top;
    //     var pos = coordsToPos(localX, localY);
    //     if (pos != null) {
    //         var startIndex = posToIndex(_mouseDownPos);
    //         var endIndex = posToIndex(pos);

    //         if (endIndex > startIndex) {
    //             _selectionInfo.start.row = _mouseDownPos.row;
    //             _selectionInfo.start.column = _mouseDownPos.column;
    //             _selectionInfo.end = pos;

    //             _caretInfo.row = pos.row;
    //             _caretInfo.column = pos.column;
    //             scrollToCaret();
    //         } else {
    //             _selectionInfo.start.row = pos.row;
    //             _selectionInfo.start.column = pos.column;
    //             _selectionInfo.end = _mouseDownPos;

    //             _caretInfo.row = pos.row;
    //             _caretInfo.column = pos.column;
    //             scrollToCaret();
    //         }
    //     }
    // }

    public function focus() {
        onFocus();
    }
    
    private var _focusTimer:Timer = null;
    private function onFocus() {
        if (_currentFocus != null && _currentFocus != this) {
            _currentFocus.onBlur();
        }
        _currentFocus = this;
        
        // if (_caretInfo.timerId == -1) {
        //     _caretInfo.visible = false;
        //     _caretInfo.timerId = Scheduler.addTimeTask(function() {
        //         _caretInfo.visible = !_caretInfo.visible;
        //     }, 0, .4);
        // }

        if (_focusTimer == null) {
            _caretInfo.visible = false;
            _focusTimer = new Timer(400, function() {
                _caretInfo.visible = !_caretInfo.visible;
            });
        }

        // if (text.length > 0) 
        //     caretPosition = text.length-1;
        // else
        caretPosition = 0;
    }

    public function blur() {
        onBlur();
    }
    
    private function onBlur() {
        // Scheduler.removeTimeTask(_caretInfo.timerId);
        if (_focusTimer != null) {
            _focusTimer.stop();
            _focusTimer = null;
        }

        _caretInfo.visible = false;
        _currentFocus = null;

        resetSelection();
    }

    // public function destroy() {
    //     Mouse.get().remove(onMouseDown, onMouseUp, onMouseMove, null, null);
    //     Keyboard.get().remove(onKeyDown, onKeyUp, onKeyPress);
    //     _textChanged = null;
    //     _caretMoved = null;
    // }

    //*****************************************************************************************************************//
    // UTIL                                                                                                            //
    //*****************************************************************************************************************//
    private function splitLines() {
        _lines = [];

        if (text == null/* || _font == null */) {
            return;
        }

        if (multiline == false) {
            var text = text.split("\n").join("").split("\r").join("");
            if (password == true) {
                var passwordText = "";
                for (i in 0...text.length) {
                    passwordText += "*";
                }
                text = passwordText;
            }
            _lines.push(new TextLine(text));
        } else if (wordWrap == false) {
            var arr = StringTools.replace(StringTools.replace(text, "\r\n", "\n"), "\r", "\n").split("\n");
            trace(arr);
            for (a in arr) {
                _lines.push(new TextLine(a));
            }
        } else if (wordWrap == true) {
            var lines = Nvg.textBreakLines(NanovgHelper.vg, text, width);
            // trace(lines);
            if (lines.length > 0)
                for (l in lines)
                    _lines.push(new TextLine(l.line)); // TODO: wasteful
            else
                _lines.push(new TextLine(text));
        }
    }

    private function deleteCharsFromCaret(count:Int = 1, moveCaret:Bool = true) {
        deleteChars(count, _caretInfo, moveCaret);
    }

    private function deleteChars(count:Int, from:CharPosition, moveCaret:Bool = true) {
        var fromIndex = posToIndex(from);
        var toIndex = fromIndex + count;

        var startIndex = fromIndex;
        var endIndex = toIndex;
        if (startIndex > endIndex) {
            startIndex = toIndex;
            endIndex = fromIndex;
        }

        if (endIndex > text.length)
            endIndex = text.length;

        var before = text.substring(0, startIndex);
        var after = text.substring(endIndex, text.length);

        text = before + after;
        if (moveCaret == true) {
            caretPosition = endIndex + count;
        }
    }

    private function posToIndex(pos:CharPosition) {
        var index = 0;
        var i = 0;
        for (line in _lines) {
            if (i == pos.row) {
                var column = pos.column;
                if (line.length < pos.column) {
                    column = line.length-1;
                }
                index += column;
                break;
            } else {
                index += line.length + 1;
            }
            i++;
        }

        return index;
    }

    private function indexToPos(index:Int):CharPosition {
        var pos:CharPosition = { row: 0, column: 0 };

        var count:Int = 0;
        for (line in _lines) {
            if (index <= line.length) {
                pos.column = index;
                break;
            } else {
                index -= (line.length + 1);
                pos.row++;
            }
        }

        return pos;
    }

    private function scrollToCaret() {
        ensureRowVisible(_caretInfo.row);

        if (_lines.length < maxVisibleLines) {
            scrollTop = 0;
        }

        var line = _lines[_caretInfo.row];
        if (caretLeft > width) {
            scrollLeft += caretLeft - width + 50;

            if (scrollLeft + width > line.getWidthFromTo(0, line.length)) {
                scrollLeft = line.getWidthFromTo(0, line.length) - width + caretWidth;
                if (scrollLeft < 0) {
                    scrollLeft = 0;
                }
            }
        } else if (caretLeft < 0) {
            scrollLeft += caretLeft - 50;

            if (scrollLeft < 0 || line.getWidthFromTo(0, line.length) <= width) {
                scrollLeft = 0;
            }
        }
        notifyCaretMoved();
    }

    private function ensureRowVisible(row:Int) {
        if (row >= scrollTop && row <= scrollTop + maxVisibleLines - 1) {
            return;
        }

        if (row < scrollTop + maxVisibleLines) {
            scrollTop = row;
        } else {
            scrollTop = row - maxVisibleLines + 1;
        }
    }

    private function findClosestColumn(origin:CharPosition, offset:Int) {
        var closestColumn = origin.column;
        var offsetLine = _lines[origin.row + offset];
        if (closestColumn > offsetLine.length) {
            closestColumn = offsetLine.length;
        }
        return closestColumn;
    }

    //*****************************************************************************************************************//
    // RENDER                                                                                                          //
    //*****************************************************************************************************************//

    private function drawCharacters(characters:TextLine, start:Int, length:Int, _x:Float, _y:Float, color:NvgColor) {
        var s = characters.text.substr(start, length);
        
        // DrawText(s, x, y, fontSize, StyleHelper.col(color));

        // Nvg.fontFaceId(NanovgHelper.vg, FontHelper.getFont('default'));
        // Nvg.fontSize(NanovgHelper.vg, fontSize * Toolkit.scale);
        // Nvg.textAlign(NanovgHelper.vg, NvgAlign.ALIGN_TOP);

        // var maxWidth:Float = _width * Toolkit.scale;
        // var bounds:Array<cpp.Float32> = [0.0,0,0,0];
        // Nvg.textBoxBounds(NanovgHelper.vg, 0, 0, maxWidth, s, null, bounds);
        
        var xOffset = _x;//-bounds[0];
        var yOffset = _y;//+(bounds[3]-bounds[1]);

        //
        // for (g in characters.glyphs)
        //     StyleHelper.drawRectangle(xOffset+g[0], yOffset, 2, 2, Nvg.rgba(255,0,0,255), 0);


        Nvg.fillColor(NanovgHelper.vg, color);


        // Nvg.textAlign(NanovgHelper.vg, NvgAlign.ALIGN_MIDDLE);
        // if (multiline)
        //     Nvg.textBox(NanovgHelper.vg, xOffset, yOffset, width, s, null);
        // else
            Nvg.text(NanovgHelper.vg, xOffset, yOffset, s, null);
        
    }

    public function draw() {
        // if (_font == null) {
        //     return;
        // }
        
        var x = left;
        var y = top;
        var w = width;
        var h = height;
        StyleHelper.drawRectangle(x, y, w, h, backgroundColor, 0);

        ScissorHelper.pushScissor(Math.round(left), Math.round(top), Math.round(width), Math.round(height));

        Nvg.save(NanovgHelper.vg);
        Nvg.translate(NanovgHelper.vg, x, y+fontSize * Toolkit.scale);

        Nvg.fontFaceId(NanovgHelper.vg, FontHelper.getFont('default'));
        Nvg.fontSize(NanovgHelper.vg, fontSize * Toolkit.scale);
        Nvg.textLineHeight(NanovgHelper.vg, 2);
        Nvg.textAlign(NanovgHelper.vg, NvgAlign.ALIGN_BOTTOM);

        var xpos:Float = -scrollLeft;
        var ypos:Float = 0;

        var start = scrollTop;
        var end = start + maxVisibleLines;

        if (start > 0) {
            start--; // show one less line so it looks nicer
            ypos -= fontSize;
        }
        if (end > _lines.length) {
            end = _lines.length;
        }
        if (end < _lines.length) {
            end++; // show one additonal line so it looks nicer
        }

        for (i in start...end) {
            xpos = -scrollLeft;
            var line = _lines[i];
            line.recalc();

            if (i >= _selectionInfo.start.row && i <= _selectionInfo.end.row) {
                if (i == _selectionInfo.start.row && _selectionInfo.start.row == _selectionInfo.end.row) {
                    if (_selectionInfo.start.column != _selectionInfo.end.column) {
                        drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos, textColor);
                        xpos += line.getWidthFromTo(0, _selectionInfo.start.column);

                        StyleHelper.drawRectangle(xpos, ypos-fontSize * Toolkit.scale, line.getWidthFromTo(_selectionInfo.start.column, _selectionInfo.end.column), fontSize, selectedBackgroundColor, 0);

                        drawCharacters(line, _selectionInfo.start.column, (_selectionInfo.end.column) - (_selectionInfo.start.column), xpos, ypos, selectedTextColor);
                        xpos += line.getWidthFromTo(_selectionInfo.start.column, _selectionInfo.end.column);
                        drawCharacters(line, _selectionInfo.end.column, line.length, xpos, ypos, textColor);
                    }
                    else {
                        StyleHelper.drawRectangle(xpos+line.getWidthFromTo(0, _selectionInfo.start.column), ypos-fontSize * Toolkit.scale, line.getWidthFromTo(_selectionInfo.start.column, _selectionInfo.end.column), fontSize, selectedBackgroundColor, 0);
                        drawCharacters(line, 0, line.length, xpos, ypos, textColor);
                    }

                } else if (i == _selectionInfo.start.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    drawCharacters(line, 0, _selectionInfo.start.column, xpos, ypos, textColor);
                    xpos += line.getWidthFromTo(0, _selectionInfo.start.column);

                    StyleHelper.drawRectangle(xpos, ypos-fontSize * Toolkit.scale, line.getWidthFromTo(_selectionInfo.start.column, line.glyphs.length), fontSize, selectedBackgroundColor, 0);

                    drawCharacters(line, _selectionInfo.start.column, line.length - (_selectionInfo.start.column), xpos, ypos, selectedTextColor);
                } else if (i == _selectionInfo.end.row && _selectionInfo.start.row != _selectionInfo.end.row) {
                    StyleHelper.drawRectangle(xpos, ypos-fontSize * Toolkit.scale, line.getWidthFromTo(0, _selectionInfo.end.column), fontSize, selectedBackgroundColor, 0);

                    drawCharacters(line, 0, _selectionInfo.end.column, xpos, ypos, selectedTextColor);
                    xpos += line.getWidthFromTo(0, _selectionInfo.end.column);

                    drawCharacters(line, _selectionInfo.end.column, line.length - (_selectionInfo.end.column), xpos, ypos, textColor);
                } else {
                    StyleHelper.drawRectangle(xpos, ypos-fontSize * Toolkit.scale, line.getWidthFromTo(0, line.glyphs.length), fontSize, selectedBackgroundColor, 0);

                    drawCharacters(line, 0, line.length, xpos, ypos, selectedTextColor);
                }

            } else {
                drawCharacters(line, 0, line.length, xpos, ypos, textColor);
            }

            // drawCharacters(line, 0, line.length, -scrollLeft, ypos + fontSize, textColor);

            ypos += fontSize;
        }

        if (_caretInfo.row > -1 && _caretInfo.column > -1 && (_caretInfo.visible == true || _caretInfo.force == true)) {
            StyleHelper.drawRectangle(caretLeft, caretTop-fontSize * Toolkit.scale, caretWidth, caretHeight, textColor, 0);
        }

        Nvg.restore(NanovgHelper.vg);

        ScissorHelper.popScissor();
    }
}