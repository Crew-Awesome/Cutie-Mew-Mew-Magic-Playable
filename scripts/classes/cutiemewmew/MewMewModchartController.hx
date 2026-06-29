package cutiemewmew;

import core.audio.Conductor;
import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.config.ClientPrefs;
import funkin.states.PlayState;
import funkin.visuals.game.Note;
import modcharting.ModchartManager;
import modcharting.modifiers.modifiers.MewCompositeModifier;
import utils.Controls;

class MewMewModchartController
{
    var manager:ModchartManager;
    var composite:MewCompositeModifier;

    var active:Bool = false;
    var sineActive:Bool = false;
    var sineStartTime:Float = 32017;
    var traverseAmount:Float = 190;
    var sineAmount:Float = 30;
    var sineFade:Float = 1;
    var purpleProgress:Float = 0;
    var purpleTween:Dynamic = null;
    var purpleR:Int = 0xFFFFA6FF;
    var purpleG:Int = 0xFFC76CFF;
    var purpleB:Int = 0xFF54209A;
    var normalR:Array<Int> = [];
    var normalG:Array<Int> = [];
    var normalB:Array<Int> = [];
    var songTime:Float = 0;
    var prepX:Float = 0;
    var pulseY:Float = 0;
    var prepTween:Dynamic = null;
    var pulseTween:Dynamic = null;
    var sineFadeTween:Dynamic = null;
    var defaultStrumY:Array<Float> = [];
    var hopX:Array<Float> = [0, 0, 0, 0];
    var hopY:Array<Float> = [0, 0, 0, 0];
    var hopTweens:Array<Dynamic> = [];
    var drumX:Array<Float> = [0, 0, 0, 0];
    var drumY:Array<Float> = [0, 0, 0, 0];
    var drumTweens:Array<Dynamic> = [];
    var jumpY:Array<Float> = [0, 0, 0, 0];
    var jumpAngle:Array<Float> = [0, 0, 0, 0];
    var jumpTweens:Array<Dynamic> = [];
    var dizzyActive:Bool = false;
    var dizzyStartTime:Float = 0;
    var dizzyEndTime:Float = 0;
    var pressY:Array<Float> = [0, 0, 0, 0];
    var pressTweens:Array<Dynamic> = [null, null, null, null];
    var eventTimes:Array<Float> = [30684, 31017, 31350, 31684, 32017, 40017, 40350, 40684, 41017, 41350, 41684, 48850, 49017, 50183, 50517];
    var ambientX:Array<Float> = [0, 0, 0, 0];
    var ambientY:Array<Float> = [0, 0, 0, 0];
    var ambientAngle:Array<Float> = [0, 0, 0, 0];

    public function new() {}

    function play():PlayState
        return PlayState.instance;

    function playerLine():Dynamic
    {
        final state = play();
        if (state == null || state.playerStrumLines == null || state.playerStrumLines.members == null)
            return null;
        return state.playerStrumLines.members[0];
    }

    function enabled():Bool
    {
        final value:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicModcharts');
        return value != false;
    }

    public function setup()
    {
        centerPlayerStrumLine();

        final state = play();
        if (state == null || state.playerStrumLines == null || manager != null)
            return;

        manager = new ModchartManager(state.playerStrumLines);
        composite = new MewCompositeModifier();
        manager.prepareMod('mewComposite', function()
        {
            return composite;
        }, -1, -1);
        composite.value = 1;

        for (index in 0...eventTimes.length)
            scheduleEvent(index);

        final targetIndex:Int = state.strumLines == null ? -1 : state.members.indexOf(state.strumLines);
        if (targetIndex >= 0)
            state.insert(targetIndex, manager);
        else
            state.add(manager);
    }

    public function update(introActive:Bool)
    {
        songTime = Conductor.songPosition;
        updatePressBumps(introActive);
        centerPlayerStrumLine();

        if (!enabled() && active)
            reset(true);

        if (purpleProgress > 0 || purpleTween != null)
            updateNoteColors();

        syncModifier();
    }

