/**
 * User: tamt
 * Date: 14-3-20
 * Time: 上午9:48
 */
package findRef {
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.ProgressEvent;
import flash.filesystem.File;
import flash.ui.Keyboard;

import morn.editor.Plugin;
import morn.editor.PluginBase;

import mx.collections.ArrayCollection;
import mx.containers.HBox;
import mx.containers.TitleWindow;
import mx.controls.Button;
import mx.controls.List;
import mx.core.ClassFactory;
import mx.core.IFactory;

public class FindResultView extends EventDispatcher {
    public static const FIND_USELESS:String = "FIND_USELESS";
    public static const CLOSE:String = "CLOSE";
    public static const SELECT:String = "SELECT";

    public var resource:String;
    public var list:List
    public var panel:TitleWindow;
    private var defaultItemRenderer:IFactory;

    public function FindResultView() {

        panel = new TitleWindow();
        panel.title = "资源使用情况";
        panel.layout = "vertical";

        list = new List();
        list.percentWidth = 100;
        list.percentHeight = 100;
        list.doubleClickEnabled = true;
        list.addEventListener("itemDoubleClick", onSelect);
        defaultItemRenderer = list.itemRenderer;

        panel.addElement(list);
        panel.width = 300;
        panel.height = 330;

        panel.setStyle("paddingLeft", 10);
        panel.setStyle("paddingRight", 10);
        panel.setStyle("paddingBottom", 10);
        panel.setStyle("paddingTop", 10);

        var hbox:HBox = new HBox();
        hbox.percentWidth = 100;
        hbox.setStyle("horizontalAlign", "right");

        var useless:Button = new Button();
        useless.label = "查找没用的资源";
        useless.addEventListener(MouseEvent.CLICK, findUseless);
        hbox.addElement(useless);
        var btn:Button = new Button();
        btn.label = "关闭";
        btn.addEventListener(MouseEvent.CLICK, close);
        hbox.addElement(btn);

        panel.addElement(hbox);

        panel.addEventListener(Event.ADDED_TO_STAGE, onAdded);
        panel.addEventListener(Event.REMOVED_FROM_STAGE, onRemoved);
    }

    private function onDelete(event:KeyboardEvent):void {
        if (event.keyCode == Keyboard.DELETE) {
            var focus:* = PluginBase.builderMain['focusManager'].getFocus();
            if (panel.contains(focus) || panel == focus) {
                if (list.selectedItem && !this.resource) {
                    var path:String = Plugin.getResourceNativePath(String(list.selectedItem));
                    var file:File = new File(path);
                    if (file.exists) {
                        var cmd:String = "del " + path;
                        PluginBase.exeCmds([cmd], onDeleteComplete, onDeleteProgress, onDeleteError);
                    } else {
                        PluginBase.alert("错误", "文件不存在。注意不支持swf元件的删除");
                    }
                }
            }
        }
    }

    private function onDeleteProgress(e:ProgressEvent):void {
    }

    private function onDeleteError(...args):void {
    }

    private function onDeleteComplete():void {
        if (list.selectedItem && !this.resource) {
            var t:int = list.selectedIndex;
            (list.dataProvider as ArrayCollection).removeItemAt(t);
            list.validateNow();
            if (t > 0 && t < (list.dataProvider as ArrayCollection).length) {
                list.selectedIndex = t;
            } else {
                list.selectedIndex = 0;
            }
        }
    }

    private function findUseless(event:MouseEvent):void {
        dispatchEvent(new Event(FIND_USELESS))
    }

    private function onSelect(event:Event):void {
        dispatchEvent(new Event(SELECT))
    }

    private function referenceLabelFunc(data:Array):String {
        return String(data[1]).slice((PluginBase.workPath + "\\morn\\pages").length + 1);
    }

    private function uselessResLabelFunc(data:String):String {
        return data;
    }

    public function setData(resource:String, arr:Array):void {
        this.resource = resource;
        if (resource) {
            list.labelFunction = referenceLabelFunc;
            list.itemRenderer = defaultItemRenderer;
        } else {
            list.labelFunction = uselessResLabelFunc;
            list.itemRenderer = new ClassFactory(UselessItemRenderer);
        }

        list.dataProvider = arr;
        list.validateNow();
    }

    private function close(event:MouseEvent = null):void {
        dispatchEvent(new Event(CLOSE));
    }

    override public function dispatchEvent(event:Event):Boolean {
        if (hasEventListener(event.type)) {
            return super.dispatchEvent(event);
        } else {
            return false;
        }
    }

    private function onAdded(event:Event):void {
        PluginBase.builderStage.addEventListener(KeyboardEvent.KEY_UP, onDelete);
    }

    private function onRemoved(event:Event):void {
        PluginBase.builderStage.removeEventListener(KeyboardEvent.KEY_UP, onDelete);
    }
}
}
