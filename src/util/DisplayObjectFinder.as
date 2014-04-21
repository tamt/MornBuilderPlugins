package util {
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;

/**
 * 显示对象查找器, 从显示列表中查找符合条件的显示对象
 */
public class DisplayObjectFinder {
    private var i:int;
    private var pattern:String;
    private var patterns:Array;
    private var scope:DisplayObjectContainer;
    private var findIt:DisplayObject;

    public function DisplayObjectFinder() {
    }

    /**
     * 销毁对象
     */
    public function destroy():void {
        this.reset();
    }

    private function reset():void {
        i = 0;
        pattern = null;
        patterns = null;
        scope = null;
        findIt = null;
    }

    /**
     * 根据路径查找, 比如: Main..BottomPanel..winControl.Intensify_btn
     * @param path
     * @param from
     * @return 查找到的显示对象, 如果没有找到则为null
     */
    public function search(path:String, from:DisplayObjectContainer):DisplayObject {
        this.reset();

        scope = from;
        patterns = path.split(".");

        for (i = 0; i < patterns.length; i++) {
            pattern = patterns[i];
            if (!pattern)continue;
            if (!scope)break;
            eachDisplayObject(scope, check);
            if (findIt)break;
        }

        return findIt;
    }

    private function check(dp:DisplayObject):Boolean {
        if ((dp.name == pattern) || (Object(dp).constructor == ("[class " + pattern + "]")) || (String(dp) == ("[object " + pattern + "]"))) {
            if (i == (patterns.length - 1)) {
                findIt = dp;
            }
            scope = dp as DisplayObjectContainer;
            return true;
        }

        return false;
    }


    /**
     * 遍历某个容器下的每个显示对象
     * @param container     要遍历的容器
     * @param fun           针对第个显示对象要执行的方法, 该方法需要返回一个布尔值， 如果为true， 中断遍历。
     */
    private function eachDisplayObject(container:DisplayObjectContainer, fun:Function):Boolean {
        var willBreak:Boolean;
        var num:int = container.numChildren;
        for (var i:int = 0; i < num; i++) {
            if (container.getChildAt(i) is DisplayObjectContainer) {
                willBreak = eachDisplayObject(container.getChildAt(i) as DisplayObjectContainer, fun);
                if (willBreak) {
                    return willBreak;
                }
            }
            willBreak = fun.call(null, container.getChildAt(i));
        }

        return willBreak;
    }
}
}