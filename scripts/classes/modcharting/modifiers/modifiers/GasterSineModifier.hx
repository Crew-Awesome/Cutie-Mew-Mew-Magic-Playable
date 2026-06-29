package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class GasterSineModifier extends BaseModifier
{
    public function new()
    {
        super("GasterSine");
    }

    override function initDefaults():Void
    {
        subValues.set("speed", 0.58);
        subValues.set("phase", 0.8);
        subValues.set("amount", 18);
    }

    override private function applyMod(result:ModResult, beat:Float, lane:Int):Void
    {
        result.y += Math.sin(beat * getSubValue("speed") + lane * getSubValue("phase")) * getSubValue("amount") * value;
    }
}
