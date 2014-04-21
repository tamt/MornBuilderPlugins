/**
 * User: tamt
 * Date: 14-3-31
 * Time: 上午9:15
 */
package {
import cn.itamt.utils.Inspector;
import cn.itamt.utils.inspector.core.liveinspect.LiveInspectView;
import cn.itamt.utils.inspector.core.propertyview.PropertiesView;
import cn.itamt.utils.inspector.core.structureview.StructureView;
import cn.itamt.utils.inspector.plugins.controlbar.ControlBar;

import flash.display.DisplayObjectContainer;

import morn.editor.Plugin;

import morn.editor.PluginBase;

public class tInspector extends Plugin {
    private static var inited:Boolean;
    private static var inspector:Inspector;

    public function tInspector() {
    }

    override public function start():void {
        if (initialize()) {
            inspector.toggleTurn();
        } else {
            alert("查找引用", "插件启动失败!");
        }
    }

    private static function initialize():Boolean {
        if (inited)return Boolean(inspector);
        inited = true;

        inspector = Inspector.getInstance();
        inspector.init(DisplayObjectContainer(builderMain.root));
        inspector.pluginManager.registerPlugin(new ControlBar());
        inspector.pluginManager.registerPlugin(new PropertiesView());
        inspector.pluginManager.registerPlugin(new StructureView());
        inspector.pluginManager.registerPlugin(new LiveInspectView());

        return Boolean(inspector);
    }


}
}
