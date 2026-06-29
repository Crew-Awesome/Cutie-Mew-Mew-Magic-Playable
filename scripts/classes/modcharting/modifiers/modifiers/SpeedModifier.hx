package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class SpeedModifier extends BaseModifier {
	public function new() {
		super("Speed");
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		if (value == 0)
			return;
		// trace('SpeedModifier: value=$value baseSpeed=${getSubValue("baseSpeed")} result=${getSubValue("baseSpeed") * value}');
		result.speed = manager.getStrumSpeed(lane) * value;
	}
}
