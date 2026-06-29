import funkin.visuals.objects.VideoSprite;
import funkin.visuals.game.Note;
import flixel.text.FlxText.FlxTextBorderStyle;
import modcharting.ModchartManager;
import modcharting.modifiers.modifiers.MewCompositeModifier;

var showVideo:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicShowVideo');

if (showVideo == null)
    showVideo = true;

var cutieBg:FlxSprite;
var cutieVideo:VideoSprite;
var cutieOverlay:FlxSprite;
var introOverlay:FlxSprite;
var introText:FlxText;
var introStarted:Bool = false;
var introActive:Bool = false;
var mewModchartManager:ModchartManager;
var mewCompositeModifier:MewCompositeModifier;
var noteSpeedStart:Float = 0.65;
var noteSpeedTarget:Float = 3;
var noteSpeedCurrent:Float = 3;
var noteSpeedLerpActive:Bool = false;
var noteSpeedLerpTime:Float = 0;
var noteSpeedLerpDuration:Float = 2.2;
var mewModchartActive:Bool = false;
var mewSineActive:Bool = false;
var mewSineStartTime:Float = 32017;
var mewTraverseAmount:Float = 190;
var mewSineAmount:Float = 30;
var mewSineFade:Float = 1;
var mewPurpleProgress:Float = 0;
var mewPurpleTween:Dynamic = null;
var mewPurpleR:Int = 0xFFFFA6FF;
var mewPurpleG:Int = 0xFFC76CFF;
var mewPurpleB:Int = 0xFF54209A;
var mewLaneNormalR:Array<Int> = [];
var mewLaneNormalG:Array<Int> = [];
var mewLaneNormalB:Array<Int> = [];
var mewSongTime:Float = 0;
var mewPrepX:Float = 0;
var mewPulseY:Float = 0;
var mewPrepTween:Dynamic = null;
var mewPulseTween:Dynamic = null;
var mewSineFadeTween:Dynamic = null;
var mewDefaultStrumY:Array<Float> = [];
var mewHopOffsetsX:Array<Float> = [0, 0, 0, 0];
var mewHopOffsetsY:Array<Float> = [0, 0, 0, 0];
var mewHopTweens:Array<Dynamic> = [];
var mewDrumOffsetsX:Array<Float> = [0, 0, 0, 0];
var mewDrumOffsetsY:Array<Float> = [0, 0, 0, 0];
var mewDrumTweens:Array<Dynamic> = [];
var mewJumpOffsetsY:Array<Float> = [0, 0, 0, 0];
var mewJumpAngles:Array<Float> = [0, 0, 0, 0];
var mewJumpTweens:Array<Dynamic> = [];
var mewDizzyActive:Bool = false;
var mewDizzyStartTime:Float = 0;
var mewDizzyEndTime:Float = 0;
var mewPressOffsetsY:Array<Float> = [0, 0, 0, 0];
var mewPressTweens:Array<Dynamic> = [null, null, null, null];
var mewEventTimes:Array<Float> = [30684, 31017, 31350, 31684, 32017, 40017, 40350, 40684, 41017, 41350, 41684, 48850, 49017, 50183, 50517];
var mewAmbientX:Array<Float> = [0, 0, 0, 0];
var mewAmbientY:Array<Float> = [0, 0, 0, 0];
var mewAmbientAngle:Array<Float> = [0, 0, 0, 0];

function getPlay():PlayState
    return PlayState.instance;

function centerPlayerStrumLine()
{
    final play = getPlay();

    if (play == null || play.playerStrumLines == null || play.playerStrumLines.members == null)
        return;

    final line = play.playerStrumLines.members[0];

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

    if (mewDefaultStrumY.length != line.strums.members.length)
        mewDefaultStrumY = [for (strum in line.strums.members) strum == null ? 0 : strum.y];

    for (index => strum in line.strums.members)
    {
        if (strum != null)
        {
            strum.x = targetX + spacing * index;
            strum.y = mewDefaultStrumY[index];
            strum.angle = 0;
        }
    }
}

function getPlayerLine():Dynamic
{
    final play = getPlay();

    if (play == null || play.playerStrumLines == null || play.playerStrumLines.members == null)
        return null;

    return play.playerStrumLines.members[0];
}

function mewModchartsEnabled():Bool
{
    final value:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicModcharts');

    return value != false;
}

