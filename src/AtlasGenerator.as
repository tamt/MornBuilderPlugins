/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午6:57
 */
package {
import atlas.AtlasGeneratorConfig;

import flash.events.ProgressEvent;
import flash.filesystem.File;

import morn.editor.Plugin;

import mx.controls.Alert;
import mx.managers.PopUpManager;

/**
 * 调用python，把morn下的assets生成atlas材质图（不包括swf资源）
 */
public class AtlasGenerator extends Plugin {

    private var python:File;

    override public function start():void {
        python = new File(pluginPath + "/" + pluginName + "/tagen.py");
        if (python.exists) {
            var config:AtlasGeneratorConfig = new AtlasGeneratorConfig();
            PopUpManager.addPopUp(config, builderMain);
            PopUpManager.centerPopUp(config);
            alert(pluginName, "你确定要生成atlas吗？", Alert.OK | Alert.CANCEL, confirmGenerate);
        } else {
            alert(pluginName, "找不到tagen.py");
        }
    }

    private function confirmGenerate(e:Object):void {
        if (e.detail == Alert.OK) {
            var cmd:String = pluginConfig.python + " " + python.nativePath + " -t " + pluginConfig.texturesize + " -c " + workPath + "/morn/assets/" + " " + workPath + "/morn/atlas/";
            exeCmds([cmd], onDeleteComplete, onDeleteProgress, onDeleteError);
        }
    }

    private function onDeleteProgress(e:ProgressEvent):void {
    }

    private function onDeleteError(...args):void {
        log("出错");
    }

    private function onDeleteComplete():void {
        //TODO 删除成功是否现在刷新资源
        log("完成");
    }

}
}
