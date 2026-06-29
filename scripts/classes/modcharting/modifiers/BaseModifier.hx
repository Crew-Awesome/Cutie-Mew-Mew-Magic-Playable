package modcharting.modifiers;

/**
 * The result of a modifier calculation.
*/
typedef ModResult = {
	x:Float,
	y:Float,
	z:Float,
	angle:Float,
	scaleX:Float,
	scaleY:Float,
	alpha:Float,
	speed:Float
}

/**
 * Base class for all modifiers.
 */
class BaseModifier {

	/** 
	 * The name of the modifier. 
	*/
	public var name:String;

	/** 
	 * Current value of the modifier. 
	*/
	public var value:Float = 0;

	/** 
	 * Sub values of the modifier. 
	*/
	public var subValues:Map<String, Float>;

	/** 
	 * A reference to the modchart manager.
	*/
	public var manager:ModchartManager;

	public var strumLineIndex:Int = -1;
	public var strumIndex:Int = -1;

	/** 
	 * The last calculated beat for each lane. 
	*/
	public var lastCalculatedBeats:Array<Float> = [];

	/** 
	 * Whether the modifier is dirty and needs to be recalculated. 
	*/
	public var dirty:Bool = true;

	/** 
	 * Cached results for each lane. 
	*/
	public var cachedResults:Array<ModResult> = [];

	public function new(name:String) {
		this.name = name;
		this.subValues = new Map<String, Float>();
		initDefaults();
	}

	public function initDefaults():Void {}

	public function isActive():Bool {
		return value != 0;
	}

	/** 
	 * Calculate the modifier for the given beat and lane. 
	*/
	public function calculate(beat:Float, lane:Int):ModResult {
		if (cachedResults[lane] == null) {
			cachedResults[lane] = {
				x: 0,
				y: 0,
				z: 0,
				angle: 0,
				scaleX: 1,
				scaleY: 1,
				alpha: 1,
				speed: Math.NaN
			};
			lastCalculatedBeats[lane] = -999;
		}

		final result = cachedResults[lane];

		if (!isActive()) {
			result.x = 0;
			result.y = 0;
			result.z = 0;
			result.angle = 0;
			result.scaleX = 1;
			result.scaleY = 1;
			result.alpha = 1;
			result.speed = Math.NaN;
			return result;
		}

		if (!dirty && beat == lastCalculatedBeats[lane])
			return result;

		result.x = 0;
		result.y = 0;
		result.z = 0;
		result.angle = 0;
		result.scaleX = 1;
		result.scaleY = 1;
		result.alpha = 1;
		result.speed = Math.NaN;

		applyMod(result, beat, lane);

		lastCalculatedBeats[lane] = beat;
		return result;
	}

	public function finishBeatUpdate(beat:Float):Void {
		dirty = false;
	}

	/** 
	 * Apply the modifier to the result (Affects the notes and strums).
	 * 
	 * @param result The result to apply the modifier to.
	 * @param beat The current beat.
	 * @param lane The current lane.
	*/
	public function applyMod(result:ModResult, beat:Float, lane:Int):Void {}

	public function markDirty():Void {
		dirty = true;
	}

	/** 
	 * Get the value of a sub value.
	 * 
	 * @param name The name of the sub value.
	 * @return The value of the sub value.
	*/
	public function getSubValue(name:String):Float {
		return subValues.exists(name) ? subValues.get(name) : 0;
	}

	/** 
	 * Set the value of a sub value.
	 * 
	 * @param name The name of the sub value.
	 * @param value The value of the sub value.
	*/
	public function setSubValue(name:String, value:Float):Void {
		if (subValues.get(name) == value)
			return;
		subValues.set(name, value);
		markDirty();
	}

	/** 
	 * Check if a sub value exists.
	 * 
	 * @param name The name of the sub value.
	 * @return Whether the sub value exists.
	*/
	public function hasSubValue(name:String):Bool {
		return subValues.exists(name);
	}
}