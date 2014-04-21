/**
 * User: tamt
 * Date: 14-3-20
 * Time: 下午1:57
 */
package refRes{
import flash.events.Event;
import flash.events.EventDispatcher;
import flash.utils.getTimer;

import morn.editor.PluginBase;

public class ReplaceResource extends EventDispatcher {
    public var from:String;
    public var to:String;
    public var files:Array;
    public var index:uint;
    public var references:Array;

    public function ReplaceResource() {
    }

    public function exec(from:String, to:String, files:Array):void {
        this.from = from;
        this.to = to;
        this.files = files;
        this.references = [];
        this.index = 0;

        PluginBase.builderMain.addEventListener(Event.ENTER_FRAME, next);
    }

    private function next(event:Event = null):void {
        var time:int = 1000 / PluginBase.builderStage.frameRate;
        var start:int = getTimer();

        dispatchEvent(new Event("progress"));

        while ((getTimer() - start) < time) {
            if (index >= files.length) {
                PluginBase.builderMain.removeEventListener(Event.ENTER_FRAME, next);
                dispatchEvent(new Event("complete"));
                break;
            }

            var file:String = files[index][1];
            var content:String = PluginBase.readTxt(file);
            var regExp:RegExp = new RegExp('"' + this.from + '"', "ig");
            if (regExp.test(content)) {
                PluginBase.writeTxt(file, content.replace(regExp, '"' + to + '"'));
            }

            index++;
        }
    }

}
}
