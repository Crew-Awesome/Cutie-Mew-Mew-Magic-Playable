package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class ZModifier extends BaseModifier {
	public function new() {
		super("Z");
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		result.z += value;
	}
}
