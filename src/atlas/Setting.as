/**
 * Created by 小川 on 2014/5/1.
 */
package atlas {

/**
 * http://gc.codehum.com/p/python-texture-atlas-generator/
 */
public class Setting {

    public var help:Boolean;
    public var verbose:Boolean;

    [Bindable]
    public var texture:uint = 1024;
    [Bindable]
    public var group_by_folder:Boolean = true;
    [Bindable]
    public var flat:Boolean = true;
    [Bindable]
    public var sort:int = -1;
    [Bindable]
    public var padding:uint;
    [Bindable]
    public var fill:Boolean;
    [Bindable]
    public var crop:Boolean = true;
    [Bindable]
    public var power_of_2:Boolean;
    [Bindable]
    public var optimize:Boolean;
    [Bindable]
    public var info:String = "csv";
    [Bindable]
    public var no_rotation:Boolean;

}
}