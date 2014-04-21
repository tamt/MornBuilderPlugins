/**
 * User: tamt
 * Date: 14-3-28
 * Time: 上午11:11
 */
package {
import com.hillelcoren.components.AutoComplete;

import flash.display.DisplayObject;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.filesystem.File;
import flash.ui.Keyboard;
import flash.utils.setTimeout;

import morn.editor.Plugin;

import morn.editor.PluginBase;

import mx.collections.ArrayCollection;
import mx.containers.TitleWindow;
import mx.controls.FileSystemTree;
import mx.managers.PopUpManager;

import util.DisplayObjectFinder;

import util.Util;

/**
 * 打开页面
 */
public class OpenPage extends Plugin {

    private static var inited:Boolean;
    private static var auto:AutoComplete;
    private static var window:TitleWindow;
    private static var finder:DisplayObjectFinder;
    private static var pageTree:FileSystemTree;
    private static var isShiftDown:Boolean;

    public function OpenPage() {
    }

    override public function start():void {
        if (initialize()) {
            auto.dataProvider = new ArrayCollection(getFileList(workPath + "\\morn\\pages"));
            PopUpManager.addPopUp(window, DisplayObject(builderMain.root));
            PopUpManager.centerPopUp(window);
            builderStage.addEventListener(KeyboardEvent.KEY_DOWN, handleKey);
            setTimeout(function () {
                auto.setFocus();
                auto.clear();
            }, 100);
        } else {
            log("OpenPage插件初始化失败");
        }
    }

    static public function initialize():Boolean {
        if (inited)return inited;

        auto = new AutoComplete();
        auto.width = 300;
        auto.labelFunction = searchLabelFunction;
        auto.dropDownLabelFunction = listLabelFunction;
        auto.matchType = "anyPart";
        auto.setStyle("selectedItemStyleName", "underline");
        auto.addEventListener("change", onChange);

        window = new TitleWindow();
        window.title = "打开页面";
        window.width = 303;
        window.height = 55;
        window.addChild(auto);

        finder = new DisplayObjectFinder()
        pageTree = FileSystemTree(finder.search(util.Util.pageTreePath, builderMain));

        inited = auto && window && pageTree;

        return inited;
    }

    private static function handleKey(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.ESCAPE) {
            remove();
        } else if (event.keyCode == Keyboard.SHIFT) {
            isShiftDown = event.shiftKey;
        }
    }

    private static function onChange(event:Event):void {
        var selected:String = auto.selectedItem[1];
        var file:File = new File(selected);
        if (file.exists) {
            if (isShiftDown) {
                PluginBase.openPage(file.nativePath);
            }
            if (file.parent.isDirectory) {
                pageTree.openSubdirectory(file.parent.nativePath);
                pageTree.validateNow();
            }
            var idx:int = pageTree.findIndex(file.nativePath);
            pageTree.selectedIndex = idx;
            pageTree.scrollToIndex(idx);
        } else {
            alert("错误", "页面文件已经不存在");
        }
        auto.clear();
        remove();
    }

    private static function remove():void {
        isShiftDown = false;
        builderStage.removeEventListener(KeyboardEvent.KEY_DOWN, handleKey);
        PopUpManager.removePopUp(window);
    }

    private static function listLabelFunction(item:Array):String {
        var label:String = item[1];
        label = label.slice((workPath + "\\morn\\pages").length + 1);
        return label;
    }

    private static function searchLabelFunction(item:Array):String {
        var label:String = item[1];
        label = label.slice((workPath + "\\morn\\pages").length + 1);
        return label;
    }
}
}