function cacheMewLaneColors()
{
    final line = getPlayerLine();

    if (line == null || line.strums == null || line.strums.members == null)
        return;

    if (mewLaneNormalR.length == line.strums.members.length)
        return;

    mewLaneNormalR = [];
    mewLaneNormalG = [];
    mewLaneNormalB = [];

    for (strum in line.strums.members)
    {
        if (strum == null || strum._castShader == null)
        {
            mewLaneNormalR.push(0xFFFF0000);
            mewLaneNormalG.push(0xFF00FF00);
            mewLaneNormalB.push(0xFF0000FF);
        }
        else
        {
            mewLaneNormalR.push(strum._castShader.r);
            mewLaneNormalG.push(strum._castShader.g);
            mewLaneNormalB.push(strum._castShader.b);
        }
    }
}

function setMewShaderPurple(shader:Dynamic, lane:Int, isNote:Bool)
{
    if (shader == null)
        return;

    cacheMewLaneColors();

    if (lane < 0 || lane >= mewLaneNormalR.length)
        lane = 0;

    shader.r = FlxColor.interpolate(mewLaneNormalR[lane], mewPurpleR, mewPurpleProgress);
    shader.g = FlxColor.interpolate(mewLaneNormalG[lane], mewPurpleG, mewPurpleProgress);
    shader.b = FlxColor.interpolate(mewLaneNormalB[lane], mewPurpleB, mewPurpleProgress);

    if (isNote || mewPurpleProgress > 0)
        shader.multiplier = 1;
}

function updateMewNoteColors()
{
    final line = getPlayerLine();

    if (line == null)
        return;

    if (line.strums != null && line.strums.members != null)
        for (index => strum in line.strums.members)
            if (strum != null)
            {
                setMewShaderPurple(strum._castShader, index, false);
                if (mewPurpleProgress <= 0 && strum.animation != null && strum.animation.name == strum.strumLineConfig.idle)
                    strum._castShader.multiplier = 0;
            }

    if (line.notes != null && line.notes.members != null)
        for (note in line.notes.members)
            if (note != null)
                setMewShaderPurple(note._castShader, note.data, true);
}

function tweenMewPurple(target:Float, duration:Float)
{
    if (!mewModchartsEnabled())
        return;

    if (mewPurpleTween != null)
        mewPurpleTween.cancel();

    mewPurpleTween = FlxTween.num(mewPurpleProgress, target, duration, {
        ease: FlxEase.sineInOut,
        onComplete: function(_)
        {
            mewPurpleProgress = target;
            mewPurpleTween = null;
            updateMewNoteColors();
        }
    }, function(value:Float)
    {
        mewPurpleProgress = value;
        updateMewNoteColors();
    });
}

function setupMewModchartManager()
{
    final play = getPlay();

    if (play == null || play.playerStrumLines == null || mewModchartManager != null)
        return;

    mewModchartManager = new ModchartManager(play.playerStrumLines);
    mewCompositeModifier = new MewCompositeModifier();
    mewModchartManager.prepareMod('mewComposite', function()
    {
        return mewCompositeModifier;
    }, -1, -1);
    mewCompositeModifier.value = 1;

    for (index in 0...mewEventTimes.length)
        scheduleMewFrameworkEvent(index);

    final targetIndex:Int = play.strumLines == null ? -1 : game.members.indexOf(play.strumLines);

    if (targetIndex >= 0)
        game.insert(targetIndex, mewModchartManager);
    else
        game.add(mewModchartManager);
}

function scheduleMewFrameworkEvent(index:Int)
{
    mewModchartManager.scheduleEvent(mewEventTimes[index] / Conductor.crochet, function()
    {
        runMewTimedEvent(index);
    });
}

function clearMewHopTweens()
{
    for (tween in mewHopTweens)
        if (tween != null)
            tween.cancel();

    mewHopTweens = [];
}

