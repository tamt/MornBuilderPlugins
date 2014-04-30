/**
 * User: tamt
 * Date: 2014/4/30
 * Time: 18:48
 */
package util {
import flash.display.Sprite;

import morn.editor.PluginBase;

import mx.preloaders.IPreloaderDisplay;

public class CustomPreloader extends Sprite implements IPreloaderDisplay {
    public function CustomPreloader() {
        PluginBase.log("[CustomPreloader.CustomPreloader]");
    }

    public function get backgroundAlpha():Number {
        return 0;
    }

    public function set backgroundAlpha(value:Number):void {
    }

    public function get backgroundColor():uint {
        return 0;
    }

    public function set backgroundColor(value:uint):void {
    }

    public function get backgroundImage():Object {
        return null;
    }

    public function set backgroundImage(value:Object):void {
    }

    public function get backgroundSize():String {
        return "";
    }

    public function set backgroundSize(value:String):void {
    }

    public function set preloader(obj:Sprite):void {
    }

    public function get stageHeight():Number {
        return 0;
    }

    public function set stageHeight(value:Number):void {
    }

    public function get stageWidth():Number {
        return 0;
    }

    public function set stageWidth(value:Number):void {
    }

    public function initialize():void {
    }
}
}
