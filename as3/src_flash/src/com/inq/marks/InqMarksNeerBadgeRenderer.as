package com.inq.marks
{
    import flash.display.GradientType;
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.geom.Matrix;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;

    /**
     * NEER battle renderer with a bottom "damage to zero" progress panel.
     * Example: 0/1900, where 1900 is baseDamage (damage needed for delta ~= 0).
     *
     * The panel can be toggled with a short click on the NEER mark.
     * Alt still works as a temporary reveal for backwards compatibility.
     */
    public class InqMarksNeerBadgeRenderer extends InqMarksBattleRendererBase
    {
        private static const BAR_X:Number = 170;
        private static const BAR_Y:Number = 174;
        private static const BAR_W:Number = 166;
        private static const BAR_H:Number = 4;
        private static const GOLD:uint = 0xEAD7B7;
        private static const GREEN:uint = 0x018644;
        private static const RED:uint = 0xC51917;
        private static const CLICK_THRESHOLD:Number = 6.0;

        private var _zeroLayer:Sprite;
        private var _zeroBar:Shape;
        private var _zeroText:TextField;
        private var _currentDamage:int = 0;
        private var _zeroDamage:int = 0;
        private var _altExpanded:Boolean = false;
        private var _clickExpanded:Boolean = false;
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

            _zeroBar = new Shape();
            _zeroLayer.addChild(_zeroBar);

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

            addEventListener(Event.ADDED_TO_STAGE, _onLocalAdded);
            addEventListener(Event.REMOVED_FROM_STAGE, _onLocalRemoved);
            addEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown);
            addEventListener(MouseEvent.CLICK, _onLocalClick);
            _drawZeroProgress();
        }

        override public function setData(mark:Number, p65:int, p85:int, p95:int, p100:int,
                                         currentDamage:int, baseDamage:int, stars:int,
                                         projectedMark:Number = -1.0, projectedAvg:int = 0):void
        {
            _currentDamage = int(Math.max(0, currentDamage));
            _zeroDamage = int(Math.max(0, baseDamage));
            super.setData(mark, p65, p85, p95, p100,
                          currentDamage, baseDamage, stars, projectedMark, projectedAvg);
            _drawZeroProgress();
        }

        override public function setCurrentDamage(value:int):void
        {
            _currentDamage = int(Math.max(0, value));
            super.setCurrentDamage(value);
            _drawZeroProgress();
        }

        override public function setExpanded(value:Boolean):void
        {
            _altExpanded = value;
            super.setExpanded(value);
            _updateZeroVisibility();
        }

        override public function dispose():void
        {
            if (_disposedLocal) return;
            _disposedLocal = true;
            _removeStageListeners();
            removeEventListener(Event.ADDED_TO_STAGE, _onLocalAdded);
            removeEventListener(Event.REMOVED_FROM_STAGE, _onLocalRemoved);
            removeEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown);
            removeEventListener(MouseEvent.CLICK, _onLocalClick);
            super.dispose();
        }

        private function _onLocalAdded(e:Event):void
        {
            _removeStageListeners();
            _eventStage = stage;
            if (!_eventStage) return;
            _eventStage.addEventListener(KeyboardEvent.KEY_DOWN, _onLocalKeyDown);
            _eventStage.addEventListener(KeyboardEvent.KEY_UP, _onLocalKeyUp);
        }

        private function _onLocalRemoved(e:Event):void
        {
            _removeStageListeners();
            _altExpanded = false;
            _updateZeroVisibility();
        }

        private function _removeStageListeners():void
        {
            if (!_eventStage) return;
            _eventStage.removeEventListener(KeyboardEvent.KEY_DOWN, _onLocalKeyDown);
            _eventStage.removeEventListener(KeyboardEvent.KEY_UP, _onLocalKeyUp);
            _eventStage = null;
        }

        private function _onLocalKeyDown(e:KeyboardEvent):void
        {
            if (e.keyCode != Keyboard.ALTERNATE || _altExpanded) return;
            _altExpanded = true;
            _updateZeroVisibility();
        }

        private function _onLocalKeyUp(e:KeyboardEvent):void
        {
            if (e.keyCode != Keyboard.ALTERNATE || !_altExpanded) return;
            _altExpanded = false;
            _updateZeroVisibility();
        }

        private function _onLocalMouseDown(e:MouseEvent):void
        {
            _clickStartX = e.stageX;
            _clickStartY = e.stageY;
        }

        private function _onLocalClick(e:MouseEvent):void
        {
            if (_disposedLocal) return;

            // Do not toggle the panel after dragging the mark.
            var dx:Number = e.stageX - _clickStartX;
            var dy:Number = e.stageY - _clickStartY;
            if (dx * dx + dy * dy > CLICK_THRESHOLD * CLICK_THRESHOLD)
                return;

            _clickExpanded = !_clickExpanded;
            _updateZeroVisibility();
        }

        private function _updateZeroVisibility():void
        {
            if (_zeroLayer)
                _zeroLayer.visible = _clickExpanded || _altExpanded;
        }

        private function _drawZeroProgress():void
        {
            if (!_zeroBar || !_zeroText) return;

            var g:Graphics = _zeroBar.graphics;
            g.clear();

            var pct:Number = _zeroDamage > 0
                ? Math.max(0.0, Math.min(1.0, Number(_currentDamage) / Number(_zeroDamage)))
                : 0.0;
            var fillColor:uint = (_zeroDamage > 0 && _currentDamage >= _zeroDamage) ? GREEN : RED;

            g.lineStyle(1.0, GOLD, 0.55, true);
            g.moveTo(BAR_X - 10, BAR_Y);
            g.lineTo(BAR_X, BAR_Y);
            g.moveTo(BAR_X - 10, BAR_Y - 7);
            g.lineTo(BAR_X - 10, BAR_Y + 7);
            g.moveTo(BAR_X + BAR_W, BAR_Y);
            g.lineTo(BAR_X + BAR_W + 10, BAR_Y);
            g.moveTo(BAR_X + BAR_W + 10, BAR_Y - 7);
            g.lineTo(BAR_X + BAR_W + 10, BAR_Y + 7);

            g.lineStyle(0.8, GOLD, 0.42, true);
            g.beginFill(0x05070A, 0.35);
            g.drawRect(BAR_X, BAR_Y - BAR_H * 0.5, BAR_W, BAR_H);
            g.endFill();

            if (pct > 0.0)
            {
                var fillW:Number = Math.max(1.0, (BAR_W - 1.0) * pct);
                var fillY:Number = BAR_Y - BAR_H * 0.5 + 0.5;
                var fillH:Number = BAR_H - 1.0;
                var m:Matrix = new Matrix();
                m.createGradientBox(fillW, fillH, 0.0, BAR_X + 0.5, fillY);

                // Same NEER red/green palette, but with alpha growing toward current value.
                g.lineStyle();
                g.beginGradientFill(GradientType.LINEAR,
                                    [fillColor, fillColor],
                                    [0.22, 0.95],
                                    [0, 255], m);
                g.drawRect(BAR_X + 0.5, fillY, fillW, fillH);
                g.endFill();
            }

            var mx:Number = BAR_X + BAR_W * pct;
            g.lineStyle(1.5, 0xFFFFFF, 1.0, true);
            g.moveTo(mx, BAR_Y - 5);
            g.lineTo(mx, BAR_Y + 5);
            g.lineStyle();

            // Current value (the number before "/") uses the same NEER state colour.
            _zeroText.htmlText =
                "<font color=\"#" + _hex6(fillColor) + "\">" + _currentDamage.toString() + "</font>" +
                "<font color=\"#EAD7B7\">/" +
                (_zeroDamage > 0 ? _zeroDamage.toString() : "0") + "</font>";
            _zeroText.alpha = 0.95;
            _zeroText.x = BAR_X + BAR_W * 0.5 - _zeroText.width * 0.5;
            _zeroText.y = BAR_Y + 7;
            _updateZeroVisibility();
        }

        private function _hex6(value:uint):String
        {
            var s:String = value.toString(16).toUpperCase();
            while (s.length < 6) s = "0" + s;
            return s;
        }
    }
}
