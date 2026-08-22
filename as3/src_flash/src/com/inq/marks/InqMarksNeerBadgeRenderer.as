package com.inq.marks
{
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;

    public class InqMarksNeerBadgeRenderer extends InqMarksBattleRendererBase
    {
        private static const GREEN:uint = 0x018644;
        private static const RED:uint   = 0xC51917;
        private static const CLICK_THRESHOLD:Number = 6.0;
        private static const ZERO_FONT_SIZE:int = 16;

        private var _zeroLayer:Sprite;
        private var _zeroCurrentText:TextField;
        private var _zeroTargetText:TextField;
        private var _currentDamage:int = 0;
        private var _zeroDamage:int = 0;
        private var _shown:Boolean = false;
        private var _altShown:Boolean = false;
        private var _clickStartX:Number = 0.0;
        private var _clickStartY:Number = 0.0;
        private var _disposedLocal:Boolean = false;
        private var _eventStage:Stage = null;

        public function InqMarksNeerBadgeRenderer()
        {
            super();
            setStyle(InqMarksBattleRendererBase.STYLE_NEER);

            _zeroLayer = new Sprite();
            _zeroLayer.mouseEnabled = false;
            _zeroLayer.mouseChildren = false;
            _zeroLayer.visible = false;
            addChild(_zeroLayer);

            _zeroCurrentText = _makeZeroText();
            _zeroTargetText = _makeZeroText();
            _zeroLayer.addChild(_zeroCurrentText);
            _zeroLayer.addChild(_zeroTargetText);

            // Capture MOUSE_DOWN before the base drag hit stops propagation.
            addEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown, true);
            addEventListener(MouseEvent.CLICK, _onLocalClick);
            addEventListener(Event.ADDED_TO_STAGE, _onAdded);
            addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
            _drawZeroText();
        }

        private function _makeZeroText():TextField
        {
            var tf:TextField = new TextField();
            tf.selectable = false;
            tf.mouseEnabled = false;
            tf.autoSize = TextFieldAutoSize.LEFT;
            var fmt:TextFormat = new TextFormat();
            fmt.font = "Arial";
            fmt.size = ZERO_FONT_SIZE;
            fmt.bold = true;
            fmt.color = 0xFFFFFF;
            tf.defaultTextFormat = fmt;
            return tf;
        }

        override public function setData(mark:Number, p65:int, p85:int, p95:int, p100:int,
                                         currentDamage:int, baseDamage:int, stars:int,
                                         projectedMark:Number = -1.0, projectedAvg:int = 0):void
        {
            _currentDamage = int(Math.max(0, currentDamage));
            _zeroDamage = int(Math.max(0, baseDamage));
            super.setData(mark, p65, p85, p95, p100,
                          currentDamage, baseDamage, stars, projectedMark, projectedAvg);
            _drawZeroText();
        }

        override public function setCurrentDamage(value:int):void
        {
            _currentDamage = int(Math.max(0, value));
            super.setCurrentDamage(value);
            _drawZeroText();
        }

        // Also follow the normal battle-badge expanded state. This makes Alt work
        // whether it is delivered by this class directly or by the parent HUD code.
        override public function setExpanded(value:Boolean):void
        {
            _altShown = value;
            super.setExpanded(value);
            _updateVisibility();
        }

        override public function dispose():void
        {
            if (_disposedLocal) return;
            _disposedLocal = true;
            _removeStageListeners();
            removeEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown, true);
            removeEventListener(MouseEvent.CLICK, _onLocalClick);
            removeEventListener(Event.ADDED_TO_STAGE, _onAdded);
            removeEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
            super.dispose();
        }

        private function _onAdded(e:Event):void
        {
            _removeStageListeners();
            _eventStage = stage;
            if (!_eventStage) return;
            // Capture phase makes the Alt listener resilient to other HUD handlers.
            _eventStage.addEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown, true);
            _eventStage.addEventListener(KeyboardEvent.KEY_UP, _onKeyUp, true);
        }

        private function _onRemoved(e:Event):void
        {
            _removeStageListeners();
            _shown = false;
            _altShown = false;
            _updateVisibility();
        }

        private function _removeStageListeners():void
        {
            if (!_eventStage) return;
            _eventStage.removeEventListener(KeyboardEvent.KEY_DOWN, _onKeyDown, true);
            _eventStage.removeEventListener(KeyboardEvent.KEY_UP, _onKeyUp, true);
            _eventStage = null;
        }

        private function _onKeyDown(e:KeyboardEvent):void
        {
            if (e.keyCode != Keyboard.ALTERNATE || _altShown) return;
            _altShown = true;
            _updateVisibility();
        }

        private function _onKeyUp(e:KeyboardEvent):void
        {
            if (e.keyCode != Keyboard.ALTERNATE || !_altShown) return;
            _altShown = false;
            _updateVisibility();
        }

        private function _onLocalMouseDown(e:MouseEvent):void
        {
            _clickStartX = e.stageX;
            _clickStartY = e.stageY;
        }

        private function _onLocalClick(e:MouseEvent):void
        {
            if (_disposedLocal) return;
            var dx:Number = e.stageX - _clickStartX;
            var dy:Number = e.stageY - _clickStartY;
            if (dx * dx + dy * dy > CLICK_THRESHOLD * CLICK_THRESHOLD) return;

            _shown = !_shown;
            _updateVisibility();
        }

        private function _updateVisibility():void
        {
            if (_zeroLayer) _zeroLayer.visible = _shown || _altShown;
        }

        private function _drawZeroText():void
        {
            if (!_zeroCurrentText || !_zeroTargetText) return;

            var zeroColor:uint = (_zeroDamage > 0 && _currentDamage >= _zeroDamage) ? GREEN : RED;
            var ratio:Number = _zeroDamage > 0
                ? Math.max(0.0, Math.min(1.0, Number(_currentDamage) / Number(_zeroDamage)))
                : 0.0;

            // Only the dynamic current value gets the progress alpha.
            _zeroCurrentText.alpha = 0.35 + 0.65 * ratio;
            _zeroCurrentText.htmlText =
                "<font color=\"#" + _hex6(zeroColor) + "\">" + _currentDamage.toString() + "</font>";

            // /target stays solid white.
            _zeroTargetText.alpha = 1.0;
            _zeroTargetText.htmlText =
                "<font color=\"#FFFFFF\">/" + (_zeroDamage > 0 ? _zeroDamage.toString() : "0") + "</font>";

            var totalW:Number = _zeroCurrentText.width + _zeroTargetText.width;
            var startX:Number = 262 - totalW * 0.5;
            _zeroCurrentText.x = startX;
            _zeroCurrentText.y = 154;
            _zeroTargetText.x = startX + _zeroCurrentText.width;
            _zeroTargetText.y = 154;
            _updateVisibility();
        }

        private function _hex6(value:uint):String
        {
            var s:String = value.toString(16).toUpperCase();
            while (s.length < 6) s = "0" + s;
            return s;
        }
    }
}
