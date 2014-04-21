/**
 * User: tamt
 * Date: 13-4-3
 * Time: 下午5:16
 */
package {
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.geom.Rectangle;

import morn.editor.Plugin;

/**
 * 自动设置页面尺寸以匹配内容
 */
public class AutoSizeView extends Plugin {
    public function AutoSizeView() {
        //利用log判断是否加载插件成功
        log("自动设置页面尺寸插件初始化完毕");
    }


    /**插件运行的起点*/
    override public function start():void {
        var viewXML:XML = viewXml.copy();

        var root:DisplayObjectContainer;
        var rect:Rectangle;
        for (var i:int = 0; i < int.MAX_VALUE; i++) {
            var comp:DisplayObject = getCompById(i);
            if (comp) {
                if (!root) {
                    root = comp.parent;
                    rect = new Rectangle();
                }

                rect = rect.union(comp.getRect(root));
            } else if (i >= 100) {
                //目前来看compId是从1开始计算的
                //这里只是防止万一前100都没有Component的话，插件还能正常工作。
                break;
            }
        }

        viewXML.@sceneWidth = Math.ceil(rect.right);
        viewXML.@sceneHeight = Math.ceil(rect.bottom);

        changeViewXml(viewXML, true)
    }
}
}