function resetMewModchart(?instant:Bool = false)
{
    mewModchartActive = false;
    mewSineActive = false;
    mewDizzyActive = false;
    clearMewHopTweens();
    clearMewDrumTweens();
    clearMewJumpTweens();
    clearMewPressTweens();

    if (mewPrepTween != null)
    {
        mewPrepTween.cancel();
        mewPrepTween = null;
    }

    if (mewPulseTween != null)
    {
        mewPulseTween.cancel();
        mewPulseTween = null;
    }

    if (mewSineFadeTween != null)
    {
        mewSineFadeTween.cancel();
        mewSineFadeTween = null;
    }

    mewPrepX = 0;
    mewPulseY = 0;
    mewSineFade = 1;
    if (instant && mewPurpleTween == null)
    {
        mewPurpleProgress = 0;
        updateMewNoteColors();
    }

    for (i in 0...mewHopOffsetsX.length)
    {
        mewHopOffsetsX[i] = 0;
        mewHopOffsetsY[i] = 0;
        mewDrumOffsetsX[i] = 0;
        mewDrumOffsetsY[i] = 0;
        mewJumpOffsetsY[i] = 0;
        mewJumpAngles[i] = 0;
        mewPressOffsetsY[i] = 0;
        mewAmbientX[i] = 0;
        mewAmbientY[i] = 0;
        mewAmbientAngle[i] = 0;
    }

    final line = getPlayerLine();

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

    applyMewModchart();
}

function windUpPulse(amount:Float)
{
    if (!mewModchartsEnabled())
        return;

    mewModchartActive = true;

    if (amount <= 4)
        tweenMewPurple(1, Conductor.crochet * 1.3 / 1000);

    if (mewPrepTween != null)
        mewPrepTween.cancel();

    if (mewPulseTween != null)
        mewPulseTween.cancel();

    final targetPrep:Float = -FlxMath.bound(amount / 13, 0, 1) * mewTraverseAmount;
    mewPrepTween = FlxTween.num(mewPrepX, targetPrep, Conductor.stepCrochet / 280, {ease: FlxEase.quadOut}, function(value:Float)
    {
        mewPrepX = value;
    });

    mewPulseY = -amount * 1.1;
    mewPulseTween = FlxTween.num(mewPulseY, 0, Conductor.stepCrochet / 420, {ease: FlxEase.quadOut}, function(value:Float)
    {
        mewPulseY = value;
    });

    final line = getPlayerLine();

    if (line == null || line.strums == null || line.strums.members == null)
        return;

    for (index => strum in line.strums.members)
    {
        if (strum == null)
            continue;

        FlxTween.cancelTweensOf(strum);

        final side:Float = index < 2 ? -1 : 1;
        strum.angle = side * amount * 0.35;

        FlxTween.tween(strum, {angle: 0}, Conductor.stepCrochet / 420, {ease: FlxEase.quadOut});
    }
}

function startMewSineTraverse()
{
    if (!mewModchartsEnabled())
        return;

    mewModchartActive = true;
    mewSineActive = true;
    mewSineStartTime = mewSongTime;
    mewSineFade = 1;

    if (mewSineFadeTween != null)
    {
        mewSineFadeTween.cancel();
        mewSineFadeTween = null;
    }

    mewPrepX = 0;
}

function stopMewSineTraverse()
{
    if (!mewSineActive)
        return;

    if (mewSineFadeTween != null)
        mewSineFadeTween.cancel();

    mewSineFadeTween = FlxTween.num(mewSineFade, 0, Conductor.crochet / 1000, {
        ease: FlxEase.circOut,
        onComplete: function(_)
        {
            mewSineActive = false;
            mewSineFade = 0;
            mewSineFadeTween = null;
        }
    }, function(value:Float)
    {
        mewSineFade = value;
    });
}

function clearMewWaveMotionAfterFade()
{
    mewSineActive = false;
    mewSineFade = 0;
    mewPrepX = 0;
    mewPulseY = 0;
}

function hopMewReceptors(lanes:Array<Int>)
{
    if (!mewModchartsEnabled())
        return;

    mewModchartActive = true;

    final riseTime:Float = Conductor.stepCrochet / 850;
    final returnTime:Float = Conductor.stepCrochet / 650;

    for (lane in lanes)
    {
        if (lane < 0 || lane >= mewHopOffsetsX.length)
            continue;

        final dir:Float = lane == 0 ? 1 : lane == 1 ? 1 : lane == 2 ? -1 : -1;
        final offset = {x: mewHopOffsetsX[lane], y: mewHopOffsetsY[lane]};

        var upTween = FlxTween.tween(offset, {x: dir * 20, y: -44}, riseTime, {
            ease: FlxEase.circOut,
            onUpdate: function(_)
            {
                mewHopOffsetsX[lane] = offset.x;
                mewHopOffsetsY[lane] = offset.y;
            },
            onComplete: function(_)
            {
                var downTween = FlxTween.tween(offset, {x: 0, y: 0}, returnTime, {
                    ease: FlxEase.circOut,
                    onUpdate: function(_)
                    {
                        mewHopOffsetsX[lane] = offset.x;
                        mewHopOffsetsY[lane] = offset.y;
                    },
                    onComplete: function(_)
                    {
                        mewHopOffsetsX[lane] = 0;
                        mewHopOffsetsY[lane] = 0;
                    }
                });

                mewHopTweens.push(downTween);
            }
        });

        mewHopTweens.push(upTween);
    }
}

