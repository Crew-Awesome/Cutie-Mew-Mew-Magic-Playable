import funkin.visuals.objects.VideoSprite;
import funkin.visuals.game.Note;
import flixel.text.FlxText.FlxTextBorderStyle;

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
var noteSpeedStart:Float = 0.65;
var noteSpeedTarget:Float = 3;
var noteSpeedCurrent:Float = 3;
var noteSpeedLerpActive:Bool = false;
var noteSpeedLerpTime:Float = 0;
var noteSpeedLerpDuration:Float = 2.2;

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

    for (index => strum in line.strums.members)
    {
        if (strum != null)
            strum.x = targetX + spacing * index;
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
    setAllStrumSpeeds(noteSpeedStart);
}

function onUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    centerPlayerStrumLine();
    resizeVideo();
    resizeOverlay();
    layoutHealthBar();
    updateStackedScoreText();
}

function postUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    centerPlayerStrumLine();
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
