package modcharting.modifiers.modifiers;

import flixel.math.FlxMath;

import modcharting.modifiers.BaseModifier;

class BeatXModifier extends BaseModifier {
	public function new() {
		super("BeatX");
	}

	override private function initDefaults():Void {
		subValues.set("speed", 1.0);
		subValues.set("mult", 1.0);
		subValues.set("offset", 0.0);
		subValues.set("alternate", 1.0);
		subValues.set("fAccelTime", 0.2);
		subValues.set("fTotalTime", 0.5);
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		result.x += beatMath(value, beat);
	}

	function beatMath(currentValue:Float, beat:Float):Float {
		var speed:Float = getSubValue("speed");
		var mult:Float = getSubValue("mult");
		var offset:Float = getSubValue("offset");
		var alternate:Bool = (getSubValue("alternate") >= 0.5);

		var mathToUse:Float = 0.0;

		var fAccelTime = getSubValue("fAccelTime");
		var fTotalTime = getSubValue("fTotalTime");

		var time = (beat + offset) * speed;
		var posMult = mult * 2;
		var fBeat = time + fAccelTime;

		var bEvenBeat = (Math.floor(fBeat) % 2) != 0;

		if (fBeat < 0)
			return 0;

		fBeat -= Math.floor(fBeat);
		fBeat += 1;
		fBeat -= Math.floor(fBeat);

		if (fBeat >= fTotalTime)
			return 0;

		var fAmount:Float;
		if (fBeat < fAccelTime) {
			fAmount = FlxMath.remapToRange(fBeat, 0.0, fAccelTime, 0.0, 1.0);
			fAmount *= fAmount;
		} else {
			fAmount = FlxMath.remapToRange(fBeat, fAccelTime, fTotalTime, 1.0, 0.0);
			fAmount = 1 - (1 - fAmount) * (1 - fAmount);
		}

		if (bEvenBeat && alternate)
			fAmount *= -1;

		mathToUse = FlxMath.fastSin((0.01 * posMult) + (Math.PI / 2.0));

		var fShift = 20.0 * fAmount * mathToUse;
		return fShift * currentValue;
	}
}
