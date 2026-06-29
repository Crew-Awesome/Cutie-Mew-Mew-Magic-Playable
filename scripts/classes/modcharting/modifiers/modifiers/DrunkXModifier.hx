package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class DrunkXModifier extends BaseModifier {
	public function new() {
		super("DrunkX");
	}

	override private function initDefaults():Void {
		subValues.set("speed", 1.0);
		subValues.set("offset", 0.2);
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		var speed = getSubValue("speed");
		var offset = getSubValue("offset");

		result.x += value * Math.sin((beat * speed) + (lane * offset)) * 30;
	}
}