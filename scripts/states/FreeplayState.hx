import funkin.visuals.objects.Alphabet;

import funkin.config.Score;

import utils.Formatter;

using StringTools;

@:typedef JsonFreeplay = {
    var directory:String;
    var bg:JsonSprite;
    var cameraOffset:Point;
    var songsSpacing:Point;
    var cameraSpeed:Float;
    var changeBGColor:Bool;
    var infoCorner:String;
};

final config:JsonFreeplay = Paths.json('data/menus/freeplay');
final songs:Array<Dynamic> = [];

var bg:FlxSprite;
var freeplayMusicId:String = '';
var continueText:FlxText;
var sprites:FlxTypedGroup<FlxTypedSpriteGroup<FlxSprite>>;

var selInt(default, set):Int = Save.custom.data.freeplaySelInt ??= 0;
function set_selInt(value:Int):Int
    return selInt = Save.custom.data.freeplaySelInt = value;

var diffSelInt(default, set):Int = Save.custom.data.freeplayDiffSelInt ??= 1;
function set_diffSelInt(value:Int):Int
    return diffSelInt = Save.custom.data.freeplayDiffSelInt = value;

var infoBG:FlxSprite;
var scoreText:FlxText;
var difficultyText:FlxText;
var upDownMoves:Int = 0;
var weirdActive:Bool = false;
var weirdStep:Int = 0;
var weirdRevealed:Bool = false;
var weirdBaseName:String = 'Cutie Mew Mew Magic';
var weirdChars:Array<String> = ['_', '?', '.', '0', '1', '3', '7', '9', '!', '#', '*'];

function playMenuMoveSound()
{
    CoolUtil.playSound('deltarune/menumove', 0.9);
}

function setFreeplayMusic(id:String)
{
    if (freeplayMusicId == id || (Conductor.music != null && Save.custom.data.cutieMewMewMagicMenuMusic == id))
        return;

    freeplayMusicId = id;
    Save.custom.data.cutieMewMewMagicMenuMusic = id;
    Conductor.play(Paths.music(id), CoolVars.meta.bpm);
}

function updateFreeplayMusicForSelection()
{
    if (weirdRevealed)
        setFreeplayMusic('flashback-excerpt');
    else
        setFreeplayMusic('pink');
}

function bumpSelectedSong(xMove:Float, yMove:Float)
{
    final selected = sprites.members[selInt];

    if (selected == null)
        return;

    final baseY:Float = selInt * config.songsSpacing.y;

    FlxTween.cancelTweensOf(selected);
    selected.x = xMove;
    selected.y = baseY + yMove;
    selected.angle = yMove > 0 ? 2.5 : -2.5;

    FlxTween.tween(selected, {x: 0, y: baseY, angle: 0}, 0.18, {ease: FlxEase.cubeOut});
}

function bumpDifficultyBox(yDirection:Int)
{
    final baseInfoX:Float = FlxG.width / 2 - infoBG.width / 2;
    final baseScoreX:Float = FlxG.width / 2 - scoreText.width / 2;
    final baseDifficultyX:Float = FlxG.width / 2 - difficultyText.width / 2;
    final baseInfoY:Float = FlxG.height - infoBG.height;
    final baseScoreY:Float = baseInfoY + 10;
    final baseDifficultyY:Float = baseScoreY + scoreText.height + 4;
    final offset:Float = yDirection * 18;

    FlxTween.cancelTweensOf(infoBG);
    FlxTween.cancelTweensOf(scoreText);
    FlxTween.cancelTweensOf(difficultyText);

    infoBG.x = baseInfoX;
    scoreText.x = baseScoreX;
    difficultyText.x = baseDifficultyX;
    infoBG.y = baseInfoY + offset;
    scoreText.y = baseScoreY + offset;
    difficultyText.y = baseDifficultyY + offset;
    difficultyText.angle = yDirection * 2.5;

    FlxTween.tween(infoBG, {y: baseInfoY}, 0.16, {ease: FlxEase.cubeOut});
    FlxTween.tween(scoreText, {y: baseScoreY}, 0.16, {ease: FlxEase.cubeOut});
    FlxTween.tween(difficultyText, {y: baseDifficultyY, angle: 0}, 0.16, {ease: FlxEase.cubeOut});
}