function clearMewDrumTweens()
{
    for (tween in mewDrumTweens)
        if (tween != null)
            tween.cancel();

    mewDrumTweens = [];

    for (i in 0...mewDrumOffsetsX.length)
    {
        mewDrumOffsetsX[i] = 0;
        mewDrumOffsetsY[i] = 0;
    }
}

function clearMewJumpTweens()
{
    for (tween in mewJumpTweens)
        if (tween != null)
            tween.cancel();

    mewJumpTweens = [];

    for (i in 0...mewJumpOffsetsY.length)
    {
        mewJumpOffsetsY[i] = 0;
        mewJumpAngles[i] = 0;
    }
}

function drumImpactMew(strength:Float)
{
    if (!mewModchartsEnabled())
        return;

    final hitTime:Float = Conductor.stepCrochet / 1500;
    final settleTime:Float = Conductor.stepCrochet / 520;

    for (lane in 0...4)
    {
        final side:Float = lane < 2 ? -1 : 1;
        final inner:Float = (lane == 1 || lane == 2) ? 0.55 : 1;
        final targetX:Float = side * 30 * inner * strength;
        final targetY:Float = (lane % 2 == 0 ? 38 : -30) * strength;
        final offset = {x: mewDrumOffsetsX[lane], y: mewDrumOffsetsY[lane]};

        var hitTween = FlxTween.tween(offset, {x: targetX, y: targetY}, hitTime, {
            ease: FlxEase.circOut,
            onUpdate: function(_)
            {
                mewDrumOffsetsX[lane] = offset.x;
                mewDrumOffsetsY[lane] = offset.y;
            },
            onComplete: function(_)
            {
                var settleTween = FlxTween.tween(offset, {x: 0, y: 0}, settleTime, {
                    ease: FlxEase.circOut,
                    onUpdate: function(_)
                    {
                        mewDrumOffsetsX[lane] = offset.x;
                        mewDrumOffsetsY[lane] = offset.y;
                    },
                    onComplete: function(_)
                    {
                        mewDrumOffsetsX[lane] = 0;
                        mewDrumOffsetsY[lane] = 0;
                    }
                });

                mewDrumTweens.push(settleTween);
            }
        });

        mewDrumTweens.push(hitTween);
    }
}

function startDizzyBuildMew(startTime:Float, endTime:Float)
{
    if (!mewModchartsEnabled())
        return;

    mewDizzyActive = true;
    mewDizzyStartTime = startTime;
    mewDizzyEndTime = endTime;
}

function stopDizzyBuildMew()
{
    mewDizzyActive = false;
}

function dizzyEndJumpMew()
{
    clearMewJumpTweens();

    final upTime:Float = Conductor.stepCrochet / 850;
    final downTime:Float = Conductor.stepCrochet / 420;

    for (lane in 0...4)
    {
        final side:Float = lane < 2 ? -1 : 1;
        final offset = {y: mewJumpOffsetsY[lane], angle: mewJumpAngles[lane]};

        var upTween = FlxTween.tween(offset, {y: -54, angle: side * 8}, upTime, {
            ease: FlxEase.circOut,
            onUpdate: function(_)
            {
                mewJumpOffsetsY[lane] = offset.y;
                mewJumpAngles[lane] = offset.angle;
            },
            onComplete: function(_)
            {
                var downTween = FlxTween.tween(offset, {y: 0, angle: 0}, downTime, {
                    ease: FlxEase.circOut,
                    onUpdate: function(_)
                    {
                        mewJumpOffsetsY[lane] = offset.y;
                        mewJumpAngles[lane] = offset.angle;
                    },
                    onComplete: function(_)
                    {
                        mewJumpOffsetsY[lane] = 0;
                        mewJumpAngles[lane] = 0;
                    }
                });

                mewJumpTweens.push(downTween);
            }
        });

        mewJumpTweens.push(upTween);
    }
}

