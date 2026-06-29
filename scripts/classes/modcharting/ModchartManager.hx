package modcharting;

import modcharting.framework.ModifierTween;
import modcharting.modifiers.BaseModifier;

/**
 * Data structure for a modifier that has been instantiated and assigned
 * to specific strum lines or indices.
 */
typedef PreparedModifier = {
	tag:String,
	strumLine:Int,
	strumIndex:Int,
	modifierName:String,
	instance:BaseModifier
}

/**
 * Represents a timed event to be executed at a specific song beat.
 */
typedef ScheduledEvent = {
	beat:Float,
	callback:Void->Void,
	executed:Bool
}

/**
 * ModchartManager handles the registration, scheduling, and application
 * of visual modifiers to the StrumLines and individual Strums.
 */
class ModchartManager extends scripting.haxe.ScriptedFlxBasic {
	/**
	 * Show log messages.
	 */
	public var showLogs:Bool = false;

	/**
	 * The focal length of the camera used for Z modifiers.
	 */
	public var focalLength:Float = 500;

	/////////////////////////////////////////////////////

	public var strumLines:FlxTypedGroup<StrumLine>;

	public var _eventsDirty:Bool = false;
	public var wasZActive:Bool = false;

	public var preparedMods:Map<String, PreparedModifier>;

	public var preparedModsList:Array<PreparedModifier>;
	public var activeModsList:Array<PreparedModifier>;

	public var activeTweens:Array<ModifierTween>;
	public var scheduledEvents:Array<ScheduledEvent>;

	public var originalStrums:Array<Array<Strum>>;

	// Cache of strum base values
	public var strumBaseX:Array<Float>;
	public var strumBaseY:Array<Float>;
	public var strumBaseScaleX:Array<Float>;
	public var strumBaseScaleY:Array<Float>;
	public var strumBaseAngle:Array<Float>;
	public var strumBaseAlpha:Array<Float>;
	public var strumLineBaseSpeed:Array<Float>;
	public var strumCurrentZ:Array<Float>;

	// Z sorting
	public var _zSortBuffer:Array<{idx:Int, z:Float}>;

	/////////////////////////////////////////////////////

	/** 
	 * Creates a new modchart manager. 
	 * 
	 * @param strls The strum lines from the PlayState.
	 */
	public function new(strls:FlxTypedGroup<StrumLine>) {
		super();

		strumLines = strls;
		preparedMods = new Map();
		preparedModsList = [];
		activeModsList = [];
		activeTweens = [];
		scheduledEvents = [];

		strumBaseX = [];
		strumBaseY = [];
		strumBaseScaleX = [];
		strumBaseScaleY = [];
		strumBaseAngle = [];
		strumBaseAlpha = [];
		strumLineBaseSpeed = [];
		strumCurrentZ = [];
		wasZActive = false;

		originalStrums = [];
		for (slIndex in 0...getStrumLinesLength()) {
			originalStrums[slIndex] = [];
			for (sIndex in 0...getStrumLength(slIndex)) {
				originalStrums[slIndex][sIndex] = strumLines.members[slIndex].strums.members[sIndex];
			}
		}

		for (slIndex in 0...getStrumLinesLength()) {
			for (sIndex in 0...getStrumLength(slIndex)) {
				final strum = originalStrums[slIndex][sIndex];
				if (strum != null) {
					final idx = slIndex * 10 + sIndex;
					strumBaseX[idx] = strum.x;
					strumBaseY[idx] = strum.y;
					strumBaseScaleX[idx] = strum.scale.x;
					strumBaseScaleY[idx] = strum.scale.y;
					strumBaseAngle[idx] = strum.angle;
					strumBaseAlpha[idx] = strum.alpha;
					strumCurrentZ[idx] = 0;
				}
			}
		}
	}

	// Public API ///////////////////////////////////////////////////

