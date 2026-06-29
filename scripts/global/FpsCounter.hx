import openfl.system.System;
import flixel.text.FlxText.FlxTextBorderStyle;

var customFpsText:FlxText;
var customFpsVisible:Bool = Save.custom.data.cutieMewMewMagicFpsVisible ??= true;
var smoothedFps:Float = 0;

function formatBytes(bytes:Float):String
{
    if (bytes >= 1000000000)
        return CoolUtil.floorDecimal(bytes / 1000000000, 2) + ' GB';

    if (bytes >= 1000000)
        return CoolUtil.floorDecimal(bytes / 1000000, 1) + ' MB';

    if (bytes >= 1000)
        return CoolUtil.floorDecimal(bytes / 1000, 1) + ' KB';

    return Std.string(Math.floor(bytes)) + ' B';
}

function hideEngineFps()
{
    final tray:Dynamic = Reflect.field(FlxG.game, 'debugTray');

    if (tray != null)
    {
        tray.visible = false;
        tray.alpha = 0;
        tray.x = -10000;
        tray.y = -10000;

        if (tray.parent != null)
            tray.parent.removeChild(tray);
    }

    if (FlxG.stage != null)
    {
        var index:Int = FlxG.stage.numChildren - 1;

        while (index >= 0)
        {
            final child:Dynamic = FlxG.stage.getChildAt(index);
            final className:String = Std.string(Type.getClassName(Type.getClass(child)));

            if (className.indexOf('DebugTray') >= 0)
            {
                child.visible = false;
                child.alpha = 0;
                FlxG.stage.removeChild(child);
            }

            index--;
        }
    }
}

function onCreate()
{
    hideEngineFps();
}

function postCreate()
{
    if (game != FlxG.state)
        return;

    hideEngineFps();

    customFpsText = new FlxText(10, 8, 300, '', 18);
    customFpsText.font = Paths.font('deltarune.ttf');
    customFpsText.color = FlxColor.WHITE;
    customFpsText.borderStyle = FlxTextBorderStyle.OUTLINE;
    customFpsText.borderColor = FlxColor.BLACK;
    customFpsText.borderSize = 1.5;
    customFpsText.scrollFactor.set();
    customFpsText.cameras = [camHUD];
    customFpsText.visible = customFpsVisible;
    add(customFpsText);
}

function postUpdate(elapsed:Float)
{
    hideEngineFps();

    if (customFpsText == null)
        return;

    if (Controls.FPS_COUNTER)
    {
        customFpsVisible = !customFpsVisible;
        Save.custom.data.cutieMewMewMagicFpsVisible = customFpsVisible;
        Save.saveCustom();
    }

    smoothedFps = CoolUtil.fpsLerp(smoothedFps, FlxG.elapsed <= 0 ? 0 : 1 / FlxG.elapsed, 0.15);

    customFpsText.text = 'FPS ' + Math.floor(smoothedFps) + '\nRAM ' + formatBytes(System.totalMemory);
    customFpsText.visible = customFpsVisible;
}
