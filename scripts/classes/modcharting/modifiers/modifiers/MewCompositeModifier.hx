package modcharting.modifiers.modifiers;

import core.audio.Conductor;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import modcharting.modifiers.BaseModifier;

class MewCompositeModifier extends BaseModifier
{
    public var traverseX:Float = 0;
    public var pulseY:Float = 0;
    public var sineActive:Bool = false;
    public var sineStartTime:Float = 0;
    public var sineFade:Float = 1;
    public var sineAmount:Float = 30;

    public var dizzyActive:Bool = false;
    public var dizzyStartTime:Float = 0;
    public var dizzyEndTime:Float = 0;

    public var hopX:Array<Float> = [0, 0, 0, 0];
    public var hopY:Array<Float> = [0, 0, 0, 0];
    public var drumX:Array<Float> = [0, 0, 0, 0];
    public var drumY:Array<Float> = [0, 0, 0, 0];
    public var jumpY:Array<Float> = [0, 0, 0, 0];
    public var jumpAngle:Array<Float> = [0, 0, 0, 0];
    public var pressY:Array<Float> = [0, 0, 0, 0];
    public var ambientX:Array<Float> = [0, 0, 0, 0];
    public var ambientY:Array<Float> = [0, 0, 0, 0];
    public var ambientAngle:Array<Float> = [0, 0, 0, 0];

    public function new()
    {
        super("MewComposite");
    }

    override public function isActive():Bool
    {
        return value != 0;
    }

    override private function applyMod(result:ModResult, beat:Float, lane:Int):Void
    {
        if (lane < 0 || lane >= 4)
            return;

        var y:Float = pulseY;
        var x:Float = traverseX;
        var angle:Float = 0;

        if (sineActive)
        {
            final sineTime:Float = Conductor.songPosition - sineStartTime;
            final sineBase:Float = sineTime / (Conductor.crochet * 2) * Math.PI * 2;

            x = -Math.cos(sineTime / (Conductor.crochet * 4) * Math.PI * 2) * 190 * sineFade;
            y = Math.sin(sineBase + lane * 0.85) * sineAmount * sineFade;
        }

        if (dizzyActive)
        {
            final progress:Float = FlxMath.bound((Conductor.songPosition - dizzyStartTime) / (dizzyEndTime - dizzyStartTime), 0, 1);
            final fadeOut:Float = FlxMath.bound((dizzyEndTime - Conductor.songPosition) / (Conductor.crochet * 2), 0, 1);
            final dizzyStrength:Float = FlxEase.sineInOut(progress) * FlxEase.sineInOut(fadeOut);
            final dizzyBase:Float = (Conductor.songPosition - dizzyStartTime) / (Conductor.crochet * 1.8) * Math.PI * 2;

            x += Math.sin(dizzyBase + lane * 1.7) * 20 * dizzyStrength;
            y += Math.cos(dizzyBase + lane * 1.3) * 12 * dizzyStrength;
            angle += Math.sin(dizzyBase + lane * 0.8) * 3 * dizzyStrength;
        }

        result.x += (x + safe(hopX, lane) + safe(drumX, lane) + safe(ambientX, lane)) * value;
        result.y += (y + safe(hopY, lane) + safe(drumY, lane) + safe(jumpY, lane) + safe(pressY, lane) + safe(ambientY, lane)) * value;
        result.angle += (angle + safe(jumpAngle, lane) + safe(ambientAngle, lane)) * value;
    }

    function safe(values:Array<Float>, lane:Int):Float
    {
        return values == null || lane < 0 || lane >= values.length ? 0 : values[lane];
    }
}