	/** 
	 * Prepare a modifier to be used.
	 * 
	 * @param tag The tag of the modifier.
	 * @param factory The factory function of the modifier.
	 * @param strumLine The strum line index of the modifier.
	 * @param strumIndex The strum index of the modifier.
	 */
	public function prepareMod(tag:String, factory:Void->BaseModifier, strumLine:Int = -1, strumIndex:Int = -1):Void {
		if (tag == null || tag == "" || factory == null)
			return;
		if (preparedMods.exists(tag))
			return;

		if (strumLine == -1) {
			for (slIndex in 0...getStrumLinesLength()) {
				if (strumLineBaseSpeed[slIndex] == null)
					strumLineBaseSpeed[slIndex] = strumLines.members[slIndex].speed;
			}
		} else {
			if (strumLineBaseSpeed[strumLine] == null)
				strumLineBaseSpeed[strumLine] = strumLines.members[strumLine].speed;
		}

		final instance = factory();
		instance.manager = this;
		instance.strumLineIndex = strumLine;
		instance.strumIndex = strumIndex;

		final pm:PreparedModifier = {
			tag: tag,
			strumLine: strumLine,
			strumIndex: strumIndex,
			modifierName: instance.name,
			instance: instance
		};

		preparedMods.set(tag, pm);
		preparedModsList.push(pm);
	}

	/** 
	 * Set the value of a modifier.
	 * 
	 * @param beat The beat to set the modifier at.
	 * @param tag The tag of the modifier.
	 * @param props The modifiers with the values to set.
	 */
	public function setMod(beat:Float, props:Dynamic):Void {
		if (props == null)
			return;

		scheduleEvent(beat, function() {
			for (tag in Reflect.fields(props)) {
				if (!preparedMods.exists(tag))
					continue;
				final val:Float = Reflect.field(props, tag);
				preparedMods.get(tag).instance.value = val;
				preparedMods.get(tag).instance.markDirty();
			}
		});

		log('setMod (multiple) scheduled at beat $beat');
	}

	/** 
	 * Ease the value of a modifier.
	 * 
	 * @param beat The beat to set the modifier at.
	 * @param duration The duration of the ease.
	 * @param easeFunc The ease function to use.
	 * @param props The modifiers with the values to ease.
	 */
	public function easeMod(beat:Float, duration:Float, easeFunc:Float->Float, props:Dynamic):Void {
		if (props == null || duration < 0 || easeFunc == null)
			return;

		scheduleEvent(beat, function() {
			for (tag in Reflect.fields(props)) {
				if (!preparedMods.exists(tag))
					continue;
				final mod = preparedMods.get(tag).instance;
				final toValue:Float = Reflect.field(props, tag);
				activeTweens.push(new ModifierTween(mod, "value", mod.value, toValue, duration, beat, easeFunc));
			}
		});

		log('easeMod (multiple) over $duration beats at beat $beat');
	}

	/** 
	 * Set the value of a modifier sub value.
	 * 
	 * @param tag The tag of the modifier.
	 * @param beat The beat to set the modifier at.
	 * @param props The sub values of the modifier with the values to set.
	 */
	public function setModSubValue(tag:String, beat:Float, props:Dynamic):Void {
		if (tag == null || tag == "" || props == null)
			return;

		scheduleEvent(beat, function() {
			if (!preparedMods.exists(tag))
				return;
			final mod = preparedMods.get(tag).instance;
			for (field in Reflect.fields(props)) {
				if (!mod.hasSubValue(field))
					continue;
				mod.setSubValue(field, Reflect.field(props, field));
			}
			mod.markDirty();
		});

		log('Added sub value for [' + Reflect.fields(props).join(", ") + '] at beat $beat.');
	}

	/** 
	 * Ease the value of a modifier sub value.
	 * 
	 * @param tag The tag of the modifier.
	 * @param beat The beat to set the modifier at.
	 * @param duration The duration of the ease.
	 * @param easeFunc The ease function to use.
	 * @param props The sub values of the modifier with the values to ease.
	 */
	public function easeModSubValue(tag:String, beat:Float, duration:Null<Float>, easeFunc:Float->Float, props:Dynamic):Void {
		if (tag == null || tag == "" || duration == null || duration < 0 || easeFunc == null || props == null)
			return;

		scheduleEvent(beat, function() {
			if (!preparedMods.exists(tag))
				return;
			final mod = preparedMods.get(tag).instance;
			for (field in Reflect.fields(props))
			{
				if (!mod.hasSubValue(field))
					continue;

				activeTweens.push(new ModifierTween(mod, field, mod.getSubValue(field), Reflect.field(props, field), duration, beat, easeFunc));
			}
			log('Added ease for sub value for [' + Reflect.fields(props).join(", ") + '] at beat $beat.');
		});
	}

	/** 
	 * Remove a modifier.
	 * 
	 * @param tag The tag of the modifier.
	 */
	public function removeMod(tag:String):Void {
		final pm = preparedMods.get(tag);
		if (pm != null) {
			preparedModsList.remove(pm);
			activeModsList.remove(pm);
		}
		preparedMods.remove(tag);
	}

