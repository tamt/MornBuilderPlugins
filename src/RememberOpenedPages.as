/**
 * User: tamt
 * Date: 14-4-18
 * Time: 下午4:53
 */
package {
import flash.events.Event;
import flash.utils.setTimeout;

import morn.editor.Plugin;
import morn.editor.PluginBase;

import util.Util;

/**
 * 显示上次打开的页面
 */
public class RememberOpenedPages extends Plugin {

    private static var inited:Boolean = false;
    private static var uiMgr:*;

    private static var pluginConfig:XML;

    override public function start():void {
        if (initialize()) {
            var pages:Array = String(pluginConfig.plugin.lastPages).split(";");
            for (var i:int = 0; i < pages.length; i++) {
                var page:String = pages[i];
                setTimeout(openPage, 300 * (i + 1), page);
            }
        } else {
            log("插件RememberOpenedPages启动失败");
        }
    }

    private static function initialize():Boolean {
        if (inited)return Boolean(uiMgr && pluginConfig);

        inited = true;

        pluginConfig = new XML(readTxt(pluginPath + "/RememberOpenedPages/config.xml"));

        uiMgr = finder.search(Util.uiMgrPath, builderMain);
        if (!viewPath) {
            uiMgr.addEventListener("childAdd", onAddChild);
        }

        return Boolean(uiMgr && pluginConfig);
    }

    private static function onAddChild(event:Event):void {
        if (!viewPath) {
            setTimeout(saveOpenPages, 100);
        }
    }

    private static function saveOpenPages():void {
        pluginConfig.plugin.lastPages = (uiMgr.openPages as Array).join(";");
        setTimeout(PluginBase.writeTxt, 4000, pluginPath + "/RememberOpenedPages/config.xml", pluginConfig.toXMLString());
    }

    override public function onPageChanged(e:Event):void {
        saveOpenPages();
    }

}
}
