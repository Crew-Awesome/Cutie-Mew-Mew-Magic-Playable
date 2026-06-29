import flixel.effects.FlxFlicker;
import flixel.text.FlxText.FlxTextBorderStyle;

using StringTools;

@:typedef JsonMain = {
    var directory:String;
    var cameraSpread:Float;
    var text:String;
    var textCorner:String;
    var textMargin:Point;
    var bg:JsonSprite;
    var options:Array<JsonSprite>;
    var optionsOffset:Point;
    var optionsSpacing:Float;
    var optionsAlignment:String;
    var optionsSelectedAnimation:String;
    var optionsIdleAnimation:String;
};

var config:JsonMain = Paths.json('data/menus/main');
var bg:FlxSprite;
var options:FlxTypedGroup<FlxSprite>;
var tint:FlxSprite;
var dialogueBox:FlxSprite;
var dialogueBorders:Array<FlxSprite> = [];
var dialogueText:FlxText;
var dialogueHint:FlxText;
var dialogueActive:Bool = false;
var dialogueFinished:Bool = false;
var dialogueLines:Array<String> = [
    '* Thanks for playing my mod!',
    '* Credits are in the song intro and pause menu.',
    '* Please change your settings in the button below before playing the song.',
    '* Check difficulties before playing!',
    '- Malloy'
];
var dialogueLine:Int = 0;
var dialogueIndex:Int = 0;
var dialogueTimer:Float = 0;
var dialogueDelay:Float = 0.02;
var dialogueBlipCooldown:Float = 0;
var menuInputCooldown:Float = 0;

function playMenuMusic(id:String)
{
    if (Conductor.music != null && Save.custom.data.cutieMewMewMagicMenuMusic == id)
        return;

    Save.custom.data.cutieMewMewMagicMenuMusic = id;
    Conductor.play(Paths.music(id), CoolVars.meta.bpm);
}

function onCreate()
{
    playMenuMusic('pink');

    final path:String = 'menus/' + config.directory + '/';

    bg = CoolUtil.spriteFromJson(null, config.bg, 'menus/freeplay/');
    bg.setGraphicSize(FlxG.width, FlxG.height);
    bg.updateHitbox();
    bg.screenCenter();
    bg.scrollFactor.set();
    bg.color = 0xFFFF9DD8;
    add(bg);

    tint = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFFF73C7);
    tint.alpha = 0.28;
    tint.scrollFactor.set();
    add(tint);

    options = new FlxTypedGroup<FlxSprite>();
    add(options);

    for (index => data in config.options)
    {
        final spr = CoolUtil.spriteFromJson(null, data, path);
        spr.x = FlxG.width / 2 - spr.width / 2;
        spr.y = FlxG.height / 2 - (config.options.length * config.optionsSpacing) / 2 + index * config.optionsSpacing + config.optionsOffset.y;

        options.add(spr);
    }

    changeOption();

    if (Save.custom.data.cutieMewMewMagicIntroDialogueSeen != true)
        showIntroDialogue();
}

function showIntroDialogue()
{
    dialogueActive = true;
    canSelect = false;

    dialogueBox = new FlxSprite(60, FlxG.height + 20);
    dialogueBox.makeGraphic(FlxG.width - 120, 215, FlxColor.BLACK);
    dialogueBox.scrollFactor.set();
    add(dialogueBox);

    dialogueBorders = [
        new FlxSprite(dialogueBox.x, dialogueBox.y).makeGraphic(dialogueBox.width, 6, FlxColor.WHITE),
        new FlxSprite(dialogueBox.x, dialogueBox.y + dialogueBox.height - 6).makeGraphic(dialogueBox.width, 6, FlxColor.WHITE),
        new FlxSprite(dialogueBox.x, dialogueBox.y).makeGraphic(6, dialogueBox.height, FlxColor.WHITE),
        new FlxSprite(dialogueBox.x + dialogueBox.width - 6, dialogueBox.y).makeGraphic(6, dialogueBox.height, FlxColor.WHITE)
    ];

    for (border in dialogueBorders)
    {
        border.scrollFactor.set();
        add(border);
    }

    dialogueText = new FlxText(dialogueBox.x + 46, dialogueBox.y + 34, dialogueBox.width - 92, '', 34);
    dialogueText.font = Paths.font('deltarune.ttf');
    dialogueText.color = FlxColor.WHITE;
    dialogueText.borderStyle = FlxTextBorderStyle.NONE;
    dialogueText.scrollFactor.set();
    add(dialogueText);

    dialogueHint = new FlxText(0, dialogueBox.y + dialogueBox.height - 42, FlxG.width, 'Z / ENTER: Continue    X / ESC: Skip', 19);
    dialogueHint.font = Paths.font('deltarune.ttf');
    dialogueHint.color = 0xFFBFBFBF;
    dialogueHint.alignment = 'center';
    dialogueHint.scrollFactor.set();
    add(dialogueHint);

    FlxTween.tween(dialogueBox, {y: FlxG.height - dialogueBox.height - 28}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[0], {y: FlxG.height - dialogueBox.height - 28}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[1], {y: FlxG.height - 34}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[2], {y: FlxG.height - dialogueBox.height - 28}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[3], {y: FlxG.height - dialogueBox.height - 28}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueText, {y: FlxG.height - dialogueBox.height + 6}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueHint, {y: FlxG.height - 58}, 0.35, {ease: FlxEase.cubeOut});
}

