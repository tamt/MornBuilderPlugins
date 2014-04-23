/**
 * User: tamt
 * Date: 14-4-22
 * Time: 下午2:51
 */
package {
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.system.Capabilities;
import flash.utils.Dictionary;

import morn.editor.Plugin;

import mx.containers.TabNavigator;

import util.Util;

public class iPhonePreview extends Plugin {

    private static var inited:Boolean;
    private static var uiMgr:TabNavigator;

    private static var screenPPI:int;
    private static var iphoneScale:Number;

    private static var NAME:String = "iPhone预览";

    private static var history:Dictionary = new Dictionary();

    public function iPhonePreview() {
    }

    override public function start():void {
        if (initialize()) {
            if (!screenPPI) {
                var config:XML = new XML(readTxt(pluginPath + "/iPhonePreview/config.xml"));
                if (parseInt(config.plugin.DisplayMonitorDiagonal)) {
                    var diagonal:Number = Math.sqrt(Capabilities.screenResolutionX * Capabilities.screenResolutionX + Capabilities.screenResolutionY * Capabilities.screenResolutionY);
                    screenPPI = diagonal / parseFloat(config.plugin.DisplayMonitorDiagonal);
                    iphoneScale = screenPPI / parseInt(config.plugin.iPhoneScreenPPI);
                } else {
                    alert(NAME, "你需要在 iPhonePreview/config.xml 中配置DisplayMonitorDiagonal（显示器的尺寸）");
                    return;
                }
            }

            for (var i:int = 0; i < uiMgr.numChildren; i++) {
                var uiViewer:DisplayObject = uiMgr.getChildAt(i);
                if (uiViewer.visible) {
                    var view:DisplayObject = finder.search("..3&", DisplayObjectContainer(uiViewer));
                    if (view) {
                        if (iphoneScale == view.scaleX) {
                            view.scaleX = view.scaleY = history[uiViewer['pagePath']].scale;
                            view.x = history[uiViewer['pagePath']].x;
                            view.y = history[uiViewer['pagePath']].y;
                        } else {
                            history[uiViewer['pagePath']] = {scale: view.scaleX, x: view.x, y: view.y};
                            view.scaleX = view.scaleY = iphoneScale == view.scaleX ? 1 : iphoneScale;
                            view.x = view.parent.width / 2 - view.scaleX * view['sceneWidth'] / 2;
                            view.y = view.parent.height / 2 - view.scaleY * view['sceneHeight'] / 2;
                        }
                        return;
                    }
                }
            }

            alert(NAME, "找不到舞台实例");
        } else {
            alert(NAME, "启动失败");
        }
    }

    private static function initialize():Boolean {
        if (inited)return Boolean(uiMgr);

        uiMgr = TabNavigator(finder.search(Util.uiMgrPath, builderMain));

        return Boolean(uiMgr);
    }
}
}

