/**
 * User: tamt
 * Date: 14-3-14
 * Time: 上午9:11
 */
package {
import findRef.*;

import flash.display.DisplayObjectContainer;
import flash.events.Event;

import morn.editor.Plugin;
import morn.editor.PluginBase;

import mx.controls.Tree;
import mx.events.ListEvent;
import mx.managers.PopUpManager;

import util.Util;

/**
 * 查找资源引用
 */
public class FindReference extends Plugin {
    static private var inited:Boolean;
    static private var pageTree:Tree;
    static private var result:FindResultView;
    static private var refFinder:ReferenceFinder;
    static private var progress:*;
    static private var uselessFinder:UselessFinder;

    public function FindReference() {
    }

    override public function start():void {
        if (initialize()) {
            var resource:String;
            if (selectedXmls && selectedXmls.length > 0) {
                resource = getResource(selectedXmls[0].xml);
            } else if (resTree.selectedItem) {
                resource = resTree.selectedItem.@asset;
            }

            if (resource) {
                var files:Array = getFileList(workPath + "\\morn\\pages");
                findReference(resource, files);
            } else {
                if (DisplayObjectContainer(builderMain.root).contains(result.panel)) {
                    PopUpManager.removePopUp(result.panel);
                } else {
                    PopUpManager.addPopUp(result.panel, builderMain.root);
                    PopUpManager.centerPopUp(result.panel);
                    alert("查找引用", "请在舞台上选择一个资源组件，或者在资源面板中选择一个资源");
                }
            }
        } else {
            alert("查找引用", "插件启动失败!");
        }
    }

    private function findReference(resource:String, files:Array):void {
        showWaiting("查找引用", "正在查找哪些页面使用了资源：" + resource);

        var group:* = finder.search("MessagePanel", DisplayObjectContainer(builderMain.root));
        if (group) {
            progress = group.msgLbl;
        }

        refFinder.find(resource, files);
    }

    static private function onFindOut(event:Event):void {
        closeWaiting();

        result.panel.title = refFinder.resource + "：" + refFinder.references.length + "个页面使用";
        result.setData(refFinder.resource, refFinder.references);

        if (!DisplayObjectContainer(builderMain.root).contains(result.panel)) {
            PopUpManager.addPopUp(result.panel, builderMain.root);
            PopUpManager.centerPopUp(result.panel);
        } else {
            PopUpManager.addPopUp(result.panel, builderMain.root);
        }
    }

    static private function onFinding(event:Event):void {
        if (progress) {
            progress.text = "【" + (refFinder.index + 1) + "/" + refFinder.files.length + "】" +
                    "查找引用：" + refFinder.resource;
        }
    }

    private static function initialize():Boolean {
        if (inited)return inited;

        pageTree = Tree(finder.search(Util.pageTreePath, builderMain));
        resTree = Tree(finder.search(Util.resTreePath, builderMain));

        result = new FindResultView();
        result.addEventListener(FindResultView.CLOSE, closeResult);
        result.addEventListener(FindResultView.FIND_USELESS, findUseless);
        result.addEventListener(FindResultView.SELECT, openSelected);

        refFinder = new ReferenceFinder();
        refFinder.addEventListener("progress", onFinding);
        refFinder.addEventListener("complete", onFindOut);

        uselessFinder = new UselessFinder();
        uselessFinder.addEventListener("progress", onUselessFinding);
        uselessFinder.addEventListener("complete", onUselessFindOut);

        inited = Boolean(pageTree);

        return inited;
    }

    private static function onUselessFindOut(event:Event):void {
        closeWaiting();

        result.panel.title = uselessFinder.uselesses.length + "个没有使用的资源（Del直接删除）";
        result.setData(null, uselessFinder.uselesses);
    }

    private static function onUselessFinding(event:Event):void {
        if (progress) {
            progress.text = "【资源：" + (uselessFinder.resourceIndex + 1) + "/" + uselessFinder.resources.length() + "】" +
                    "【文件：" + (uselessFinder.fileIndex + 1) + "/" + uselessFinder.files.length + "】";
        }
    }

    private static function openSelected(event:Event):void {
        if (result.resource) {
            PluginBase.openPage(result.list.selectedItem[1]);
        } else {
            var nodeInTree:XML = XML(resTree.dataProvider.source..item.(@asset == result.list.selectedItem));
            expandParents(nodeInTree);
            resTree.validateNow();
            var t:int = resTree.getItemIndex(nodeInTree);
            if (t >= 0) {
                resTree.selectedIndex = t;
                resTree.dispatchEvent(new ListEvent(ListEvent.CHANGE));
                resTree.scrollToIndex(t);
            }
        }
    }

    private static function expandParents(node:XML):void {
        if (node && !resTree.isItemOpen(node)) {
            resTree.expandItem(node, true);
            expandParents(node.parent());
        }
    }

    private static function findUseless(event:Event):void {
        showWaiting("查找没有引用的资源", "正在查找没有使用过的资源");

        var group:* = finder.search("MessagePanel", DisplayObjectContainer(builderMain.root));
        if (group) {
            progress = group.msgLbl;
        }

        uselessFinder.find(resTree.dataProvider.source..item, getFileList(workPath + "\\morn\\pages"));
    }

    private static function closeResult(event:Event):void {
        PopUpManager.removePopUp(result.panel);
    }

    public function getResource(node:XML):String {
        var result:*
        for each (var attr:XML in node.attributes()) {
            if (result = /(png|jpg|jpeg)\.(\w+\.)*[^\s"]+/ig.exec(attr.toString())) {
                return result[0];
            }
        }

        if (node.name() == "UIView") {
            return String(node.@source);
        }

        return null;
    }

}
}

