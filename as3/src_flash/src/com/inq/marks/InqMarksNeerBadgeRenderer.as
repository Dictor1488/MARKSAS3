package com.inq.marks
{
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;

    public class InqMarksNeerBadgeRenderer extends InqMarksBattleRendererBase
    {
        private static const GREEN:uint = 0x018644;
        private static const RED:uint   = 0xC51917;
        private static const CLICK_THRESHOLD:Number = 6.0;

        private var _zeroLayer:Sprite;
        private var _zeroText:TextField;
        private var _currentDamage:int = 0;
        private var _zeroDamage:int = 0;
        private var _shown:Boolean = false;
        private var _clickStartX:Number = 0.0;
        private var _clickStartY:Number = 0.0;
        private var _disposedLocal:Boolean = false;

        public function InqMarksNeerBadgeRenderer()
        {
            super();
            setStyle(InqMarksBattleRendererBase.STYLE_NEER);

            _zeroLayer = new Sprite();
            _zeroLayer.mouseEnabled = false;
            _zeroLayer.mouseChildren = false;
            _zeroLayer.visible = false;
            addChild(_zeroLayer);

            _zeroText = new TextField();
            _zeroText.selectable = false;
            _zeroText.mouseEnabled = false;
            _zeroText.autoSize = TextFieldAutoSize.CENTER;
            var fmt:TextFormat = new TextFormat();
            fmt.font = "Arial";
            fmt.size = 13;
            fmt.bold = true;
            fmt.color = 0xFFFFFF;
            _zeroText.defaultTextFormat = fmt;
            _zeroLayer.addChild(_zeroText);

            addEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown);
            addEventListener(MouseEvent.CLICK, _onLocalClick);
            addEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
            _drawZeroText();
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

        override public function dispose():void
        {
            if (_disposedLocal) return;
            _disposedLocal = true;
            removeEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown);
            removeEventListener(MouseEvent.CLICK, _onLocalClick);
            removeEventListener(Event.REMOVED_FROM_STAGE, _onRemoved);
            super.dispose();
        }

        private function _onRemoved(e:Event):void
        {
            _shown = false;
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
            if (_zeroLayer) _zeroLayer.visible = _shown;
        }

        private function _drawZeroText():void
        {
            if (!_zeroText) return;

            var zeroColor:uint = (_zeroDamage > 0 && _currentDamage >= _zeroDamage) ? GREEN : RED;
            var ratio:Number = _zeroDamage > 0
                ? Math.max(0.0, Math.min(1.0, Number(_currentDamage) / Number(_zeroDamage)))
                : 0.0;

            // Alpha follows progress dynamically: starts dim and becomes fully visible near the zero target.
            _zeroText.alpha = 0.35 + 0.65 * ratio;
            _zeroText.htmlText =
                "<font color=\"#" + _hex6(zeroColor) + "\">" + _currentDamage.toString() + "</font>" +
                "<font color=\"#FFFFFF\">/" + (_zeroDamage > 0 ? _zeroDamage.toString() : "0") + "</font>";

            // Place directly below the NEER delta pill.
            _zeroText.x = 262 - _zeroText.width * 0.5;
            _zeroText.y = 157;
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
