/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午7:10
 */
package {
import flash.events.Event;

import mx.preloaders.SparkDownloadProgressBar;

public class AllInOne extends SparkDownloadProgressBar {

    private static var inited:Boolean;

    override protected function completeHandler(event:Event):void {
        if (!inited) {
            inited = true;
            var plugins:Array = [
                new AutoSizeView,
                new DeleteResource,
                new FindReference,
                new FindResource,
                new OpenPage,
                new RefactorResource,
                new ScrollFromSource,
                new ShowPathOnWindowTitle,
                new iPhonePreview,
                new RememberOpenedPages,
                new AtlasGenerator,
                new tInspector
            ];
        }

        super.completeHandler(event);
    }
}
}
