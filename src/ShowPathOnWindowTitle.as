/**
 * User: tamt
 * Date: 14-4-18
 * Time: 下午4:53
 */
package {
import flash.events.Event;
import flash.utils.setTimeout;

import morn.editor.Plugin;

import mx.containers.TabNavigator;

import util.Util;

/**
 * 窗口的title上显示当前打开的页面
 */
public class ShowPathOnWindowTitle extends Plugin {

    private static var inited:Boolean = false;
    private static var uiMgr:TabNavigator;
    private static var originTitle:String;

    override public function start():void {
        if (initialize()) {
            onPageChanged(null);
        } else {
            log("插件ShowPathOnWindowTitle启动失败");
        }
    }

    private static function initialize():Boolean {
        if (inited)return Boolean(uiMgr);

        inited = true;
        originTitle = builderStage.nativeWindow.title;
        uiMgr = TabNavigator(finder.search(Util.uiMgrPath, builderMain));
        if (!viewPath) {
            uiMgr.addEventListener("childAdd", onAddChild);
        }

        return Boolean(uiMgr);
    }

    private static function onAddChild(event:Event):void {
        if (!viewPath) {
            setTimeout(changeWindowTitle, 100);
        }
    }

    override public function onPageChanged(e:Event):void {
        changeWindowTitle();
    }

    private static function changeWindowTitle():void {
        builderStage.nativeWindow.title = originTitle + (viewPath ? (" - " + viewPath + "") : "");
    }
}
}