	/////////////////////////////////////////////////////

	public function log(msg:String):Void {
		if (!showLogs)
			return;
		debugTrace('[ModchartManager] $msg');
	}

	override public function update(elapsed:Float):Void {
		super.update(elapsed);

		if (!active)
			return;

		if (_eventsDirty) {
			scheduledEvents.sort(sortEvents);
			_eventsDirty = false;
		}

		for (strumLine in strumLines.members)
			for (sustain in strumLine.notes.members)
				if (sustain != null && sustain.type != 'arrow')
					sustain.copyAngle = false;

		final beat = getCurrentBeat();

		var i = 0;
		while (i < scheduledEvents.length) {
			final ev = scheduledEvents[i];
			if (ev == null || ev.executed) {
				scheduledEvents.splice(i, 1);
				continue;
			}
			if (beat >= ev.beat) {
				if (ev.callback != null)
					ev.callback();
				ev.executed = true;
				scheduledEvents.splice(i, 1);
				continue;
			}
			break;
		}

		for (tween in activeTweens)
			if (tween != null && tween.active)
				tween.update(beat);

		var j = activeTweens.length - 1;
		while (j >= 0) {
			if (activeTweens[j] != null && activeTweens[j].finished)
				activeTweens.splice(j, 1);
			j--;
		}

		applyModifiers(beat);

		for (pm in preparedModsList) {
			if (pm != null && pm.instance != null)
				pm.instance.finishBeatUpdate(beat);
		}
	}

	override public function draw():Void {
		super.draw();

		for (slIndex in 0...getStrumLinesLength()) {
			final strumsGroup = strumLines.members[slIndex].strums;
			if (strumsGroup != null && strumsGroup.group != null && originalStrums[slIndex] != null) {
				final members = strumsGroup.group.members;
				final orig = originalStrums[slIndex];
				for (i in 0...orig.length) {
					members[i] = orig[i];
				}
			}
		}
	}

	override public function destroy():Void {
		clear();
		super.destroy();
	}

	public function applyModifiers(beat:Float):Void {
		activeModsList.resize(0);
		for (pm in preparedModsList) {
			if (pm != null && pm.instance != null && pm.instance.isActive()) {
				activeModsList.push(pm);
			}
		}

		for (slIndex in 0...getStrumLinesLength()) {
			var rspeed:Float = Math.NaN;
			var hasZ:Bool = false;

			for (sIndex in 0...getStrumLength(slIndex)) {
				final strum = getStrum(slIndex, sIndex);
				if (strum == null)
					continue;

				final idx = slIndex * 10 + sIndex;

				final bx:Float = strumBaseX[idx];
				final by:Float = strumBaseY[idx];
				final bsx:Float = strumBaseScaleX[idx];
				final bsy:Float = strumBaseScaleY[idx];
				final bang:Float = strumBaseAngle[idx];
				final balp:Float = strumBaseAlpha[idx];

				var rx:Float = 0;
				var ry:Float = 0;
				var rz:Float = 0;
				var rangle:Float = 0;
				var ralpha:Float = 1;
				var rscaleX:Float = 1;
				var rscaleY:Float = 1;

				for (pm in activeModsList) {
					if (!targetsStrum(pm, slIndex, sIndex))
						continue;

					final r = pm.instance.calculate(beat, sIndex);
					if (r == null)
						continue;

					rx += r.x;
					ry += r.y;
					rz += r.z;
					rangle += r.angle;
					ralpha *= r.alpha;
					rscaleX *= r.scaleX;
					rscaleY *= r.scaleY;

					if (sIndex == 0 && !Math.isNaN(r.speed))
						rspeed = Math.isNaN(rspeed) ? r.speed : rspeed * r.speed;
				}

				strumCurrentZ[idx] = rz;
				if (rz != 0)
					hasZ = true;

				var finalScaleX = bsx * rscaleX;
				var finalScaleY = bsy * rscaleY;
				var finalX = bx + rx;
				var finalY = by + ry;

				if (rz != 0) {
					final scale:Float = focalLength / (focalLength + rz);
					finalX += (bx + rx - FlxG.width * 0.5) * (scale - 1);
					finalY += (by + ry - FlxG.height * 0.5) * (scale - 1);
					finalScaleX *= scale;
					finalScaleY *= scale;
				}

				strum.x = finalX;
				strum.y = finalY;
				strum.angle = bang + rangle;
				strum.alpha = balp * ralpha;
				strum.scale.set(finalScaleX, finalScaleY);
			}

			if (hasZ || wasZActive) {
				final strumsGroup = strumLines.members[slIndex].strums;
				if (strumsGroup != null && strumsGroup.group != null) {
					strumsGroup.group.sort(sortStrums, flixel.util.FlxSort.DESCENDING);
				}

				final notesGroup = strumLines.members[slIndex].notes;
				if (notesGroup != null && notesGroup.group != null) {
					notesGroup.group.sort(sortNotes, flixel.util.FlxSort.DESCENDING);
				}

				if (!hasZ) {
					wasZActive = false;
				} else {
					wasZActive = true;
				}
			}

			if (!Math.isNaN(rspeed))
				strumLines.members[slIndex].speed = rspeed;
		}
	}

