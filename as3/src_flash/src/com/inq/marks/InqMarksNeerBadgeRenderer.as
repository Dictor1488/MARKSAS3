package com.inq.marks
{
    import flash.display.Graphics;
    import flash.display.Shape;
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.text.TextField;
    import flash.text.TextFieldAutoSize;
    import flash.text.TextFormat;
    import flash.ui.Keyboard;

    /**
     * NEER battle renderer with an Alt-only "damage to zero" progress bar.
     * Example: 0/1900, where 1900 is baseDamage (damage needed for delta ~= 0).
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

        private var _zeroLayer:Sprite;
        private var _zeroBar:Shape;
        private var _zeroText:TextField;
        private var _currentDamage:int = 0;
        private var _zeroDamage:int = 0;
        private var _altExpanded:Boolean = false;
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
            super.dispose();
        }

        private function _onLocalAdded(e:Event):void
        {
            if (!stage) return;
            stage.addEventListener(KeyboardEvent.KEY_DOWN, _onLocalKeyDown);
            stage.addEventListener(KeyboardEvent.KEY_UP, _onLocalKeyUp);
        }

        private function _onLocalRemoved(e:Event):void
        {
            _removeStageListeners();
            _altExpanded = false;
            _updateZeroVisibility();
        }

        private function _removeStageListeners():void
        {
            if (!stage) return;
            stage.removeEventListener(KeyboardEvent.KEY_DOWN, _onLocalKeyDown);
            stage.removeEventListener(KeyboardEvent.KEY_UP, _onLocalKeyUp);
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

        private function _updateZeroVisibility():void
        {
            if (_zeroLayer)
                _zeroLayer.visible = _altExpanded;
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

            // side connectors / ticks in the same thin NEER language
            g.lineStyle(1.0, GOLD, 0.55, true);
            g.moveTo(BAR_X - 10, BAR_Y);
            g.lineTo(BAR_X, BAR_Y);
            g.moveTo(BAR_X - 10, BAR_Y - 7);
            g.lineTo(BAR_X - 10, BAR_Y + 7);
            g.moveTo(BAR_X + BAR_W, BAR_Y);
            g.lineTo(BAR_X + BAR_W + 10, BAR_Y);
            g.moveTo(BAR_X + BAR_W + 10, BAR_Y - 7);
            g.lineTo(BAR_X + BAR_W + 10, BAR_Y + 7);

            // track
            g.lineStyle(0.8, GOLD, 0.42, true);
            g.beginFill(0x05070A, 0.35);
            g.drawRect(BAR_X, BAR_Y - BAR_H * 0.5, BAR_W, BAR_H);
            g.endFill();

            // current / zero-target fill
            if (pct > 0.0)
            {
                g.lineStyle();
                g.beginFill(fillColor, 1.0);
                g.drawRect(BAR_X + 0.5, BAR_Y - BAR_H * 0.5 + 0.5,
                           Math.max(1.0, (BAR_W - 1.0) * pct), BAR_H - 1.0);
                g.endFill();
            }

            // current position marker
            var mx:Number = BAR_X + BAR_W * pct;
            g.lineStyle(1.5, 0xFFFFFF, 1.0, true);
            g.moveTo(mx, BAR_Y - 5);
            g.lineTo(mx, BAR_Y + 5);
            g.lineStyle();

            _zeroText.text = _currentDamage.toString() + "/" +
                             (_zeroDamage > 0 ? _zeroDamage.toString() : "0");
            _zeroText.x = BAR_X + BAR_W * 0.5 - _zeroText.width * 0.5;
            _zeroText.y = BAR_Y + 7;
            _updateZeroVisibility();
        }
    }
}
