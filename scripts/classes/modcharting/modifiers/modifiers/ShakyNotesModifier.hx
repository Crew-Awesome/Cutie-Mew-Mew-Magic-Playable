package modcharting.modifiers.modifiers;

import modcharting.modifiers.BaseModifier;

class ShakyNotesModifier extends BaseModifier {
	public function new() {
		super("ShakyNotes");
	}

    override private function initDefaults():Void {
        subValues.set("speed", 1.0);
    }

	override private function applyMod(result:ModResult, beat:Float, lane:Int):Void {
		result.x += FlxMath.fastSin(500)
			+ value * (Math.cos(Conductor.songPosition * 4 * 0.2)
				+ ((lane % manager.getKeyCount(strumLineIndex == -1 ? 0 : strumLineIndex)) * 0.2) - 0.002) * (Math.sin(100
				- (120 * getSubValue('speed') * 0.4)));

		result.y += FlxMath.fastSin(500)
			+ value * (Math.cos(Conductor.songPosition * 8 * 0.2)
				+ ((lane % manager.getKeyCount(strumLineIndex == -1 ? 0 : strstrumLineIndexumLine)) * 0.2) - 0.002) * (Math.sin(100
				- (120 * getSubValue('speed') * 0.4)));
	}
}
