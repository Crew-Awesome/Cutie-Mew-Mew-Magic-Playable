package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class DrunkModifier extends BaseModifier {
	public function new() {
		super("Drunk");
	}

	override private function initDefaults():Void {
		subValues.set("speed", 1.0);
		subValues.set("offset", 0.2);
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		var speed = getSubValue("speed");
		var offset = getSubValue("offset");

		result.x += value * Math.sin((beat * speed) + (lane * offset)) * 30;
		result.y += value * Math.cos((beat * speed) + (lane * offset)) * 15;
		result.z += value * Math.cos((beat * speed) + (lane * offset)) * 15;
		result.angle += value * Math.sin((beat * speed) + (lane * offset)) * 3;
	}
}