function clearMewPressTweens()
{
    for (tween in mewPressTweens)
        if (tween != null)
            tween.cancel();

    for (i in 0...mewPressOffsetsY.length)
    {
        mewPressOffsetsY[i] = 0;
        mewPressTweens[i] = null;
    }
}

function bumpPressedLane(lane:Int)
{
    if (lane < 0 || lane >= mewPressOffsetsY.length)
        return;

    if (mewPressTweens[lane] != null)
        mewPressTweens[lane].cancel();

    mewPressOffsetsY[lane] = -58;
    mewPressTweens[lane] = FlxTween.num(mewPressOffsetsY[lane], 0, Conductor.stepCrochet / 420, {
        ease: FlxEase.circOut,
        onComplete: function(_)
        {
            mewPressOffsetsY[lane] = 0;
            mewPressTweens[lane] = null;
        }
    }, function(value:Float)
    {
        mewPressOffsetsY[lane] = value;
    });
}

function updateMewPressBumps()
{
    if (introActive)
        return;

    if (Controls.NOTE_LEFT_P)
        bumpPressedLane(0);

    if (Controls.NOTE_DOWN_P)
        bumpPressedLane(1);

    if (Controls.NOTE_UP_P)
        bumpPressedLane(2);

    if (Controls.NOTE_RIGHT_P)
        bumpPressedLane(3);
}

function applyMewModchart()
{
    if (mewCompositeModifier == null)
        return;

    updateMewAmbientOffsets();

    var traverseX:Float = 0;

    if (!mewSineActive && mewModchartActive && mewModchartsEnabled())
    {
        traverseX = mewPrepX;
    }

    mewCompositeModifier.value = 1;
    mewCompositeModifier.traverseX = traverseX;
    mewCompositeModifier.pulseY = mewPulseY;
    mewCompositeModifier.sineActive = mewSineActive;
    mewCompositeModifier.sineStartTime = mewSineStartTime;
    mewCompositeModifier.sineFade = mewSineFade;
    mewCompositeModifier.sineAmount = mewSineAmount;
    mewCompositeModifier.dizzyActive = mewDizzyActive;
    mewCompositeModifier.dizzyStartTime = mewDizzyStartTime;
    mewCompositeModifier.dizzyEndTime = mewDizzyEndTime;
    mewCompositeModifier.hopX = mewHopOffsetsX;
    mewCompositeModifier.hopY = mewHopOffsetsY;
    mewCompositeModifier.drumX = mewDrumOffsetsX;
    mewCompositeModifier.drumY = mewDrumOffsetsY;
    mewCompositeModifier.jumpY = mewJumpOffsetsY;
    mewCompositeModifier.jumpAngle = mewJumpAngles;
    mewCompositeModifier.pressY = mewPressOffsetsY;
    mewCompositeModifier.ambientX = mewAmbientX;
    mewCompositeModifier.ambientY = mewAmbientY;
    mewCompositeModifier.ambientAngle = mewAmbientAngle;
    mewCompositeModifier.markDirty();
}

function clearMewAmbientOffsets()
{
    for (i in 0...mewAmbientX.length)
    {
        mewAmbientX[i] = 0;
        mewAmbientY[i] = 0;
        mewAmbientAngle[i] = 0;
    }
}

function ambientWindow(start:Float, end:Float):Float
{
    if (mewSongTime < start || mewSongTime > end)
        return 0;

    final fade:Float = Conductor.crochet * 2;
    final fadeIn:Float = FlxMath.bound((mewSongTime - start) / fade, 0, 1);
    final fadeOut:Float = FlxMath.bound((end - mewSongTime) / fade, 0, 1);

    return FlxEase.sineInOut(Math.min(fadeIn, fadeOut));
}

function ambientIntroWindow(start:Float, end:Float):Float
{
    if (mewSongTime < start || mewSongTime > end)
        return 0;

    final fade:Float = Conductor.crochet * 2;
    final fadeIn:Float = FlxMath.bound((mewSongTime - start) / fade, 0, 1);

    return FlxEase.sineInOut(fadeIn);
}

