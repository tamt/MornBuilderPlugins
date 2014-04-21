/**
 * User: tamt
 * Date: 14-3-14
 * Time: 上午9:11
 */
package {
import findRes.*;

import com.hillelcoren.components.AutoComplete;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.ui.Keyboard;

import morn.editor.Plugin;

import morn.editor.PluginBase;

import mx.collections.XMLListCollection;
import mx.containers.TitleWindow;
import mx.controls.Tree;
import mx.core.ClassFactory;
import mx.events.ListEvent;
import mx.managers.PopUpManager;

import util.DisplayObjectFinder;

import util.Util;

public class FindResource extends Plugin {

    private static var resTree:Tree;
    private static var resources:XMLListCollection;
    private static var auto:AutoComplete;
    private static var window:TitleWindow;

    public function FindResource() {
    }

    override public function start():void {
        initialize();
    }

    private static function initialize(event:Event = null):void {
        if (resTree == null) {
            var finder:DisplayObjectFinder = new DisplayObjectFinder();
            var root:DisplayObjectContainer = DisplayObjectContainer(DisplayObjectContainer(builderMain.root).getChildAt(0));
            resTree = Tree(finder.search(util.Util.resTreePath, root));
            if (resTree) {
                auto = new AutoComplete();
                auto.width = 300;
                resources = new XMLListCollection(resTree.dataProvider.source..item);
                auto.dataProvider = resources;
                auto.labelFunction = searchLabelFunction;
                auto.dropDownLabelFunction = listLabelFunction;
                auto.matchType = "anyPart";
                auto.setStyle("selectedItemStyleName", "underline");
                auto.addEventListener("change", onChange);
                auto.dropDownItemRenderer = new ClassFactory(AssetItemRenderer);

                window = new TitleWindow();
                window.title = "查找资源";
                window.width = 303;
                window.height = 55;
                window.addChild(auto);
            }
        } else {
            resources = new XMLListCollection(resTree.dataProvider.source..item);
            auto.dataProvider = resources;
        }

        if (auto) {
            PopUpManager.addPopUp(window, DisplayObject(builderMain.root));
            PopUpManager.centerPopUp(window);
            builderStage.addEventListener(KeyboardEvent.KEY_UP, handleKey)
            auto.setFocus();
        }
    }

    private static function handleKey(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.ESCAPE) {
            remove();
        }
    }

    private static function remove():void {
        builderStage.removeEventListener(KeyboardEvent.KEY_UP, handleKey)
        PopUpManager.removePopUp(window);
    }

    private static function onChange(event:Event):void {
        var nodeInTree:XML = XML(resTree.dataProvider.source..item.(@asset == auto.selectedItem.@asset));
        expandParents(nodeInTree);
        resTree.validateNow();
        var t:int = resTree.getItemIndex(nodeInTree)
        if (t >= 0) {
            resTree.selectedIndex = t;
            resTree.dispatchEvent(new ListEvent(ListEvent.CHANGE));
            PluginBase.log("scroll to index result: " + resTree.scrollToIndex(t));
        }
        auto.clear();
        remove();
    }

    private static function expandParents(node:XML):void {
        if (node && !resTree.isItemOpen(node)) {
            resTree.expandItem(node, true);
            expandParents(node.parent());
        }
    }

    private static function listLabelFunction(item:XML):String {
        var label:String = item.@asset;
        return label;
    }

    private static function searchLabelFunction(item:XML):String {
        var label:String = item.@asset;
        return label;
    }
}
}