function getSelectedSongLabel():Dynamic
{
    final selected = sprites.members[selInt];

    if (selected == null || selected.members == null || selected.members.length <= 0)
        return null;

    return selected.members[0];
}

function setSelectedSongName(name:String)
{
    final label:Dynamic = getSelectedSongLabel();

    if (label == null)
        return;

    label.text = name;
    label.alignment = 'centered';
    label.x = FlxG.width / 2;
}

function showContinueText()
{
    if (continueText == null)
        return;

    FlxTween.cancelTweensOf(continueText);
    continueText.alpha = 0.18;
    continueText.scale.set(1.04, 1.04);

    FlxTween.tween(continueText, {alpha: 0}, 1.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(continueText.scale, {x: 1, y: 1}, 1.35, {ease: FlxEase.cubeOut});
}

function updateWeirdBackground()
{
    final greys:Array<Int> = [0xFFFF9DD8, 0xFFD9CDD4, 0xFFC8C4C7, 0xFFB8B8B8, 0xFFA2A2A2, 0xFF898989, 0xFF6F6F6F];
    final greyIndex:Int = Std.int(Math.min(greys.length - 1, Math.floor(weirdStep / 2)));
    final target:Int = greys[greyIndex];

    FlxTween.cancelTweensOf(bg);
    FlxTween.color(bg, 2.2, bg.color, target, {ease: FlxEase.sineInOut});
}

function getCorruptedName():String
{
    final letters:Array<String> = weirdBaseName.split('');
    final amount:Int = Std.int(Math.min(letters.length - 1, 1 + weirdStep));
    var changed:Int = 0;
    var attempts:Int = 0;

    while (changed < amount && attempts < 80)
    {
        attempts++;

        final index:Int = FlxG.random.int(0, letters.length - 1);

        if (letters[index] != ' ')
        {
            letters[index] = weirdChars[FlxG.random.int(0, weirdChars.length - 1)];
            changed++;
        }
    }

    return letters.join('');
}

function explodeSongLetters()
{
    final label:Dynamic = getSelectedSongLabel();

    if (label == null || label.letters == null)
        return;

    CoolUtil.playSound('deltarune/badexplosion', 0.8);

    for (letter in label.letters)
    {
        if (letter == null)
            continue;

        FlxTween.cancelTweensOf(letter);
        letter.velocity.set(FlxG.random.float(-260, 260), FlxG.random.float(-520, -240));
        letter.acceleration.y = FlxG.random.float(900, 1250);
        letter.angularVelocity = FlxG.random.float(-520, 520);
        FlxTween.tween(letter, {alpha: 0}, 1.15, {ease: FlxEase.quadIn});
    }
}

function updateSecretScoreBox()
{
    final unlocked:Bool = Save.custom.data.gasterThemeSecretPlayed == true;

    if (unlocked)
    {
        final score:SongScore = Score.getSong('gaster-theme', 'yet-darker');
        scoreText.text = 'SCORE: ' + score.score + ' (' + CoolUtil.floorDecimal(score.accuracy, 2) + '%)';
    }
    else
        scoreText.text = 'SCORE: ???';

    difficultyText.text = '< YET DARKER >';
    infoBG.scale.set(Math.max(scoreText.width, difficultyText.width) + 60, scoreText.height + difficultyText.height + 28);
    infoBG.updateHitbox();
    infoBG.x = FlxG.width / 2 - infoBG.width / 2;
    infoBG.y = FlxG.height - infoBG.height;
    scoreText.x = FlxG.width / 2 - scoreText.width / 2;
    scoreText.y = infoBG.y + 10;
    difficultyText.x = FlxG.width / 2 - difficultyText.width / 2;
    difficultyText.y = scoreText.y + scoreText.height + 4;
}

function revealMissingSecretSong()
{
    if (weirdRevealed)
        return;

    weirdRevealed = true;
    explodeSongLetters();
    CoolUtil.playSound('deltarune/weird_route_jingle', 0.7);
    updateFreeplayMusicForSelection();
    showSecretPlaceholderSong(Save.custom.data.gasterThemeSecretPlayed == true ? "Gaster's Theme" : '???');
    updateSecretScoreBox();
}

function showSecretPlaceholderSong(title:String)
{
    final selected = sprites.members[selInt];

    if (selected == null)
        return;

    final secretText:Alphabet = new Alphabet(FlxG.width / 2, 0, title);
    secretText.alpha = 0;
    secretText.setScale(1.18);
    secretText.alignment = 'centered';
    secretText.x = FlxG.width / 2;
    secretText.y = -10;
    selected.add(secretText);

    FlxTween.tween(secretText, {alpha: 1, y: 0}, 1.15, {ease: FlxEase.cubeOut});
}

function startWeirdRouteHint()
{
    if (!weirdActive)
    {
        weirdActive = true;
        CoolUtil.playSound('deltarune/weird_route_jingle', 0.85);
    }

    updateWeirdBackground();
    setSelectedSongName(getCorruptedName());
    showContinueText();
}

function advanceWeirdRouteHint()
{
    if (!weirdActive || weirdRevealed)
        return;

    weirdStep++;
    updateWeirdBackground();
    showContinueText();

    if (weirdStep >= 13)
        revealMissingSecretSong();
    else
        setSelectedSongName(getCorruptedName());
}

function registerUpDownMove()
{
    upDownMoves++;

    if (upDownMoves == 9)
        startWeirdRouteHint();
    else if (upDownMoves > 9)
        advanceWeirdRouteHint();
}

function checkLocked(week:JsonWeek)
    return week.locked;

function onCreate()
{
    bg = CoolUtil.spriteFromJson(null, config.bg, 'menus/' + config.directory + '/');
    add(bg);
    updateFreeplayMusicForSelection();

    final weekNames:String = [];
    final weeks:Array<JsonWeek> = [];

    for (week in Paths.readDirectory('data/weeks', CoolVars.data.loadDefaultWeeks ? 'multiple' : 'unique'))
    {
        if (!week.endsWith('.json'))
            continue;

        var name:String = week.substring(0, week.length - 5);

        if (weekNames.contains(name))
            continue;

        weeks.push(Formatter.getWeek(name));
        weekNames.push(name);
    }

    sprites = new FlxTypedGroup<FlxTypedSpriteGroup<FlxSprite>>();
    add(sprites);

    for (week in weeks)
    {
        if (week.hideFreeplay || checkLocked(week))
            continue;

        for (song in week.songs)
            songs.push({
                name: song.name,
                color: CoolUtil.colorFromString(song.color),
                difficulties: week.difficulties
            });
    }

    for (index => song in songs)
    {
        final group:FlxTypedSpriteGroup<FlxSprite> = new FlxTypedSpriteGroup<FlxSprite>(0, index * config.songsSpacing.y);
        sprites.add(group);

        final text:Alphabet = new Alphabet(0, 0, song.name);
        text.alignment = 'centered';
        text.x = FlxG.width / 2;
        group.add(text);
    }

    if (config.changeBGColor && songs.length > 0)
        bg.color = songs[selInt].color;

    infoBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    infoBG.scrollFactor.set();
    infoBG.alpha = 0.5;
    add(infoBG);

    scoreText = new FlxText(0, 5, 0, 'SCORE', 40);
    scoreText.font = Paths.font('vcr.ttf');
    scoreText.scrollFactor.set();
    add(scoreText);

    difficultyText = new FlxText(0, scoreText.y + scoreText.height + 4, 0, '< DIFF >', 30);
    difficultyText.font = Paths.font('vcr.ttf');
    difficultyText.scrollFactor.set();
    add(difficultyText);

    continueText = new FlxText(0, FlxG.height * 0.28, FlxG.width, 'continue...', 42);
    continueText.font = Paths.font('deltarune.ttf');
    continueText.alignment = 'center';
    continueText.color = 0xFFEFEFEF;
    continueText.alpha = 0;
    continueText.scrollFactor.set();
    add(continueText);

    changeOption();
}

function changeOption(?change:Int = 0)
{
    selInt += change;

    if (selInt < 0)
        selInt = songs.length - 1;

    if (selInt > songs.length - 1)
        selInt = 0;

    for (index => obj in sprites.members)
    {
        FlxTween.cancelTweensOf(obj);
        obj.x = 0;
        obj.y = index * config.songsSpacing.y;
        obj.angle = 0;
        obj.alpha = index == selInt ? 1 : 0.5;

        if (index == selInt && config.changeBGColor && !weirdActive)
        {
            FlxTween.cancelTweensOf(bg);
            FlxTween.color(bg, 0.5, bg.color, songs[index].color, {ease: FlxEase.cubeOut});
        }
    }

    changeDifficulty();
}

function changeDifficulty(?change:Int = 0)
{
    final difficulties:Array<String> = songs[selInt].difficulties;

    diffSelInt += change;

    if (diffSelInt < 0)
        diffSelInt = difficulties.length - 1;

    if (diffSelInt > difficulties.length - 1)
        diffSelInt = 0;

    final score:SongScore = Score.getSong(songs[selInt].name, difficulties[diffSelInt]);

    scoreText.text = 'SCORE: ' + score.score + ' (' + CoolUtil.floorDecimal(score.accuracy, 2) + '%)';

    final diffText:String = difficulties[diffSelInt].trim().toUpperCase();

    difficultyText.text = difficulties.length <= 1 ? diffText : '< ' + diffText + ' >';

    infoBG.scale.set(Math.max(scoreText.width, difficultyText.width) + 60, scoreText.height + difficultyText.height + 28);
    infoBG.updateHitbox();
    infoBG.x = FlxG.width / 2 - infoBG.width / 2;
    infoBG.y = FlxG.height - infoBG.height;

    scoreText.x = FlxG.width / 2 - scoreText.width / 2;
    scoreText.y = infoBG.y + 10;

    difficultyText.x = FlxG.width / 2 - difficultyText.width / 2;
    difficultyText.y = scoreText.y + scoreText.height + 4;
}

var canSelect:Bool = true;

function onUpdate(elapsed:Float)
{
    camGame.scroll.x = CoolUtil.fpsLerp(camGame.scroll.x, 0, config.cameraSpeed);
    camGame.scroll.y = CoolUtil.fpsLerp(camGame.scroll.y, selInt * config.songsSpacing.y + config.cameraOffset.y, config.cameraSpeed);

    if (canSelect)
    {
        if (Controls.UI_DOWN_P || Controls.UI_UP_P)
        {
            if (weirdRevealed)
            {
                playMenuMoveSound();
                return;
            }

            final direction:Int = Controls.UI_DOWN_P ? 1 : -1;

            changeOption(direction);
            bumpSelectedSong(0, direction * 26);
            bumpDifficultyBox(direction);
            playMenuMoveSound();
            registerUpDownMove();
        }

        if (Controls.UI_LEFT_P || Controls.UI_RIGHT_P)
        {
            if (weirdRevealed)
            {
                playMenuMoveSound();
                return;
            }

            final direction:Int = Controls.UI_LEFT_P ? -1 : 1;

            changeDifficulty(direction);
            playMenuMoveSound();
        }

        if (Controls.BACK)
        {
            canSelect = false;
            CoolUtil.switchState(new CustomState(CoolVars.meta.mainMenuState));
            CoolUtil.playSound('cancel');
        }

        if (Controls.ACCEPT)
        {
            try
            {
                if (weirdRevealed)
                {
                    CoolUtil.switchState(new PlayState('freeplay', ['gaster-theme'], 'yet-darker'));
                    canSelect = false;
                    return;
                }

                final curSong = songs[selInt];
                CoolUtil.switchState(new PlayState('freeplay', [curSong.name], curSong.difficulties[diffSelInt]));
                canSelect = false;
            } catch(e:Exception) {
                debugTrace(e, 'error');
            }
        }
    }
}