function updateMewAmbientOffsets()
{
    clearMewAmbientOffsets();

    if (!mewModchartsEnabled() || mewSineActive)
        return;

    final beatTime:Float = mewSongTime / Conductor.crochet;

    // Intro: soft breathing from center.
    var strength:Float = ambientIntroWindow(0, 32017);
    if (strength > 0)
    {
        final breath:Float = Math.sin(beatTime / 4 * Math.PI * 2) * 18 * strength;

        mewAmbientX[0] -= breath;
        mewAmbientX[1] -= breath * 0.35;
        mewAmbientX[2] += breath * 0.35;
        mewAmbientX[3] += breath;
    }

    // Mid phrase: alternating pair sways.
    strength = ambientWindow(48017, 56000);
    if (strength > 0)
    {
        final sway:Float = Math.sin(beatTime / 2 * Math.PI * 2) * 22 * strength;
        final bob:Float = Math.cos(beatTime / 2 * Math.PI * 2) * 8 * strength;

        mewAmbientX[0] += sway;
        mewAmbientY[0] += bob;
        mewAmbientX[1] += sway;
        mewAmbientY[1] += bob;
        mewAmbientX[2] -= sway;
        mewAmbientY[2] -= bob;
        mewAmbientX[3] -= sway;
        mewAmbientY[3] -= bob;
    }

}

function runMewTimedEvent(index:Int)
{
    switch (index)
    {
        case 0:
            windUpPulse(4);

        case 1:
            windUpPulse(7);

        case 2:
            windUpPulse(10);

        case 3:
            windUpPulse(13);

        case 4:
            startMewSineTraverse();

        case 5:
            stopMewSineTraverse();
            hopMewReceptors([0, 1]);

        case 6:
            hopMewReceptors([2, 3]);

        case 7:
            hopMewReceptors([0, 1]);

        case 8:
            hopMewReceptors([2, 3]);

        case 9:
            tweenMewPurple(0, Conductor.crochet * 1.5 / 1000);

        case 10:
            clearMewWaveMotionAfterFade();

        case 11:
            drumImpactMew(1);

        case 12:
            drumImpactMew(0.85);

        case 13:
            drumImpactMew(1);

        case 14:
            drumImpactMew(1.15);

    }
}

function setGameplayInputBlocked(blocked:Bool)
{
    final play = getPlay();

    if (play == null || play.playerStrumLines == null || play.playerStrumLines.members == null)
        return;

    for (line in play.playerStrumLines.members)
    {
        if (line == null)
            continue;

        line.active = !blocked;

        if (!blocked)
            line.botplay = ClientPrefs.data.botplay;
    }
}

function setAllStrumSpeeds(value:Float)
{
    final play = getPlay();

    noteSpeedCurrent = value;

    if (play == null || play.strumLines == null || play.strumLines.members == null)
        return;

    for (line in play.strumLines.members)
    {
        if (line != null)
            line.speed = value;
    }
}

function beginNoteSpeedLerp()
{
    noteSpeedLerpTime = 0;
    noteSpeedLerpActive = true;
    setAllStrumSpeeds(noteSpeedStart);
}

function updateNoteSpeedLerp(elapsed:Float)
{
    if (!noteSpeedLerpActive)
        return;

    noteSpeedLerpTime += elapsed;

    final progress = FlxMath.bound(noteSpeedLerpTime / noteSpeedLerpDuration, 0, 1);
    final eased = FlxEase.cubeOut(progress);

    setAllStrumSpeeds(noteSpeedStart + (noteSpeedTarget - noteSpeedStart) * eased);

    if (progress >= 1)
        noteSpeedLerpActive = false;
}

function holdVideoForIntro()
{
    if (cutieVideo == null)
        return;

    cutieVideo.visible = false;
    cutieVideo.pause();
}

function releaseVideoForCountdown()
{
    if (cutieVideo == null)
        return;

    cutieVideo.visible = true;
    resizeVideo();
    cutieVideo.resume();
}

function hideGroupMembers(group:Dynamic)
{
    if (group == null || group.members == null)
        return;

    for (obj in group.members)
    {
        if (obj != null)
        {
            obj.visible = false;
            obj.alpha = 0;
        }
    }
}

function hidePlayCharacters()
{
    final play = getPlay();

    if (play == null)
        return;

    if (play.bf != null)
    {
        play.bf.visible = false;
        play.bf.alpha = 0;
    }

    if (play.dad != null)
    {
        play.dad.visible = false;
        play.dad.alpha = 0;
    }

    if (play.gf != null)
    {
        play.gf.visible = false;
        play.gf.alpha = 0;
    }

    hideGroupMembers(play.playerIcons);
    hideGroupMembers(play.opponentIcons);
    hideGroupMembers(play.extraIcons);
}