	public function targetsStrum(pm:PreparedModifier, slIndex:Int, sIndex:Int):Bool {
		return (pm.strumLine == -1 || pm.strumLine == slIndex) && (pm.strumIndex == -1 || pm.strumIndex == sIndex);
	}

	public function getCurrentBeat():Float {
		if (Conductor.crochet != null && Conductor.crochet > 0)
			return Conductor.songPosition / Conductor.crochet;
		return 0;
	}

	public function scheduleEvent(beat:Float, cb:Void->Void):Void {
		scheduledEvents.push({beat: beat, callback: cb, executed: false});
		_eventsDirty = true;
	}

	public function getStrum(strlIndex:Int, strumIndex:Int):Strum {
		if (strlIndex < 0 || strlIndex >= originalStrums.length)
			return null;
		if (strumIndex < 0 || strumIndex >= originalStrums[strlIndex].length)
			return null;
		return originalStrums[strlIndex][strumIndex];
	}

	public function getStrumLinesLength():Int {
		return strumLines == null ? 0 : strumLines.members.length;
	}

	public function getStrumLength(strlIndex:Int):Int {
		if (strlIndex < 0 || strlIndex >= strumLines.members.length)
			return 0;
		return strumLines.members[strlIndex].strums.members.length;
	}

	public function getKeyCount(strumLine:Int = 0):Int {
		return getStrumLength(strumLine);
	}

	public function getStrumSpeed(strumLine:Int = 0):Float {
		return strumLineBaseSpeed[strumLine];
	}

	public function clearScheduled():Void {
		scheduledEvents = [];
	}

	public function clear():Void {
		preparedMods.clear();
		preparedModsList = [];
		activeModsList = [];
		activeTweens = [];
		scheduledEvents = [];
	}

	public function sortStrums(order:Int, a:Strum, b:Strum):Int {
		if (a == null || b == null)
			return 0;
		if (a.strumLine == null || b.strumLine == null)
			return 0;

		final slIndexA = strumLines.members.indexOf(a.strumLine);
		final slIndexB = strumLines.members.indexOf(b.strumLine);

		final idxA = slIndexA * 10 + a.data;
		final idxB = slIndexB * 10 + b.data;

		final zA = strumCurrentZ[idxA];
		final zB = strumCurrentZ[idxB];

		if (zA == zB) {
			return a.data < b.data ? -1 : (a.data > b.data ? 1 : 0);
		}

		if (zA > zB)
			return -1;
		else if (zA < zB)
			return 1;

		return 0;
	}

	public function sortNotes(order:Int, a:Note, b:Note):Int {
		if (a == null || b == null)
			return 0;
		if (a.strumLine == null || b.strumLine == null)
			return 0;

		final slIndexA = strumLines.members.indexOf(a.strumLine);
		final slIndexB = strumLines.members.indexOf(b.strumLine);

		final idxA = slIndexA * 10 + a.data;
		final idxB = slIndexB * 10 + b.data;

		final zA = strumCurrentZ[idxA];
		final zB = strumCurrentZ[idxB];

		if (zA == zB) {
			return 0;
		}
		if (zA > zB)
			return -1;
		else if (zA < zB)
			return 1;

		return 0;
	}

	public function sortEvents(a:ScheduledEvent, b:ScheduledEvent):Int {
		if (a == null || b == null)
			return 0;
		return a.beat < b.beat ? -1 : a.beat > b.beat ? 1 : 0;
	}
}
