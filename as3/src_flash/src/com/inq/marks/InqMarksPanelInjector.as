package com.inq.marks
{
    import flash.events.Event;
    import net.wg.infrastructure.base.AbstractView;

    public class InqMarksPanelInjector extends AbstractView
    {
        private var _panel:InqMarksPanelComponent = null;
        protected var _battleBadge:InqMarksBattleMarkBadge = null;

        public var py_onDragEnd:Function = null;
        public var py_onPanelReady:Function = null;
        public var py_onMarkBadgeToggle:Function = null;
        public var py_onMarkBadgeOffsetChanged:Function = null;
        public var py_onBattleBadgeOffsetChanged:Function = null;

        private var _configDone:Boolean = false;
        private var _pendingCalls:Array = [];
        private var _notifyFrameCount:int = 0;

        public function InqMarksPanelInjector()
        {
            super();
        }

        override protected function configUI():void
        {
            super.configUI();
            _createPanel();
            _configDone = true;
            _replayPendingCalls();
            _notifyFrameCount = 0;
            addEventListener(Event.ENTER_FRAME, _onNotifyFrame);
        }

        override protected function nextFrameAfterPopulateHandler():void
        {
            super.nextFrameAfterPopulateHandler();
            _bringToFront();
        }

        override protected function onDispose():void
        {
            removeEventListener(Event.ENTER_FRAME, _onNotifyFrame);
            _destroyPanel();
            _pendingCalls = [];
            py_onDragEnd = null;
            py_onPanelReady = null;
            py_onMarkBadgeToggle = null;
            py_onMarkBadgeOffsetChanged = null;
            py_onBattleBadgeOffsetChanged = null;
            _configDone = false;
            super.onDispose();
        }

        private function _onNotifyFrame(event:Event):void
        {
            _notifyFrameCount++;
            if (_notifyFrameCount < 5) return;
            removeEventListener(Event.ENTER_FRAME, _onNotifyFrame);
            if (py_onPanelReady != null)
                py_onPanelReady();
        }

        override public function updateStage(width:Number, height:Number):void
        {
            // ContainerManager викликає updateStage після оновлення масштабу
            // та геометрії контейнерів. Звичайний Stage RESIZE приходив раніше
            // і саме тому панель спочатку стрибала, а потім поверталася.
            super.updateStage(width, height);
            if (_panel) _panel.updatePosition();
            if (_battleBadge) _battleBadge.updatePosition();
        }

        private function _createPanel():void
        {
            if (_panel) return;
            _panel = new InqMarksPanelComponent();
            _panel.addEventListener(InqMarksPanelEvent.OFFSET_CHANGED, _onOffsetChanged);
            _panel.addEventListener(InqMarksPanelEvent.MARK_BADGE_TOGGLE, _onMarkBadgeToggle);
            _panel.addEventListener(InqMarksPanelEvent.MARK_BADGE_OFFSET_CHANGED, _onMarkBadgeOffsetChanged);
            _panel.setVisibleState(false);
            addChild(_panel);

            _battleBadge = new InqMarksBattleMarkBadge();
            _battleBadge.addEventListener(
                InqMarksPanelEvent.BATTLE_BADGE_OFFSET_CHANGED,
                _onBattleBadgeOffsetChanged);
            _battleBadge.visible = false;
            if (attachBattleBadge())
            {
                // У бою badge живе у BaseBattlePage, як штатні HUD-компоненти.
            }
            else
            {
                addChild(_battleBadge);
            }
            _battleBadge.updatePosition();
        }

        protected function attachBattleBadge():Boolean
        {
            return false;
        }

        protected function detachBattleBadge():void
        {
        }

        private function _destroyPanel():void
        {
            if (_panel)
            {
                _panel.removeEventListener(InqMarksPanelEvent.OFFSET_CHANGED, _onOffsetChanged);
                _panel.removeEventListener(InqMarksPanelEvent.MARK_BADGE_TOGGLE, _onMarkBadgeToggle);
                _panel.removeEventListener(
                    InqMarksPanelEvent.MARK_BADGE_OFFSET_CHANGED,
                    _onMarkBadgeOffsetChanged);
                _panel.dispose();
                if (_panel.parent) _panel.parent.removeChild(_panel);
                _panel = null;
            }
            if (_battleBadge)
            {
                detachBattleBadge();
                _battleBadge.removeEventListener(
                    InqMarksPanelEvent.BATTLE_BADGE_OFFSET_CHANGED,
                    _onBattleBadgeOffsetChanged);
                _battleBadge.dispose();
                if (_battleBadge.parent) _battleBadge.parent.removeChild(_battleBadge);
                _battleBadge = null;
            }
        }

        private function _replayPendingCalls():void
        {
            if (_pendingCalls.length == 0) return;
            var calls:Array = _pendingCalls;
            _pendingCalls = [];
            for (var i:int = 0; i < calls.length; i++)
            {
                var call:Object = calls[i];
                var fn:Function = call.fn as Function;
                if (fn != null) fn.apply(null, call.args);
            }
        }

        private function _onOffsetChanged(event:InqMarksPanelEvent):void
        {
            if (py_onDragEnd != null) py_onDragEnd(event.data);
        }

        private function _onMarkBadgeToggle(event:InqMarksPanelEvent):void
        {
            if (py_onMarkBadgeToggle != null)
                py_onMarkBadgeToggle(Boolean(event.data));
        }

        private function _onMarkBadgeOffsetChanged(event:InqMarksPanelEvent):void
        {
            if (py_onMarkBadgeOffsetChanged != null)
                py_onMarkBadgeOffsetChanged(event.data);
        }

        private function _onBattleBadgeOffsetChanged(event:InqMarksPanelEvent):void
        {
            if (py_onBattleBadgeOffsetChanged != null)
                py_onBattleBadgeOffsetChanged(event.data);
        }

        private function _bringToFront():void
        {
            try
            {
                if (parent != null)
                    parent.setChildIndex(this, parent.numChildren - 1);
            }
            catch (e:Error) {}
        }

        public function as_setMoeData(p65:int, p85:int, p95:int, p100:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMoeData, args: [p65, p85, p95, p100]}); return; }
            if (_panel) _panel.setMoeData(p65, p85, p95, p100);
        }

        public function as_setBattleHistory(values:Array, currentMark:Number):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setBattleHistory, args: [values, currentMark]}); return; }
            if (_panel) _panel.setBattleHistory(values, currentMark);
        }

        public function as_setLastBattleDamage(value:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setLastBattleDamage, args: [value]}); return; }
            if (_panel) _panel.setLastBattleDamage(value);
        }

        public function as_setMarkBadgeOpen(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeOpen, args: [value]}); return; }
            if (_panel) _panel.setMarkBadgeOpen(value);
        }

        public function as_setMarkBadgeEnabled(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeEnabled, args: [value]}); return; }
            if (_panel) _panel.setMarkBadgeEnabled(value);
        }

        public function as_setMarkBadgeControlVisible(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeControlVisible, args: [value]}); return; }
            if (_panel) _panel.setMarkBadgeControlVisible(value);
        }

        public function as_setPanelBodyVisible(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setPanelBodyVisible, args: [value]}); return; }
            if (_panel) _panel.setPanelBodyVisible(value);
        }

        public function as_setMarkBadgeOffset(offset:Array):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeOffset, args: [offset]}); return; }
            if (_panel) _panel.setMarkBadgeOffset(offset);
        }

        public function as_setBattleBadgeOffset(offset:Array):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setBattleBadgeOffset, args: [offset]}); return; }
            if (_battleBadge) _battleBadge.setPositionOffset(offset);
        }

        public function as_setMarkBadgeStars(value:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeStars, args: [value]}); return; }
            if (_panel) _panel.setMarkBadgeStars(value);
        }

        public function as_setMarkBadgeStyle(value:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setMarkBadgeStyle, args: [value]}); return; }
            if (_panel) _panel.setMarkBadgeStyle(value);
        }

        public function as_setBattleBadgeStyle(value:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setBattleBadgeStyle, args: [value]}); return; }
            if (_battleBadge) _battleBadge.setStyle(value);
        }

        public function as_setBattleBadgeData(
            currentMark:Number, p65:int, p85:int, p95:int, p100:int,
            currentDamage:int, baseDamage:int, stars:int,
            projectedMark:Number = -1.0, projectedAvg:int = 0):void
        {
            if (!_configDone)
            {
                _pendingCalls.push({fn: this.as_setBattleBadgeData, args: [
                    currentMark, p65, p85, p95, p100, currentDamage,
                    baseDamage, stars, projectedMark, projectedAvg]});
                return;
            }
            if (_battleBadge)
                _battleBadge.setData(
                    currentMark, p65, p85, p95, p100, currentDamage,
                    baseDamage, stars, projectedMark, projectedAvg);
        }

        public function as_setBattleBadgeDamage(currentDamage:int):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setBattleBadgeDamage, args: [currentDamage]}); return; }
            if (_battleBadge) _battleBadge.setCurrentDamage(currentDamage);
        }

        public function as_setBattleBadgeExpanded(value:Boolean):void
        {
            if (_battleBadge) _battleBadge.setExpanded(value);
        }

        public function as_setBattleBadgeVisible(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setBattleBadgeVisible, args: [value]}); return; }
            if (_battleBadge)
            {
                _battleBadge.visible = value;
                _battleBadge.updatePosition();
            }
            if (_panel && value)
                _panel.setVisibleState(false);
        }

        public function as_setLoading():void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setLoading, args: []}); return; }
            if (_panel) _panel.setLoading();
        }

        public function as_clearData():void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_clearData, args: []}); return; }
            if (_panel) _panel.clearData();
        }

        public function as_setVisible(value:Boolean):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setVisible, args: [value]}); return; }
            if (_panel) _panel.setVisibleState(value);
        }

        public function as_setPosition(offset:Array):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setPosition, args: [offset]}); return; }
            if (_panel) _panel.setPositionOffset(offset);
        }

        public function as_setLocalization(data:Object):void
        {
            if (!_configDone) { _pendingCalls.push({fn: this.as_setLocalization, args: [data]}); return; }
            if (_panel) _panel.setLocalization(data);
        }
    }
}
