package com.inq.marks
{
    import flash.events.Event;

    public class InqMarksPanelEvent extends Event
    {
        public static const OFFSET_CHANGED:String = "MarksPanel.offsetChanged";
        public static const MARK_BADGE_TOGGLE:String = "MarksPanel.markBadgeToggle";
        public static const MARK_BADGE_OFFSET_CHANGED:String = "MarksPanel.markBadgeOffsetChanged";
        public static const BATTLE_BADGE_OFFSET_CHANGED:String = "MarksPanel.battleBadgeOffsetChanged";

        public var data:*;

        public function InqMarksPanelEvent(
            type:String, data:* = null,
            bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
            this.data = data;
        }

        override public function clone():Event
        {
            return new InqMarksPanelEvent(type, data, bubbles, cancelable);
        }
    }
}
