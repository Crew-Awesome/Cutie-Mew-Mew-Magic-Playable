import funkin.visuals.game.Note;
import flixel.text.FlxText.FlxTextBorderStyle;

var gasterBg:FlxSprite;
var introOverlay:FlxSprite;
var introText:FlxText;
var introStarted:Bool = false;
var introActive:Bool = false;
var modchartBaseY:Array<Float> = [];
var modchartTime:Float = 0;

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
    final spacing = line.config.spacing;
    final totalWidth = spacing * (line.strums.members.length - 1) + first.width;
    final targetX = (FlxG.width - totalWidth) / 2;

    line.x = 0;

    for (index => strum in line.strums.members)
        if (strum != null)
            strum.x = targetX + spacing * index;
}

function modchartEnabled():Bool
{
    final value:Dynamic = ClientPrefs.getPreference('cutieMewMewMagicModcharts');

    return value != false;
}

function applyGasterModchart(elapsed:Float)
{
    final play = getPlay();

    if (play == null || play.playerStrumLines == null || play.playerStrumLines.members == null)
        return;

    final line = play.playerStrumLines.members[0];

    if (line == null || line.strums == null || line.strums.members == null)
        return;

    modchartTime += elapsed;

    if (modchartBaseY.length != line.strums.members.length)
        modchartBaseY = [for (strum in line.strums.members) strum == null ? 0 : strum.y];

    final enabled:Bool = modchartEnabled();

    for (index => strum in line.strums.members)
    {
        if (strum == null)
            continue;

        final wave:Float = enabled ? Math.sin(modchartTime * 1.75 + index * 0.8) * 14 : 0;
        strum.y = modchartBaseY[index] + wave;
    }

    if (line.notes != null && line.notes.members != null)
    {
        for (note in line.notes.members)
        {
            if (note == null)
                continue;

            note.yOffset = enabled ? Math.sin(modchartTime * 1.75 + note.data * 0.8) * 14 : 0;
        }
    }
}

function hidePlayObjects()
{
    final play = getPlay();

    if (play == null)
        return;

    for (group in [play.characters, play.playerCharacters, play.opponentCharacters, play.extraCharacters, play.playerIcons, play.opponentIcons, play.extraIcons])
    {
        if (group == null || group.members == null)
            continue;

        for (obj in group.members)
        {
            if (obj != null)
            {
                obj.visible = false;
                obj.active = false;
                obj.alpha = 0;
            }
        }
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
    startCountdown();
}

function startCreditIntro()
{
    if (introStarted)
        return;

    introStarted = true;
    introActive = true;
    setGameplayInputBlocked(true);

    introOverlay = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xFF202020);
    introOverlay.alpha = 0.72;
    introOverlay.scrollFactor.set();
    introOverlay.cameras = [camOther];
    game.add(introOverlay);

    introText = new FlxText(0, 0, FlxG.width, "Gaster's Theme\n\nSong: Toby Fox\nChart: Paperzi\nSource: UNDERTALE\n\nCoding/Mod: Malloy");
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

function onCreate()
{
    allowCameraMoving = false;
}

function postCreate()
{
    final play = getPlay();

    hidePlayObjects();
    disableBrokenMissCallbacks();

    if (play != null && play.healthBar != null)
    {
        play.healthBar.fillingBack.color = FlxColor.RED;
        play.healthBar.fillingFront.color = FlxColor.LIME;
    }

    gasterBg = new FlxSprite(0, 0);
    gasterBg.loadGraphic(Paths.image('gaster-theme/bg'));
    gasterBg.setGraphicSize(FlxG.width, FlxG.height);
    gasterBg.updateHitbox();
    gasterBg.scrollFactor.set();
    gasterBg.cameras = [camGame];
    gasterBg.screenCenter();
    insert(0, gasterBg);

    centerPlayerStrumLine();
    applyGasterModchart(0);
    layoutHealthBar();
    updateStackedScoreText();
}

function onUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    centerPlayerStrumLine();
    applyGasterModchart(elapsed);
    hidePlayObjects();
    layoutHealthBar();
    updateStackedScoreText();
}

function postUpdate(elapsed:Float)
{
    if (introActive)
        setGameplayInputBlocked(true);

    centerPlayerStrumLine();
    applyGasterModchart(elapsed);
    hidePlayObjects();
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

function onScoreSave()
{
    final play = getPlay();

    if (play != null && Reflect.getProperty(play, 'botplay') != true && ClientPrefs.data.practice != true)
    {
        Save.custom.data.gasterThemeSecretPlayed = true;
        Save.saveCustom();
    }

    return Function_Continue;
}