function disableBrokenMissCallbacks()
{
    final play = getPlay();

    if (play == null || play.strumLines == null || play.strumLines.members == null)
        return;

    for (strumLine in play.strumLines.members)
    {
        if (strumLine == null)
            continue;

        final originalMissCallback = strumLine.noteMissCallback;
        final originalSpawnCallback = strumLine.noteSpawnCallback;

        strumLine.noteMissCallback = function(note:Note)
        {
            if (note != null)
            {
                note.ignore = false;
                note.character = [0, 0];
            }

            return originalMissCallback(note);
        };

        strumLine.noteSpawnCallback = function(note:Note)
        {
            if (note != null)
            {
                note.ignore = false;
                note.character = [0, 0];
            }

            return originalSpawnCallback(note);
        };
    }
}

function resizeVideo()
{
    if (cutieVideo == null)
        return;

    cutieVideo.setGraphicSize(FlxG.width, FlxG.height);
    cutieVideo.updateHitbox();
    cutieVideo.screenCenter();
}

function getOverlayAlpha():Float
{
    final value:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicDarkOverlay');

    if (value == null)
        return 0.35;

    return FlxMath.bound(value, 0, 1);
}

function resizeOverlay()
{
    if (cutieOverlay == null)
        return;

    cutieOverlay.setGraphicSize(FlxG.width, FlxG.height);
    cutieOverlay.updateHitbox();
    cutieOverlay.screenCenter();
    cutieOverlay.alpha = getOverlayAlpha();
}

function formatNumber(value:Dynamic):String
    return Std.string(value == null ? 0 : value);

function updateStackedScoreText()
{
    final play = getPlay();

    if (play == null || play.scoreTxt == null)
        return;

    final scoreText = play.scoreTxt;
    final botplay:Bool = Reflect.getProperty(play, 'botplay') == true;
    final score = Reflect.getProperty(play, 'score');
    final combo = Reflect.getProperty(play, 'combo');
    final misses = Reflect.getProperty(play, 'misses');
    final accuracy = Reflect.getProperty(play, 'accuracy');

    scoreText.text = botplay
        ? 'BOTPLAY'
        : 'Score: ' + formatNumber(score) + '\nCombo: ' + formatNumber(combo) + '\nMisses: ' + formatNumber(misses) + '\nAccuracy: ' + CoolUtil.floorDecimal(accuracy == null ? 100 : accuracy, 2) + '%';
    scoreText.fieldWidth = 300;
    scoreText.alignment = 'left';
    scoreText.x = 24;
    scoreText.y = FlxG.height / 2 - scoreText.height / 2;
}

function layoutHealthBar()
{
    final play = getPlay();

    if (play == null || play.healthBar == null)
        return;

    play.healthBar.angle = 90;
    play.healthBar.x = FlxG.width - 42 - play.healthBar.width / 2;
    play.healthBar.y = FlxG.height / 2 - play.healthBar.height / 2;
    play.healthBar.fillingBack.color = FlxColor.RED;
    play.healthBar.fillingFront.color = FlxColor.LIME;
}

function shouldSkipCreditIntro():Bool
{
    final value:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicSkipCreditsIntro');

    return value == true;
}

function startCountdownAfterIntro()
{
    introActive = false;
    setGameplayInputBlocked(false);
    releaseVideoForCountdown();
    beginNoteSpeedLerp();
    startCountdown();
}

function startCreditIntro()
{
    if (introStarted)
        return;

    introStarted = true;
    introActive = true;
    setGameplayInputBlocked(true);
    setAllStrumSpeeds(noteSpeedStart);
    holdVideoForIntro();

    introOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF3A3A3A);
    introOverlay.alpha = 0.62;
    introOverlay.scrollFactor.set();
    introOverlay.cameras = [camOther];
    game.add(introOverlay);

    introText = new FlxText(0, 0, FlxG.width, 'Cutie Mew Mew Magic\n\nSong: Toby Fox\nChart: Gabri_JJBAxd\nSource: Deltarune\n\nCoding/Mod: Malloy\nModChart: Nezumieepy');
    introText.setFormat(Paths.font('vcr.ttf'), 28, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    introText.borderSize = 1.5;
    introText.scrollFactor.set();
    introText.cameras = [camOther];
    introText.screenCenter();
    game.add(introText);

    FlxTimer.wait(2.6, function()
    {
        FlxTween.tween(introOverlay, {alpha: 0}, 0.8, {ease: FlxEase.cubeOut});
        FlxTween.tween(introText, {alpha: 0}, 0.8, {
            ease: FlxEase.cubeOut,
            onComplete: function(_)
            {
                introOverlay.destroy();
                introText.destroy();
                startCountdownAfterIntro();
            }
        });
    });
}

