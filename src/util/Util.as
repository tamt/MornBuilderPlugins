package util {
import mx.controls.Tree;

public class Util {

    public static const pagePanelPath:String = "Main.WindowedApplicationSkin..PagePanel";
    public static const resPanelPath:String = "Main.WindowedApplicationSkin..ResPanel";
    public static const pageTreePath:String = "Main.WindowedApplicationSkin..PagePanel.PanelSkin..FileSystemTree";
    public static const resTreePath:String = "Main.WindowedApplicationSkin..ResPanel.PanelSkin..Tree";
    public static const uiMgrPath:String = "Main.WindowedApplicationSkin..UIManager";

    static public function expandParents(resTree:Tree, node:XML):void {
        if (node && !resTree.isItemOpen(node)) {
            resTree.expandItem(node, true);
            expandParents(resTree, node.parent());
        }
    }

    static public function getResource(node:XML):String {
        var result:*;
        for each (var attr:XML in node.attributes()) {
            if (result = /(png|jpg|jpeg)\.(\w+\.)*[^\s"]+/ig.exec(attr.toString())) {
                return result[0];
            } else if (result = /frameclip_(\w+)*[^\s"]+/ig.exec(attr.toString())) {
                return result[0];
            }
        }

        return null;
    }
}
}