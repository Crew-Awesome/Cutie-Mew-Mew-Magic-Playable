package;

import flixel.util.FlxStringUtil;

import openfl.filters.DropShadowFilter;
import openfl.text.TextFormat;
import openfl.text.TextField;

import cpp.vm.Gc;

class FPSCounter extends scripting.haxe.ScriptedGameObject
{
    var label:TextField;

    public function new()
    {
        super();

        x = y = 15;

        label = new TextField();
        label.defaultTextFormat = new TextFormat(Paths.font('deltarune.ttf'), 17, FlxColor.WHITE);
        label.filters = [new DropShadowFilter(0, 0, FlxColor.BLACK, 10)];

        add(label);
    }

    var fps:Float = 0;

    var memory:Float = 0;
    var memoryString:String = '';

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (Controls.FPS_COUNTER)
            visible = !visible;

        if (!visible)
            return;

        fps = CoolUtil.fpsLerp(fps, elapsed <= 0 ? 0 : 1 / elapsed, 0.1);

        final curMemory:Null<Float> = Gc.memInfo64(Gc.MEM_INFO_USAGE);

        if (memory != curMemory && curMemory != null)
        {
            memory = curMemory;

            memoryString = FlxStringUtil.formatBytes(memory);
        }

        label.text = 'FPS: ' + Math.floor(fps) + '\nGC: ' + memoryString;
    }
}