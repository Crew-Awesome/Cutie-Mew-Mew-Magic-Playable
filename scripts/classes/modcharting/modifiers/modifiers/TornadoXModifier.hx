package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class TornadoXModifier extends BaseModifier {
	public function new() {
		super("TornadoX");
	}

	override function initDefaults() {
		subValues.set('speed', 1.0);
		subValues.set('offset', 0.0);
	
	}

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		result.x += tornadoMath(lane, beat);
		trace('TornadoXModifier: result.x=${result.x}, tornadoMath=${tornadoMath(lane, beat)}');
	}

	public function tornadoMath(lane:Int, beat:Float) {
		var offset = subValues.get('offset');
		var columnPhaseShift = Math.PI / 3;
		var phaseShift = beat * subValues.get('speed') * 10.0; // cambiá 2.0 al gusto
		var returnToZeroOffset = (-Math.cos(-columnPhaseShift) + 1) / 2 * 3;
		var offset = (-Math.cos((phaseShift - columnPhaseShift)) + 1) / 2 * 30 - returnToZeroOffset;

		return offset;
	}
}
