/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午7:10
 */
package {
import flash.display.Sprite;

public class AllInOne extends Sprite {

    private static var inited:Boolean;

    public function AllInOne() {
        if (!stage) {
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
                    new tInspector
                ];
            }
        }
    }
}
}