    public function postUpdate()
    {
        syncModifier();
        if (manager != null)
            manager.applyModifiers(Conductor.songPosition / Conductor.crochet);
    }

    public function onNoteHit(note:Note)
    {
        if (note != null)
            bumpPressedLane(note.data);
    }

    public function centerPlayerStrumLine()
    {
        final line = playerLine();
        if (line == null || line.strums == null || line.strums.members == null || line.strums.members[0] == null)
            return;

        final first = line.strums.members[0];
        final last = line.strums.members[line.strums.members.length - 1];
        if (last == null)
            return;

        final spacing = line.config.spacing;
        final totalWidth = spacing * (line.strums.members.length - 1) + first.width;
        final targetX = (FlxG.width - totalWidth) / 2;

        line.x = 0;

        if (defaultStrumY.length != line.strums.members.length)
            defaultStrumY = [for (strum in line.strums.members) strum == null ? 0 : strum.y];

        for (index => strum in line.strums.members)
        {
            if (strum != null)
            {
                strum.x = targetX + spacing * index;
                strum.y = defaultStrumY[index];
                strum.angle = 0;
            }
        }
    }

    function scheduleEvent(index:Int)
    {
        manager.scheduleEvent(eventTimes[index] / Conductor.crochet, function()
        {
            runTimedEvent(index);
        });
    }

    function cacheLaneColors()
    {
        final line = playerLine();
        if (line == null || line.strums == null || line.strums.members == null || normalR.length == line.strums.members.length)
            return;

        normalR = [];
        normalG = [];
        normalB = [];

        for (strum in line.strums.members)
        {
            if (strum == null || strum._castShader == null)
            {
                normalR.push(0xFFFF0000);
                normalG.push(0xFF00FF00);
                normalB.push(0xFF0000FF);
            }
            else
            {
                normalR.push(strum._castShader.r);
                normalG.push(strum._castShader.g);
                normalB.push(strum._castShader.b);
            }
        }
    }

    function setShaderPurple(shader:Dynamic, lane:Int, isNote:Bool)
    {
        if (shader == null)
            return;

        cacheLaneColors();
        if (lane < 0 || lane >= normalR.length)
            lane = 0;

        shader.r = FlxColor.interpolate(normalR[lane], purpleR, purpleProgress);
        shader.g = FlxColor.interpolate(normalG[lane], purpleG, purpleProgress);
        shader.b = FlxColor.interpolate(normalB[lane], purpleB, purpleProgress);

        if (isNote || purpleProgress > 0)
            shader.multiplier = 1;
    }

    function updateNoteColors()
    {
        final line = playerLine();
        if (line == null)
            return;

        if (line.strums != null && line.strums.members != null)
        {
            for (index => strum in line.strums.members)
            {
                if (strum != null)
                {
                    setShaderPurple(strum._castShader, index, false);
                    if (purpleProgress <= 0 && strum.animation != null && strum.animation.name == strum.strumLineConfig.idle)
                        strum._castShader.multiplier = 0;
                }
            }
        }

        if (line.notes != null && line.notes.members != null)
            for (note in line.notes.members)
                if (note != null)
                    setShaderPurple(note._castShader, note.data, true);
    }

    function tweenPurple(target:Float, duration:Float)
    {
        if (!enabled())
            return;

        if (purpleTween != null)
            purpleTween.cancel();

        purpleTween = FlxTween.num(purpleProgress, target, duration, {
            ease: FlxEase.sineInOut,
            onComplete: function(_)
            {
                purpleProgress = target;
                purpleTween = null;
                updateNoteColors();
            }
        }, function(value:Float)
        {
            purpleProgress = value;
            updateNoteColors();
        });
    }

    function cancelTween(tween:Dynamic):Dynamic
    {
        if (tween != null)
            tween.cancel();
        return null;
    }