function addBelowGameplay(obj:FlxSprite)
{
    final play = getPlay();

    if (play == null)
    {
        game.add(obj);
        return;
    }

    var targetIndex = -1;

    if (play.strumLines != null)
        targetIndex = game.members.indexOf(play.strumLines);

    if (targetIndex < 0 && play.uiGroup != null)
        targetIndex = game.members.indexOf(play.uiGroup);

    if (targetIndex < 0)
        game.add(obj);
    else
        game.insert(targetIndex, obj);
}

function onCreate()
{
    allowCameraMoving = false;
}

function postCreate()
{
    final play = getPlay();

    hidePlayCharacters();
    disableBrokenMissCallbacks();

    if (play != null && play.healthBar != null)
    {
        play.healthBar.fillingBack.color = FlxColor.RED;
        play.healthBar.fillingFront.color = FlxColor.LIME;
    }

    cutieBg = new FlxSprite(0, 0);
    cutieBg.loadGraphic(Paths.image('cutie-mew-mew-magic/bg'));
    cutieBg.setGraphicSize(FlxG.width, FlxG.height);
    cutieBg.updateHitbox();
    cutieBg.scrollFactor.set();
    cutieBg.antialiasing = ClientPrefs.data.antialiasing;
    cutieBg.cameras = [camGame];
    cutieBg.screenCenter();
    addBelowGameplay(cutieBg);

    if (showVideo)
    {
        cutieVideo = new VideoSprite(0, 0, Paths.video('cutie-mew-mew-magic/video'), true, true, function()
        {
            resizeVideo();
        });
        cutieVideo.scrollFactor.set();
        cutieVideo.antialiasing = ClientPrefs.data.antialiasing;
        cutieVideo.cameras = [camGame];
        addBelowGameplay(cutieVideo);
        holdVideoForIntro();
    }

    cutieOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    cutieOverlay.scrollFactor.set();
    cutieOverlay.cameras = [camGame];
    resizeOverlay();
    addBelowGameplay(cutieOverlay);

    layoutHealthBar();
    updateStackedScoreText();
    centerPlayerStrumLine();
    setupMewModchartManager();
    applyMewModchart();
    setAllStrumSpeeds(noteSpeedStart);
}

function onUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    mewSongTime = Conductor.songPosition;
    updateMewPressBumps();
    centerPlayerStrumLine();
    if (!mewModchartsEnabled() && mewModchartActive)
        resetMewModchart(true);
    if (mewPurpleProgress > 0 || mewPurpleTween != null)
        updateMewNoteColors();
    applyMewModchart();
    resizeVideo();
    resizeOverlay();
    layoutHealthBar();
    updateStackedScoreText();
}

function postUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    applyMewModchart();
    if (mewModchartManager != null)
        mewModchartManager.applyModifiers(Conductor.songPosition / Conductor.crochet);
    resizeVideo();
    resizeOverlay();
    updateNoteSpeedLerp(elapsed);
    layoutHealthBar();
    updateStackedScoreText();
}

function onSongInit()
{
    if (shouldSkipCreditIntro())
        startCountdownAfterIntro();
    else
        startCreditIntro();

    return Function_Stop;
}

function onKeyJustPressed(event:Dynamic)
{
    if (introActive)
        return Function_Stop;

    return Function_Continue;
}

function onKeyJustReleased(event:Dynamic)
{
    if (introActive)
        return Function_Stop;

    return Function_Continue;
}

function onNoteHit(note:Note)
{
    if (introActive)
        return Function_Stop;

    if (note != null)
        bumpPressedLane(note.data);

    return Function_Continue;
}

function onNoteMiss(note:Note)
{
    if (introActive)
        return Function_Stop;

    return Function_Continue;
}

function onSongStart()
{
    setGameplayInputBlocked(false);
    setAllStrumSpeeds(noteSpeedTarget);
    releaseVideoForCountdown();
}

function onPause()
{
    if (cutieVideo != null)
        cutieVideo.pause();
}

function onResume()
{
    if (cutieVideo != null)
        cutieVideo.resume();
}
