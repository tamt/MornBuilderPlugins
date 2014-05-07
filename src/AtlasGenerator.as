/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午6:57
 */
package {
import atlas.AtlasGeneratorConfig;

import flash.events.Event;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.utils.describeType;

import morn.editor.Plugin;
import morn.editor.PluginBase;

import mx.managers.PopUpManager;

/**
 * 调用python，把morn下的assets生成atlas材质图（不包括swf资源）
 */
public class AtlasGenerator extends Plugin {

    private var python:File;

    private static var configer:AtlasGeneratorConfig;

    override public function start():void {
        python = new File(pluginPath + "/" + pluginName + "/tagen.py");
        if (python.exists) {
            if (!configer) {
                configer = new AtlasGeneratorConfig();
                configer.addEventListener("close", removeConfig);
                configer.addEventListener("ok", confirmGenerate);
            }
            PopUpManager.addPopUp(configer, builderMain);
            PopUpManager.centerPopUp(configer);
        } else {
            alert(pluginName, "找不到tagen.py");
        }
    }

    private function removeConfig(event:Event = null):void {
        PopUpManager.removePopUp(configer);
    }

    private function confirmGenerate(e:Object):void {
        //确定生成atlas图
        var xml:XML = describeType(configer.setting);
        var list:XMLList = xml..accessor;
        var options:String = "";
        var pType:String;
        var pName:String;
        var pValue:*;
        for each (var accessor:XML in list) {
            pType = String(accessor.@type);
            pName = String(accessor.@name);
            pValue = configer.setting[pName];
            if (pType == "Boolean") {
                if (pValue == true) {
                    options += (options ? " " : "") + "--" + pName + " ";
                }
            } else if (pValue != null) {
                options += (options ? " " : "") + "--" + pName + " " + pValue;
            }
        }

        var cmd:String = pluginConfig.plugin.python + " " + python.nativePath + " " + options + " " + configer.setting.infolder + " " + configer.setting.outfolder;
        PluginBase.log("python path:" + pluginConfig.plugin.python);
        PluginBase.log(cmd);

        PluginBase.showWaiting(pluginName, "正在生成atlas");
        exeCmds([cmd], onGenerateComplete, onGenerateProgress, onGenerateError);
    }

    private function onGenerateProgress(e:ProgressEvent):void {
    }

    private function onGenerateError(...args):void {
        alert(pluginName, "过程中出错，详细信息请看log(Ctrl+L)");
        PluginBase.closeWaiting();
    }

    private function onGenerateComplete(...args):void {
        PluginBase.closeWaiting();
        alert(pluginName, "生成atlas完毕");
    }

}
}