    function clearTweenList(list:Array<Dynamic>)
    {
        for (tween in list)
            if (tween != null)
                tween.cancel();
        list.resize(0);
    }

    function reset(?instant:Bool = false)
    {
        active = false;
        sineActive = false;
        dizzyActive = false;
        clearTweenList(hopTweens);
        clearTweenList(drumTweens);
        clearTweenList(jumpTweens);
        clearPressTweens();
        prepTween = cancelTween(prepTween);
        pulseTween = cancelTween(pulseTween);
        sineFadeTween = cancelTween(sineFadeTween);

        prepX = 0;
        pulseY = 0;
        sineFade = 1;

        if (instant && purpleTween == null)
        {
            purpleProgress = 0;
            updateNoteColors();
        }

        for (i in 0...4)
        {
            hopX[i] = 0;
            hopY[i] = 0;
            drumX[i] = 0;
            drumY[i] = 0;
            jumpY[i] = 0;
            jumpAngle[i] = 0;
            pressY[i] = 0;
            ambientX[i] = 0;
            ambientY[i] = 0;
            ambientAngle[i] = 0;
        }

        final line = playerLine();
        if (line == null || line.strums == null || line.strums.members == null)
            return;

        for (strum in line.strums.members)
        {
            if (strum == null)
                continue;

            FlxTween.cancelTweensOf(strum);
            strum.angle = 0;
            strum.direction = 0;
            strum.skew.set(0, 0);

            if (!instant)
                FlxTween.tween(strum, {angle: 0, direction: 0}, Conductor.stepCrochet / 500, {ease: FlxEase.cubeOut});
        }

        syncModifier();
    }

    function windUpPulse(amount:Float)
    {
        if (!enabled())
            return;

        active = true;
        if (amount <= 4)
            tweenPurple(1, Conductor.crochet * 1.3 / 1000);

        prepTween = cancelTween(prepTween);
        pulseTween = cancelTween(pulseTween);

        final targetPrep:Float = -FlxMath.bound(amount / 13, 0, 1) * traverseAmount;
        prepTween = FlxTween.num(prepX, targetPrep, Conductor.stepCrochet / 280, {ease: FlxEase.quadOut}, function(value:Float)
        {
            prepX = value;
        });
        pulseY = -amount * 1.1;
        pulseTween = FlxTween.num(pulseY, 0, Conductor.stepCrochet / 420, {ease: FlxEase.quadOut}, function(value:Float)
        {
            pulseY = value;
        });

        final line = playerLine();
        if (line == null || line.strums == null || line.strums.members == null)
            return;

        for (index => strum in line.strums.members)
        {
            if (strum == null)
                continue;
            FlxTween.cancelTweensOf(strum);
            strum.angle = (index < 2 ? -1 : 1) * amount * 0.35;
            FlxTween.tween(strum, {angle: 0}, Conductor.stepCrochet / 420, {ease: FlxEase.quadOut});
        }
    }

    function startSineTraverse()
    {
        if (!enabled())
            return;

        active = true;
        sineActive = true;
        sineStartTime = songTime;
        sineFade = 1;
        sineFadeTween = cancelTween(sineFadeTween);
        prepX = 0;
    }

    function stopSineTraverse()
    {
        if (!sineActive)
            return;

        sineFadeTween = cancelTween(sineFadeTween);
        sineFadeTween = FlxTween.num(sineFade, 0, Conductor.crochet / 1000, {
            ease: FlxEase.circOut,
            onComplete: function(_)
            {
                sineActive = false;
                sineFade = 0;
                sineFadeTween = null;
            }
        }, function(value:Float)
        {
            sineFade = value;
        });
    }

    function clearWaveMotionAfterFade()
    {
        sineActive = false;
        sineFade = 0;
        prepX = 0;
        pulseY = 0;
    }

