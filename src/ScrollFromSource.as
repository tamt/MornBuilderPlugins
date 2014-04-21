/**
 * User: tamt
 * Date: 14-3-31
 * Time: 上午9:38
 */
package {
import flash.events.MouseEvent;
import flash.filesystem.File;
import flash.system.System;
import flash.utils.setTimeout;

import morn.editor.Plugin;

import mx.containers.HBox;
import mx.controls.FileSystemTree;
import mx.controls.Tree;
import mx.events.ListEvent;

import scrollSource.*;

import spark.components.Button;
import spark.components.Panel;

import util.DisplayObjectFinder;
import util.Util;

public class ScrollFromSource extends Plugin {

    private static var inited:Boolean;
    private static var finder:DisplayObjectFinder;
    private static var resPanel:Panel;
    private static var pagePanel:Panel;

    [Embed("../asset/ScrollFromSource/scroll.png")]
    private static var ICON_SCROLL:Class;

    [Embed("../asset/ScrollFromSource/copy_name.png")]
    private static var ICON_COPY_NAME:Class;

    [Embed("../asset/ScrollFromSource/copy_path.png")]
    private static var ICON_COPY_PATH:Class;

    private static var ctrlPage:HBox;
    private static var ctrlResource:HBox;

    private static var pageTree:FileSystemTree;
    private static var resTree:Tree;

    override public function start():void {
        if (initialize()) {
            if (viewPath || selectedResource) {
                scrollToResource();
                scrollToPage();
                toggleControlBarBtn(pagePanel, ctrlPage, true);
                toggleControlBarBtn(resPanel, ctrlResource, true);
            } else {
                toggleControlBarBtn(pagePanel, ctrlPage);
                toggleControlBarBtn(resPanel, ctrlResource);
            }
        } else {
            alert("定位页面和资源", "插件启动失败");
        }
    }

    private function toggleControlBarBtn(panel:Panel, hbox:HBox, forceDisplay:Boolean = false):void {
        if (!panel.contains(hbox) || forceDisplay) {
            panel.addElement(hbox);
            hbox.move(0, -25);
        } else {
            panel.removeElement(hbox);
        }
        panel.invalidateDisplayList();
    }

    static public function initialize():Boolean {
        if (inited)return Boolean(pagePanel);
        inited = true;

        finder = new DisplayObjectFinder();
        pageTree = FileSystemTree(finder.search(Util.pageTreePath, builderMain));
        resTree = Tree(finder.search(Util.resTreePath, builderMain));
        pagePanel = Panel(finder.search(Util.pagePanelPath, builderMain));
        resPanel = Panel(finder.search(Util.resPanelPath, builderMain));

        ctrlPage = new HBox();
        ctrlPage.setStyle("horizontalAlign", "right");
        ctrlPage.setStyle("paddingRight", 5);
        ctrlPage.percentWidth = 100;
        var scrollPage:Button = new Button();
        scrollPage.setStyle("skinClass", ImageButtonSkin);
        scrollPage.setStyle("icon", ICON_SCROLL);
        scrollPage.width = 20;
        scrollPage.height = 20;
        scrollPage.toolTip = "定位当前页面";
        scrollPage.addEventListener(MouseEvent.CLICK, scrollToPage);
        ctrlPage.addElement(scrollPage);

        ctrlResource = new HBox();
        ctrlResource.setStyle("horizontalAlign", "right");
        ctrlResource.setStyle("paddingRight", 5);
        ctrlResource.percentWidth = 100;

        var copyName:Button = new Button();
        copyName.setStyle("icon", ICON_COPY_NAME);
        copyName.setStyle("skinClass", ImageButtonSkin);
        copyName.width = 20;
        copyName.height = 20;
        copyName.toolTip = "复制资源的名称";
        copyName.addEventListener(MouseEvent.CLICK, copyResName);
        ctrlResource.addElement(copyName);

        var copyPath:Button = new Button();
        copyPath.setStyle("icon", ICON_COPY_PATH);
        copyPath.setStyle("skinClass", ImageButtonSkin);
        copyPath.width = 20;
        copyPath.height = 20;
        copyPath.toolTip = "复制资源文件的路径";
        copyPath.addEventListener(MouseEvent.CLICK, copyResPath);
        ctrlResource.addElement(copyPath);

        var scrollResource:Button = new Button();
        scrollResource.setStyle("icon", ICON_SCROLL);
        scrollResource.setStyle("skinClass", ImageButtonSkin);
        scrollResource.width = 20;
        scrollResource.height = 20;
        scrollResource.toolTip = "定位当前资源";
        scrollResource.addEventListener(MouseEvent.CLICK, scrollToResource);
        ctrlResource.addElement(scrollResource);

        return Boolean(pagePanel);
    }

    private static function scrollToPage(event:MouseEvent = null):void {
        //不知道为什么，这边要延迟调用才会选中状态才会正常……
        pageTree.callLater(function ():void {
            if (viewPath) {
                var file:File = new File(viewPath);
                if (file.exists) {
                    if (file.parent.isDirectory) {
                        pageTree.openSubdirectory(file.parent.nativePath);
                        pageTree.validateNow();
                    }
                    var idx:int = pageTree.findIndex(file.nativePath);
                    pageTree.selectedIndex = idx;
                    pageTree.scrollToIndex(idx);
                }
            }
        });
    }

    private static function copyResPath(event:MouseEvent):void {
        var res:String = /*selectedResource || */resTree.selectedItem.@asset;
        if (res) {
            log("复制路径:" + getResourceNativePath(res));
            System.setClipboard(getResourceNativePath(res));
        }
    }

    private static function copyResName(event:MouseEvent):void {
        var res:String = /*selectedResource || */resTree.selectedItem.@asset;
        if (res) {
            log("复制名称:" + res);
            System.setClipboard(res);
        }
    }

    private static function scrollToResource(event:MouseEvent = null):void {
        var resource:String = selectedResource;

        if (resource) {
            log("定位资源：" + resource);
            var nodeInTree:XML = XML(resTree.dataProvider.source..item.(@asset == resource));
            Util.expandParents(resTree, nodeInTree);
            resTree.validateNow();
            var t:int = resTree.getItemIndex(nodeInTree);
            if (t >= 0) {
                resTree.selectedIndex = t;
                resTree.dispatchEvent(new ListEvent("change"));
                resTree.scrollToIndex(t);
            }
        }
    }

    private static function get selectedResource():String {
        var resource:String;
        if (selectedXmls && selectedXmls.length > 0) {
            resource = Util.getResource(selectedXmls[0].xml);
        }
        return resource;
    }
}
}
