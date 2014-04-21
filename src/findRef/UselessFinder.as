/**
 * User: tamt
 * Date: 14-3-20
 * Time: 下午1:56
 */
package findRef{
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.Dictionary;
import flash.utils.getTimer;

import morn.editor.PluginBase;

public class UselessFinder extends EventDispatcher {

    public var fileIndex:int;
    public var files:Array;
    public var resourceIndex:int;
    public var resources:XMLList;

    public var resource:String;
    public var uselesses:Array;
    private var fileContentCache:Dictionary;

    public function UselessFinder() {

    }

    public function find(resources:XMLList, files:Array):void {
        this.files = files;
        this.fileIndex = 0;
        this.resourceIndex = 0;
        this.resources = resources;

        this.resource = "";
        this.uselesses = [];
        this.fileContentCache = new Dictionary();

        PluginBase.builderMain.addEventListener(Event.ENTER_FRAME, next);
    }

    private function next(event:Event):void {
        var time:int = 1000 / PluginBase.builderStage.frameRate;
        var start:int = getTimer();

        dispatchEvent(new Event("progress"));

        while ((getTimer() - start) < time) {
            //所有resource已经查找完毕
            if (resourceIndex >= resources.length()) {
                PluginBase.builderMain.removeEventListener(Event.ENTER_FRAME, next);
                dispatchEvent(new Event("complete"));
                break;
            }

            resource = this.resources[this.resourceIndex].@asset;

            var file:String = files[fileIndex++][1];
            var content:String = getFileContent(file);
            if (content.indexOf('"' + resource + '"') > 0) {
                //这个resource存在引用，查找下个resource
                resourceIndex++;
                fileIndex = 0;
                break;
            }

            if (fileIndex >= files.length) {
                //这个resource不存在引用
                uselesses.push(resource);
                //查找下个resource
                resourceIndex++;
                fileIndex = 0;
            }
        }

    }

    private function getFileContent(file:String):String {
        if (!fileContentCache[file]) {
            fileContentCache[file] = PluginBase.readTxt(file);
        }
        return fileContentCache[file];
    }
}
}
