package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class TipsyZModifer extends BaseModifier {
	public function new() {
		super("TipsyZ");
	}

	override function initDefaults() {
		subValues.set('speed', 1.0);
		subValues.set('desync', 2.0);
		subValues.set('offset', 0.0);
		subValues.set('timertype', 0.0);
		subValues.set('useAlt', 0.0);
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		result.z += tipsyMath(value, beat, lane);
	}

	function tipsyMath(currentValue:Float, beat:Float, lane:Int):Float {
		var time:Float = (getSubValue('timertype') >= 0.5 ? beat : Conductor.songPosition * 0.001 * 1.2);
		time *= getSubValue('speed');
		time += getSubValue('offset');

		var usesAlt:Bool = (getSubValue("useAlt") >= 0.5);
		var returnValue:Float = 0.0;

		if (usesAlt)
			returnValue = currentValue * (FlxMath.fastCos((time +
				((lane) % manager.getKeyCount(strumLineIndex == -1 ? 0 : strumLineIndex)) * getSubValue('desync')) * (5) * 1 * 0.2) * 112 * 0.5);
		else
			returnValue = currentValue * (FlxMath.fastSin((time +
				((lane) % manager.getKeyCount(strumLineIndex == -1 ? 0 : strumLineIndex)) * getSubValue('desync')) * (5) * 1 * 0.2) * 112 * 0.5);

		return returnValue;
	}
}