function replayIntroDialogue()
{
    if (dialogueActive)
        return;

    dialogueLine = 0;
    dialogueIndex = 0;
    dialogueTimer = 0;
    dialogueFinished = false;
    showIntroDialogue();
}

function finishIntroDialogue()
{
    Save.custom.data.cutieMewMewMagicIntroDialogueSeen = true;
    Save.saveCustom();

    dialogueActive = false;
    canSelect = true;
    menuInputCooldown = 0.22;

    fadeDialogueObject(dialogueBox);
    for (border in dialogueBorders)
        fadeDialogueObject(border);
    fadeDialogueObject(dialogueText);
    fadeDialogueObject(dialogueHint);
}

function fadeDialogueObject(obj:Dynamic)
{
    if (obj != null)
        FlxTween.tween(obj, {alpha: 0}, 0.2, {ease: FlxEase.cubeOut, onComplete: _ -> obj.destroy()});
}

function updateIntroDialogue(elapsed:Float)
{
    if (!dialogueActive)
        return;

    dialogueBlipCooldown -= elapsed;

    if (!dialogueFinished)
    {
        dialogueTimer += elapsed;

        final currentLine:String = dialogueLines[dialogueLine];

        while (dialogueTimer >= dialogueDelay && dialogueIndex < currentLine.length)
        {
            dialogueTimer -= dialogueDelay;
            dialogueIndex++;
            dialogueText.text = currentLine.substr(0, dialogueIndex);
            playDialogueBlip(currentLine.charAt(dialogueIndex - 1));
        }

        if (dialogueIndex >= currentLine.length)
            dialogueFinished = true;
    }

    if (Controls.ACCEPT || FlxG.keys.justPressed.Z || FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
    {
        if (!dialogueFinished)
        {
            final currentLine:String = dialogueLines[dialogueLine];
            dialogueIndex = currentLine.length;
            dialogueText.text = currentLine;
            dialogueFinished = true;
        } else {
            dialogueLine++;

            if (dialogueLine >= dialogueLines.length)
                finishIntroDialogue();
            else
            {
                dialogueIndex = 0;
                dialogueTimer = 0;
                dialogueFinished = false;
                dialogueText.text = '';
            }
        }
    }

    if (Controls.BACK || FlxG.keys.justPressed.X || FlxG.keys.justPressed.ESCAPE)
        finishIntroDialogue();
}

function playDialogueBlip(char:String)
{
    if (dialogueBlipCooldown > 0)
        return;

    if (char == ' ' || char == '\n' || char == '\t')
        return;

    CoolUtil.playSound('deltarune/text_default', 0.38);
    dialogueBlipCooldown = 0.035;
}

var selInt(default, set):Int = Save.custom.data.mainMenuSelInt ??= 0;
function set_selInt(value:Int):Int
    return selInt = Save.custom.data.mainMenuSelInt = value;

function changeOption(?change:Int = 0)
{
    selInt += change;

    if (selInt < 0)
        selInt = options.members.length - 1;

    if (selInt > options.members.length - 1)
        selInt = 0;

    for (index => obj in options)
    {
        obj.playAnim(index == selInt ? config.optionsSelectedAnimation : config.optionsIdleAnimation);
        obj.centerOffsets();
    }
}

var canSelect:Bool = true;

function onUpdate(elapsed:Float)
{
    camGame.scroll.set(0, 0);

    if (menuInputCooldown > 0)
        menuInputCooldown -= elapsed;

    updateIntroDialogue(elapsed);

    if (dialogueActive)
        return;

    if (canSelect)
    {
        if (menuInputCooldown > 0)
            return;

        if (FlxG.keys.justPressed.TAB)
            replayIntroDialogue();

        if (Controls.UI_DOWN_P || Controls.UI_UP_P)
        {
            changeOption(Controls.UI_DOWN_P ? 1 : -1);
            CoolUtil.playSound('scroll');
        }

        if (Controls.ACCEPT)
        {
            canSelect = false;

            for (index => option in options)
            {
                if (index == selInt)
                {
                    FlxFlicker.flicker(option, 0, ClientPrefs.data.flashing ? 0.075 : 0.125);

                    var nextState:String = option.config.state;

                    if (nextState.startsWith('meta:'))
                        nextState = Reflect.getProperty(CoolVars.meta, nextState.substr(5));

                    FlxTimer.wait(1, function() CoolUtil.switchState(new CustomState(nextState)));
                    CoolUtil.playSound('confirm');
                } else {
                    FlxTween.tween(option, {alpha: 0.5}, 1, {ease: FlxEase.cubeOut});
                }
            }
        }

        if (Controls.BACK)
            CoolUtil.playSound('cancel');
    }
}
