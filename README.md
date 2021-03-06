致敬
====
[Morn UI/Builder](https://github.com/yungzhu/morn)极大提高了Flash游戏开发工作的效率，向[yungzhu](https://github.com/yungzhu)致敬！

MornBuilderPlugins
==================
[MornBuilder](https://github.com/yungzhu/morn)的插件，相信他们可以大幅提升你在MornBuilder上的工作效率。这些插件主要是模仿[IntelliJ IDEA](https://www.jetbrains.com/idea/)的功能，快捷键的安排上也参照IDEA。目前实现功能包括：

- 页面尺寸自动匹配页面内容(AutoSizeView)
- 按Del键可删除资源(DeleteResource)
- 查找资源引用(FindReference)
- 查找资源(FindResource)
- 打开页面(OpenPage)
- 移动、重命名资源(RefactorResource)
- 定位页面和资源(ScrollFromSource)
- 预览页面在iPhone中的尺寸(iPhonePreview)
- 显示上一次打开的页面(RememberOpenedPages)
- 生成atlas贴图资源(AtlasGenerator)

兼容MornBuilder版本
==================
在MornBuilder 2.4.1027上测试可用。

安装方法
=======
把bin目录下的文件复制到MornBuilder的plugins目录下。

配置自启动
==========
你可以在每个插件的config.xml中添加 __autostart__ 配置来决定是否在MornBuilder开启后自启动。

    <name>Del键可删除资源</name>
    <file>/../AllInOne.swf</file>
    <start>DeleteResource</start>
    <!--MornBuilder开启后自启动-->
    <autostart>true</autostart>

功能与说明
=======

##AutoSizeView

    快捷键 Ctrl+Shift+F

设置页面的尺寸以匹配页面内容（相当于Fireworks里的“符合画布”）

##DeleteResource

    快捷键 Del

在资源面板上选中一个资源，按Del键会删除这个资源文件。注意不能删除swf文件中的资源。

##FindReference

    快捷键 Alt+F7

找出一个资源在哪些页面被使用。还包含了“查找没用的资源”功能：搜索没有在页面中使用过的资源，并且可以通过按Del直接删除资源。不过，需要额外注意： **搜索只是匹配资源在页面xml文件中的情况，并不考虑AS3代码文件中使用资源的情况。**

##FindResource

    快捷键 Ctrl+Shift+I

输入关键字、回车，会在资源页面中定位选中匹配的资源。

##OpenPage

    快捷键 Ctrl+Shift+N

其实MornBuilder本身提供快速打开（Ctrl+T）功能，但不支持方向键选中。OpenPage主要是补齐按键支持。输入关键字后按键：

    1. Enter         在页面面板中定位选中匹配的页面
    2. Shift+Enter   在页面面板中定位选中匹配的页面，打开匹配的页面

##RefactorResource

    快捷键 Shift+F6

把资源文件移动到别的目录，或者重命名资源文件。操作完成后，会搜索资源的引用并替换成新的资源。

##ScrollFromSource

    快捷键 Alt+F1

在资源面板、页面面板中定位和选中当前资源、页面。
在资源面板上，还有额外功能按钮：复制资源名称，和复制资源文件路径。

##ShowPathOnWindowTitle

在MornBuilder的窗口标题栏上显示当前页面的路径，仅此而已。

##iPhonePreview

    快捷键 Alt+V

预览页面在iPhone(4/4s/5/5c/5s)上的尺寸，帮助我们设计适合玩家在iphone上操作的界面尺寸。原理很简单：根据显示器PPI与iPhone屏幕PPI比例缩放页面。
你需要在iPhonePreview/config.xml中设置显示器的尺寸（英寸），默认是21.5。
当然你也可以把iPhoneScreenPPI修改成其它手机屏幕PPI。

##RememberOpenedPages

在MornBuilder启动后，显示上一次打开的页面。

##AtlasGenerator

    快捷键 Ctrl+F12

__请先安装[python](https://www.python.org/downloads/windows/)。然后在AtlasGenerator/config.xml配置python的路径。__

把图片资源生成atlas贴图（.png），以及贴图信息（.morn）。
每个MornBuilder资源目录会生成为一张atlas图，例如：

![生成的atlas图片](/doc/Atlas.jpg)

贴图信息存储在对应的.morn文件中，格式为:

    资源名;x1;y1;x2;y2;旋转
例如：

![生成的atlas图片](/doc/AtlasInfo.jpg)

生成的atlas存放在MornBuilder导出资源（swf）的目录中。

你可以对生成器进行一些简单的配置，如下图：

![atlas生成器设置](/doc/AtlasGenerator.jpg)

配置说明请参照[python-texture-atlas-generator](http://gc.codehum.com/p/python-texture-atlas-generator/)。

###在MornUI中使用导出的atlas图片

AtlasGenerator会把原始图像的信息存储在文件中，文件格式可以是json、csv、xml、morn，其中morn保存了每个资源的名称（例如：`png.login.btn`），而其它三种保存了资源的完整路径。可以很容易根据这些信息从atlas中再取回原始图像。<br>
得益于MornUI的设计，只要重载`App.asset`的`getBitmapData`、`hasClass`方法就可以修改MornUI使用位图资源的方式。比如：

    override public function hasClass(name:String):Boolean {
        if (texture[name] || atlas[name]) {
            return true;
        }
        return super.hasClass(name);
    }

    override public function getBitmapData(name:String, cache:Boolean = true):BitmapData {
        if (!texture.hasOwnProperty(name) || !cache) {
            if (atlas[name]) {
                var info:AtlasTextureInfo = atlas[name];
                var bmd:BitmapData = new BitmapData(
                        info.rotated ? info.rect.height : info.rect.width,
                        info.rotated ? info.rect.width : info.rect.height,
                        true, 0);
                var mtx:Matrix = new Matrix();
                if (info.rotated) mtx.rotate(Math.PI / 2);
                var tl:Point = mtx.transformPoint(info.rect.topLeft);
                var br:Point = mtx.transformPoint(info.rect.bottomRight);
                rect.top = Math.min(tl.y, br.y);
                rect.left = Math.min(tl.x, br.x);
                rect.right = Math.max(tl.x, br.x);
                rect.bottom = Math.max(tl.y, br.y);
                mtx.translate(-rect.x, -rect.y);
                bmd.draw(info.source, mtx);

                if (!cache)return bmd;
                if (!texture.hasOwnProperty(name))texture[name] = bmd;
            }
        }
        if (texture[name])return texture[name];
        return super.getBitmapData(name, cache);
    }