    function hopReceptors(lanes:Array<Int>)
    {
        if (!enabled())
            return;

        active = true;
        final riseTime:Float = Conductor.stepCrochet / 850;
        final returnTime:Float = Conductor.stepCrochet / 650;

        for (lane in lanes)
        {
            if (lane < 0 || lane >= hopX.length)
                continue;

            final dir:Float = lane < 2 ? 1 : -1;
            final offset = {x: hopX[lane], y: hopY[lane]};
            var upTween = FlxTween.tween(offset, {x: dir * 20, y: -44}, riseTime, {
                ease: FlxEase.circOut,
                onUpdate: function(_) { hopX[lane] = offset.x; hopY[lane] = offset.y; },
                onComplete: function(_)
                {
                    var downTween = FlxTween.tween(offset, {x: 0, y: 0}, returnTime, {
                        ease: FlxEase.circOut,
                        onUpdate: function(_) { hopX[lane] = offset.x; hopY[lane] = offset.y; },
                        onComplete: function(_) { hopX[lane] = 0; hopY[lane] = 0; }
                    });
                    hopTweens.push(downTween);
                }
            });
            hopTweens.push(upTween);
        }
    }

    function clearDrumTweens()
    {
        clearTweenList(drumTweens);
        for (i in 0...4)
        {
            drumX[i] = 0;
            drumY[i] = 0;
        }
    }

    function clearJumpTweens()
    {
        clearTweenList(jumpTweens);
        for (i in 0...4)
        {
            jumpY[i] = 0;
            jumpAngle[i] = 0;
        }
    }

    function drumImpact(strength:Float)
    {
        if (!enabled())
            return;

        final hitTime:Float = Conductor.stepCrochet / 1500;
        final settleTime:Float = Conductor.stepCrochet / 520;

        for (lane in 0...4)
        {
            final side:Float = lane < 2 ? -1 : 1;
            final inner:Float = (lane == 1 || lane == 2) ? 0.55 : 1;
            final offset = {x: drumX[lane], y: drumY[lane]};
            var hitTween = FlxTween.tween(offset, {x: side * 30 * inner * strength, y: (lane % 2 == 0 ? 38 : -30) * strength}, hitTime, {
                ease: FlxEase.circOut,
                onUpdate: function(_) { drumX[lane] = offset.x; drumY[lane] = offset.y; },
                onComplete: function(_)
                {
                    var settleTween = FlxTween.tween(offset, {x: 0, y: 0}, settleTime, {
                        ease: FlxEase.circOut,
                        onUpdate: function(_) { drumX[lane] = offset.x; drumY[lane] = offset.y; },
                        onComplete: function(_) { drumX[lane] = 0; drumY[lane] = 0; }
                    });
                    drumTweens.push(settleTween);
                }
            });
            drumTweens.push(hitTween);
        }
    }

    function clearPressTweens()
    {
        for (tween in pressTweens)
            if (tween != null)
                tween.cancel();

        for (i in 0...4)
        {
            pressY[i] = 0;
            pressTweens[i] = null;
        }
    }

    function bumpPressedLane(lane:Int)
    {
        if (lane < 0 || lane >= pressY.length)
            return;

        if (pressTweens[lane] != null)
            pressTweens[lane].cancel();

        pressY[lane] = -58;
        pressTweens[lane] = FlxTween.num(pressY[lane], 0, Conductor.stepCrochet / 420, {
            ease: FlxEase.circOut,
            onComplete: function(_)
            {
                pressY[lane] = 0;
                pressTweens[lane] = null;
            }
        }, function(value:Float)
        {
            pressY[lane] = value;
        });
    }

    function updatePressBumps(introActive:Bool)
    {
        if (introActive)
            return;

        if (Controls.NOTE_LEFT_P) bumpPressedLane(0);
        if (Controls.NOTE_DOWN_P) bumpPressedLane(1);
        if (Controls.NOTE_UP_P) bumpPressedLane(2);
        if (Controls.NOTE_RIGHT_P) bumpPressedLane(3);
    }

