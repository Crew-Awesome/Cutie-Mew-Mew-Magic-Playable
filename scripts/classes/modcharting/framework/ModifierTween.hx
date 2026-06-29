package modcharting.framework;

import modcharting.modifiers.BaseModifier;

/**
 * Handles the interpolation of a modifier's property over a specific duration of beats.
 * This class uses an easing function to transition between start and end values.
 */
class ModifierTween {
	/** 
	 * The modifier instance being animated. 
	*/
	public var mod:BaseModifier;

	/** 
	 * The name of the property to tween. 
	 * If set to "value", it targets the main intensity; otherwise, it targets a sub-value. 
	 */
	public var propertyName:String;

	/** 
	 * Starting value of the property at the beginning of the tween. 
	*/
	public var startValue:Float;

	/** 
	 * Target value to reach by the end of the duration. 
	 */
	public var endValue:Float;

	/** 
	 * Total length of the animation in beats. 
	 */
	public var duration:Float;

	/** 
	 * The song beat at which this tween starts. 
	 */
	public var startBeat:Float;

	/** 
	 * Easing function used to calculate the interpolation curve (e.g., `FlxEase.cubeOut`). 
	 */
	public var ease:Float->Float;

	/** 
	 * Whether the tween is currently processing. 
	 */
	public var active:Bool = true;

	/** 
	 * Flag indicating if the tween has reached its destination. 
	*/
	public var finished:Bool = false;

	/** 
	 * Creates a new ModifierTween instance.
	 * 
	 * @param mod The modifier instance to animate.
	 * @param propertyName The name of the property to tween. If set to "value", it targets the main intensity; otherwise, it targets a sub-value.
	 * @param startValue The starting value of the property at the beginning of the tween.
	 * @param endValue The target value to reach by the end of the duration.
	 * @param duration The total length of the animation in beats.
	 * @param startBeat The song beat at which this tween starts.
	 * @param ease The easing function used to calculate the interpolation curve (e.g., `FlxEase.cubeOut`).
	 */
	public function new(mod:BaseModifier, propertyName:String, startValue:Float, endValue:Float, duration:Float, startBeat:Float, ease:Float->Float) {
		this.mod = mod;
		this.propertyName = propertyName;
		this.startValue = startValue;
		this.endValue = endValue;
		this.duration = duration;
		this.startBeat = startBeat;
		this.ease = ease;
	}

	/**
	 * Updates the target property's value based on the current song beat.
	 * @param currentBeat The current beat position of the song.
	 */
	public function update(currentBeat:Float):Void {
		if (!active || finished)
			return;

		// Calculate progress in beats
		var elapsed = currentBeat - startBeat;

		// Clamp to duration and mark as finished if the end is reached
		if (elapsed >= duration) {
			elapsed = duration;
			finished = true;
		}

		// Normalize time (0.0 to 1.0) and apply the easing function
		var t = elapsed / duration;
		var eased = ease(t);

		// Linear interpolation (lerp) based on the eased progress
		var current = startValue + (endValue - startValue) * eased;

		// Apply the value to the modifier
		if (propertyName == "value") {
			mod.value = current;
		} else {
			mod.setSubValue(propertyName, current);
		}

		// Ensure the modifier knows its state has changed
		mod.markDirty();
	}
}