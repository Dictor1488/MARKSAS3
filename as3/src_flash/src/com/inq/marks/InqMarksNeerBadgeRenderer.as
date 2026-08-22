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

    /**
     * NEER battle renderer with a click/Alt reveal of a single coloured "0"
     * directly below the delta badge.
     */
    public class InqMarksNeerBadgeRenderer extends InqMarksBattleRendererBase
    {
        private static const ZERO_CENTER_X:Number = 262;
        private static const ZERO_Y:Number = 157;
        private static const GREEN:uint = 0x018644;
        private static const RED:uint = 0xC51917;
        private static const CLICK_THRESHOLD:Number = 6.0;

        private var _zeroLayer:Sprite;
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

            _zeroText = new TextField();
            _zeroText.selectable = false;
            _zeroText.mouseEnabled = false;
            _zeroText.autoSize = TextFieldAutoSize.CENTER;
            var fmt:TextFormat = new TextFormat();
            fmt.font = "Arial";
            fmt.size = 13;
            fmt.bold = true;
            fmt.color = RED;
            _zeroText.defaultTextFormat = fmt;
            _zeroLayer.addChild(_zeroText);

            addEventListener(Event.ADDED_TO_STAGE, _onLocalAdded);
            addEventListener(Event.REMOVED_FROM_STAGE, _onLocalRemoved);
            addEventListener(MouseEvent.MOUSE_DOWN, _onLocalMouseDown);
            addEventListener(MouseEvent.CLICK, _onLocalClick);
            _drawZero();
        }

        override public function setData(mark:Number, p65:int, p85:int, p95:int, p100:int,
                                         currentDamage:int, baseDamage:int, stars:int,
                                         projectedMark:Number = -1.0, projectedAvg:int = 0):void
        {
            _currentDamage = int(Math.max(0, currentDamage));
            _zeroDamage = int(Math.max(0, baseDamage));
            super.setData(mark, p65, p85, p95, p100,
                          currentDamage, baseDamage, stars, projectedMark, projectedAvg);
            _drawZero();
        }

        override public function setCurrentDamage(value:int):void
        {
            _currentDamage = int(Math.max(0, value));
            super.setCurrentDamage(value);
            _drawZero();
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

        private function _drawZero():void
        {
            if (!_zeroText) return;

            var fillColor:uint = (_zeroDamage > 0 && _currentDamage >= _zeroDamage) ? GREEN : RED;
            var fmt:TextFormat = _zeroText.defaultTextFormat;
            fmt.color = fillColor;
            _zeroText.defaultTextFormat = fmt;
            _zeroText.text = "0";
            _zeroText.setTextFormat(fmt);
            _zeroText.alpha = 0.95;
            _zeroText.x = ZERO_CENTER_X - _zeroText.width * 0.5;
            _zeroText.y = ZERO_Y;
            _updateZeroVisibility();
        }
    }
}
