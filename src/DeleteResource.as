/**
 * User: tamt
 * Date: 14-4-7
 * Time: 下午6:57
 */
package {
import flash.events.KeyboardEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.ui.Keyboard;

import morn.editor.Plugin;
import morn.editor.PluginBase;

import mx.controls.Alert;
import mx.controls.Tree;
import mx.managers.FocusManager;

import util.DisplayObjectFinder;
import util.Util;

public class DeleteResource extends Plugin {

    override public function start():void {

        if (PluginBase.builderStage) {
            PluginBase.builderStage.removeEventListener(KeyboardEvent.KEY_UP, handleKey);
            PluginBase.builderStage.addEventListener(KeyboardEvent.KEY_UP, handleKey);
        }
    }

    private function handleKey(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.DELETE) {
            var focusMgr:FocusManager = builderMain['focusManager'];
            if (!resTree) resTree = Tree(finder.search(Util.resTreePath, builderMain));
            if (focusMgr) {
                if (resTree && resTree.selectedItem && focusMgr.getFocus() == resTree) {
                    alert("删除资源", "你确定要删除资源吗？", Alert.OK | Alert.CANCEL, confirmDelResource);
                }
            }
        }
    }

    private function confirmDelResource(e:Object):void {
        if (e.detail == Alert.OK) {
            var path:String = getResourceNativePath(String(resTree.selectedItem.@asset));
            var file:File = new File(path);
            if (file.exists) {
                var cmd:String = "del " + path;
                exeCmds([cmd], onDeleteComplete, onDeleteProgress, onDeleteError);
            } else {
                alert("错误", "文件不存在。注意不支持swf元件的删除");
            }
        }
    }

    private function onDeleteProgress(e:ProgressEvent):void {
    }

    private function onDeleteError(...args):void {
    }

    private function onDeleteComplete():void {
        //TODO 删除成功是否现在刷新资源
    }

}
}
