package com.inq.marks
{
    /**
     * Polaroid renderer.
     *
     * The reference overlay shows the current 198 px frame is about 3.5%
     * wider than the target. Only horizontal size is corrected here:
     * 198 px -> 191 px. Vertical scale remains untouched so text, stars
     * and frame are not flattened.
     */
    public class InqMarksPolaroidRenderer extends InqMarksBattleRendererBase
    {
        private static const TARGET_WIDTH:Number = 191.0;
        private static const SOURCE_WIDTH:Number = 198.0;

        public function InqMarksPolaroidRenderer()
        {
            super();
            setStyle(InqMarksBattleRendererBase.STYLE_POLAROID);

            scaleX = TARGET_WIDTH / SOURCE_WIDTH;
            scaleY = 1.0;
        }
    }
}
