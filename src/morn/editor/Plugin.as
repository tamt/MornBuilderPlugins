/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午6:30
 */
package morn.editor {
import flash.utils.setTimeout;

import mx.controls.Tree;

import util.DisplayObjectFinder;

public class Plugin extends PluginBase {

    static protected var resTree:Tree;
    static protected var finder:DisplayObjectFinder;

    protected var pluginConfig:XML;
    protected var pluginName:String;

    public function Plugin() {
        pluginName = String(this).slice("[object ".length, -1);
        pluginConfig = new XML(readTxt(pluginPath + "/" + pluginName + "/config.xml"));
        if (pluginConfig.plugin.autostart == "true") {
            log("自动启动：" + pluginName);
            setTimeout(start, 1000);
        }

        if (!finder) finder = new DisplayObjectFinder();
    }

    static public function getResourceNativePath(resource:String):String {
        var arr:Array = resource.split(".");
        var extension:String = arr.shift();
        var relative:String = arr.join("/") + "." + extension;
        return getPath(workPath + "/morn/assets/", relative);
    }

    static public function getResourceFileName(resource:String, newName:String = null):String {
        var arr:Array = resource.split(".");
        var extension:String = arr.shift();
        return (newName ? newName : arr[arr.length - 1]) + "." + extension;
    }

    static public function getDirNativePath(dir:XML):String {
        var relative:String = dir.@name;
        while (dir = dir.parent()) {
            if (String(dir.@name)) {
                relative = dir.@name + "/" + relative;
            }
        }
        return PluginBase.getPath(PluginBase.workPath + "/morn/assets/", relative);
    }

    public static function getResourceName(resource:String):String {
        var arr:Array = resource.split(".");
        return arr[arr.length - 1];
    }

    public static function getResourceFromPath(filePath:String):String {
        var base:String = (workPath + "\\morn\\assets\\");
        var relative:String = filePath.slice(base.length);
        var arr:Array = relative.split("\\");
        var file:Array = arr.pop().split(".");
        return file[1] + "." + arr.join(".") + (arr.length ? "." : "") + file[0];
    }

    public static function get isInEditor():Boolean {
        return App.asset is BuilderResManager;
    }
}
}
