package {
import com.hillelcoren.components.AutoComplete;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.ui.Keyboard;

import morn.editor.Plugin;

import mx.collections.XMLListCollection;
import mx.containers.HBox;
import mx.controls.Alert;
import mx.controls.Label;
import mx.controls.Tree;
import mx.events.CloseEvent;
import mx.events.CollectionEvent;
import mx.managers.PopUpManager;

import refRes.*;

import spark.components.Button;
import spark.components.TextInput;
import spark.components.TitleWindow;
import spark.layouts.VerticalLayout;

import util.DisplayObjectFinder;
import util.Util;

public class RefactorResource extends Plugin {
    private static var inited:Boolean;
    private static var finder:DisplayObjectFinder;
    private static var resTree:Tree;
    private static var auto:AutoComplete;
    private static var window:TitleWindow;
    private static var replace:ReplaceResource;
    private static var input:TextInput;

    private static const NAME:String = "移动资源";
    private static var fileFrom:File;
    private static var fileTo:File;
    private static var progress:*;
    private static var ok:Button;

    public function RefactorResource() {
    }

    override public function start():void {
        if (initialize()) {

            fileFrom = null;
            fileTo = null;

            if (selectedResource) {
                window.title = NAME + ":" + selectedResource;
                auto.dataProvider = new XMLListCollection(resTree.dataProvider.source..dir);

                PopUpManager.addPopUp(window, DisplayObject(builderMain.root), true);
                PopUpManager.centerPopUp(window);
                builderStage.addEventListener(KeyboardEvent.KEY_UP, handleKey);

                input.text = getResourceName(selectedResource);
                auto.setFocus();
            }
        } else {
            alert(NAME, "插件启动失败!");
        }
    }

    private static function initialize():Boolean {
        if (inited)return Boolean(resTree);
        inited = true;

        finder = new DisplayObjectFinder();
        resTree = Tree(finder.search(Util.resTreePath, builderMain));

        var hbox:HBox = new HBox();
        hbox.percentWidth = 100;
        hbox.setStyle("paddingLeft", 5);
        hbox.setStyle("paddingRight", 5);
        hbox.setStyle("paddingTop", 5);
        var label:Label = new Label();
        label.percentHeight = 100;
        label.text = "重命名：";
        input = new TextInput();
        input.restrict = "a-zA-Z0-9";
        hbox.addElement(label);
        hbox.addElement(input);

        var hbox1:HBox = new HBox();
        hbox1.percentWidth = 100;
        hbox1.setStyle("paddingLeft", 5);
        hbox1.setStyle("paddingRight", 5);
        hbox1.setStyle("paddingTop", 5);
        hbox1.setStyle("paddingBottom", 5);
        var label:Label = new Label();
        label.text = "移动到：";
        label.percentHeight = 100;
        auto = new AutoComplete();
        auto.percentWidth = 100;
        auto.labelFunction = searchLabelFunction;
        auto.dropDownLabelFunction = listLabelFunction;
        auto.matchType = "anyPart";
        auto.focusEnabled = true;
        hbox1.addElement(label);
        hbox1.addElement(auto);
        auto.graphics.lineStyle(1, 0x696969);
        auto.graphics.drawRect(0, 0, 229, 20);


        var hbox2:HBox = new HBox();
        hbox2.percentWidth = 100;
        hbox2.setStyle("paddingLeft", 5);
        hbox2.setStyle("paddingRight", 5);
        hbox2.setStyle("paddingBottom", 5);
        hbox2.setStyle("paddingTop", 5);
        hbox2.setStyle("horizontalAlign", "right");
        ok = new Button();
        ok.label = "确定";
        ok.addEventListener(MouseEvent.CLICK, onOK);
        hbox2.addElement(ok);

        window = new TitleWindow();
        window.layout = new VerticalLayout();
        window.addEventListener(CloseEvent.CLOSE, remove);
        window.title = NAME;
        window.width = 303;
        window.height = 140;
        window.addElement(hbox);
        window.addElement(hbox1);
        window.addElement(hbox2);

        replace = new ReplaceResource();
        replace.addEventListener("progress", onReplace);
        replace.addEventListener("complete", onReplace);

        return Boolean(resTree);
    }

    private static function onOK(event:MouseEvent):void {
        var from:String = getResourceNativePath(selectedResource);
        fileFrom = new File(from);
        if (fileFrom.exists) {
            var to:String;
            if (auto.selectedItem) {
                to = getDirNativePath(auto.selectedItem as XML) + "/" + getResourceFileName(selectedResource, input.text);
            } else {
                to = fileFrom.parent.nativePath + "/" + getResourceFileName(selectedResource, input.text);
            }

            fileTo = new File(to);
            var cmd:String = "move /Y " + fileFrom.nativePath + " " + fileTo.nativePath;
            if (fileTo.exists) {
                Alert.show("目标目录已经存在同名文件，是否覆盖？", NAME, Alert.YES | Alert.NO, null, function (event:Object) {
                    if (event.detail == Alert.YES) {
                        exeCmds([cmd], onMoveComplete, onMoveProgress, onMoveError);
                    }
                });
            } else {
                exeCmds([cmd], onMoveComplete, onMoveProgress, onMoveError);
            }
        } else {
            Alert.show("资源文件不存在。注意：不支持移动swf里的资源哦！", NAME);
        }

        remove();
    }

    private static function onReplace(event:Event):void {
        switch (event.type) {
            case "progress":
                if (progress) {
                    progress.text = "替换引用：" + "【" + (replace.index + 1) + "/" + replace.files.length + "】";
                }
                break;
            case "complete":
                closeWaiting();
                remove();
                alert(NAME, "操作完成。现在刷新资源？", Alert.YES | Alert.NO, onConfirmRefresh);
                break;
        }
    }

    private static function onConfirmRefresh(event:*):void {
        if (event.detail == Alert.YES) {
            //刷新当前页面
            var xml:XML = new XML(readTxt(viewPath));
            changeViewXml(xml, true);
            //刷新资源
            var e:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.F5);
            builderStage.dispatchEvent(e);
            //刷新页面
            var e:KeyboardEvent = new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, false, 0, Keyboard.F6);
            builderStage.dispatchEvent(e);

            //侦听资源解析完成的事件
            resTree.addEventListener(CollectionEvent.COLLECTION_CHANGE, onResourceRefreshed);
        }
    }

    /**
     * 资源解析完成
     * @param event
     */
    private static function onResourceRefreshed(event:CollectionEvent):void {
        if (fileTo) {
            var resource:String = getResourceFromPath(fileTo.nativePath);
            var item:XML = XML(resTree.dataProvider.source..item.(@asset == resource));
            Util.expandParents(resTree, item);
            resTree.validateNow();
            resTree.selectedItem = item;
            resTree.scrollToIndex(resTree.selectedIndex);
        }
    }

    private static function handleKey(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.ESCAPE) {
            remove();
        }
    }

    private static function remove(event:Event = null):void {
        resTree.removeEventListener(CollectionEvent.COLLECTION_CHANGE, onResourceRefreshed);
        builderStage.removeEventListener(KeyboardEvent.KEY_UP, handleKey);
        PopUpManager.removePopUp(window);
        auto.clear();
    }

    private static function onMoveProgress(e:ProgressEvent):void {
        log(e.toString());
    }

    private static function onMoveError(...args):void {
        alert(NAME, "exeCmds时出错");
        log(args.toString());
    }

    private static function onMoveComplete():void {
        if (fileFrom && fileTo) {
            showWaiting(NAME, "替换引用");
            var group:* = finder.search("MessagePanel", DisplayObjectContainer(builderMain.root));
            if (group) {
                progress = group.msgLbl;
            }

            var fromRes:String = getResourceFromPath(fileFrom.nativePath);
            var toRes:String = getResourceFromPath(fileTo.nativePath);
            log("移动资源：" + fromRes + " -> " + toRes);
            replace.exec(fromRes, toRes, getFileList(workPath + "\\morn\\pages"));
        } else {
            remove();
        }
    }

    private static function listLabelFunction(item:XML):String {
        var label:String = item.@name;
        while (item = item.parent()) {
            if (String(item.@name)) {
                label = item.@name + "." + label;
            }
        }
        return label;
    }

    private static function searchLabelFunction(item:XML):String {
        var label:String = item.@name;
        while (item = item.parent()) {
            if (String(item.@name)) {
                label = item.@name + "." + label;
            }
        }

        return label;
    }

    private static function get selectedResource():String {
        var resource:String;
        if (selectedXmls && selectedXmls.length > 0) {
            resource = Util.getResource(selectedXmls[0].xml);
        } else if (resTree.selectedItem) {
            resource = resTree.selectedItem.@asset;
        }
        return resource;
    }

}
}