    function clearAmbientOffsets()
    {
        for (i in 0...4)
        {
            ambientX[i] = 0;
            ambientY[i] = 0;
            ambientAngle[i] = 0;
        }
    }

    function ambientWindow(start:Float, end:Float):Float
    {
        if (songTime < start || songTime > end)
            return 0;

        final fade:Float = Conductor.crochet * 2;
        final fadeIn:Float = FlxMath.bound((songTime - start) / fade, 0, 1);
        final fadeOut:Float = FlxMath.bound((end - songTime) / fade, 0, 1);
        return FlxEase.sineInOut(Math.min(fadeIn, fadeOut));
    }

    function ambientIntroWindow(start:Float, end:Float):Float
    {
        if (songTime < start || songTime > end)
            return 0;

        final fade:Float = Conductor.crochet * 2;
        return FlxEase.sineInOut(FlxMath.bound((songTime - start) / fade, 0, 1));
    }

    function updateAmbientOffsets()
    {
        clearAmbientOffsets();

        if (!enabled() || sineActive)
            return;

        final beatTime:Float = songTime / Conductor.crochet;
        var strength:Float = ambientIntroWindow(0, 32017);

        if (strength > 0)
        {
            final breath:Float = Math.sin(beatTime / 4 * Math.PI * 2) * 18 * strength;
            ambientX[0] -= breath;
            ambientX[1] -= breath * 0.35;
            ambientX[2] += breath * 0.35;
            ambientX[3] += breath;
        }

        strength = ambientWindow(48017, 56000);
        if (strength > 0)
        {
            final sway:Float = Math.sin(beatTime / 2 * Math.PI * 2) * 22 * strength;
            final bob:Float = Math.cos(beatTime / 2 * Math.PI * 2) * 8 * strength;
            ambientX[0] += sway;
            ambientY[0] += bob;
            ambientX[1] += sway;
            ambientY[1] += bob;
            ambientX[2] -= sway;
            ambientY[2] -= bob;
            ambientX[3] -= sway;
            ambientY[3] -= bob;
        }
    }

    function syncModifier()
    {
        if (composite == null)
            return;

        updateAmbientOffsets();

        composite.value = 1;
        composite.traverseX = (!sineActive && active && enabled()) ? prepX : 0;
        composite.pulseY = pulseY;
        composite.sineActive = sineActive;
        composite.sineStartTime = sineStartTime;
        composite.sineFade = sineFade;
        composite.sineAmount = sineAmount;
        composite.dizzyActive = dizzyActive;
        composite.dizzyStartTime = dizzyStartTime;
        composite.dizzyEndTime = dizzyEndTime;
        composite.hopX = hopX;
        composite.hopY = hopY;
        composite.drumX = drumX;
        composite.drumY = drumY;
        composite.jumpY = jumpY;
        composite.jumpAngle = jumpAngle;
        composite.pressY = pressY;
        composite.ambientX = ambientX;
        composite.ambientY = ambientY;
        composite.ambientAngle = ambientAngle;
        composite.markDirty();
    }

    function runTimedEvent(index:Int)
    {
        switch (index)
        {
            case 0: windUpPulse(4);
            case 1: windUpPulse(7);
            case 2: windUpPulse(10);
            case 3: windUpPulse(13);
            case 4: startSineTraverse();
            case 5:
                stopSineTraverse();
                hopReceptors([0, 1]);
            case 6: hopReceptors([2, 3]);
            case 7: hopReceptors([0, 1]);
            case 8: hopReceptors([2, 3]);
            case 9: tweenPurple(0, Conductor.crochet * 1.5 / 1000);
            case 10: clearWaveMotionAfterFade();
            case 11: drumImpact(1);
            case 12: drumImpact(0.85);
            case 13: drumImpact(1);
            case 14: drumImpact(1.15);
        }
    }
}
