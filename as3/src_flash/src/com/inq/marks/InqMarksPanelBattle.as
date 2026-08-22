package com.inq.marks
{
    import flash.events.Event;
    import net.wg.data.constants.generated.LAYER_NAMES;
    import net.wg.gui.battle.components.BattleUIDisplayable;
    import net.wg.gui.battle.views.BaseBattlePage;
    import net.wg.gui.components.containers.MainViewContainer;

    public class InqMarksPanelBattle extends InqMarksPanelInjector
    {
        private var _battleHost:BattleUIDisplayable = null;
        private var _battlePage:BaseBattlePage = null;

        public function InqMarksPanelBattle()
        {
            super();
        }

        override protected function attachBattleBadge():Boolean
        {
            var views:MainViewContainer = App.containerMgr.getContainer(
                LAYER_NAMES.LAYER_ORDER.indexOf(LAYER_NAMES.VIEWS)) as MainViewContainer;
            if (!views) return false;
            for (var i:int = 0; i < views.numChildren; i++)
            {
                var page:BaseBattlePage = views.getChildAt(i) as BaseBattlePage;
                if (!page) continue;
                _battlePage = page;
                _battleHost = new BattleUIDisplayable();
                _battleHost.addChild(_battleBadge);
                _battleBadge.attachCollapseOverlay(_battleHost);
                _battlePage.addChild(_battleHost);
                _battlePage.addEventListener(Event.RESIZE, onBattlePageResize);
                return true;
            }
            return false;
        }

        override protected function detachBattleBadge():void
        {
            if (_battlePage)
            {
                try
                {
                    _battlePage.removeEventListener(Event.RESIZE, onBattlePageResize);
                }
                catch (error:Error)
                {
                    // BattlePage може бути вже знищена раніше за injector.
                }
            }
            if (_battleBadge)
                _battleBadge.detachCollapseOverlay();
            if (_battleBadge && _battleBadge.parent)
                _battleBadge.parent.removeChild(_battleBadge);
            if (_battleHost)
            {
                if (_battleHost.parent) _battleHost.parent.removeChild(_battleHost);
                // BaseBattlePage сам dispose-ить дочірні UIComponent під час
                // знищення battle.swf. Повторний dispose ламав перехід в ангар.
                if (!_battleHost.isDisposed())
                    _battleHost.dispose();
                _battleHost = null;
            }
            _battlePage = null;
        }

        private function onBattlePageResize(event:Event):void
        {
            if (_battleBadge) _battleBadge.updatePosition();
        }
    }
}
