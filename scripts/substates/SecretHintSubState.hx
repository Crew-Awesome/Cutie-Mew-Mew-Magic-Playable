import flixel.text.FlxText.FlxTextBorderStyle;

var dialogueBox:FlxSprite;
var dialogueBorders:Array<FlxSprite> = [];
var dialogueText:FlxText;
var dialogueHint:FlxText;
var dialogueLines:Array<String> = [
    '* The man who speaks in hands told me that,',
    '* if I go too way high or low,',
    '* I will find my way to him.',
    '- Freeplay Menu'
];
var dialogueLine:Int = 0;
var dialogueIndex:Int = 0;
var dialogueTimer:Float = 0;
var dialogueDelay:Float = 0.02;
var dialogueFinished:Bool = false;
var dialogueBlipCooldown:Float = 0;
var ready:Bool = false;

function postCreate()
{
    dialogueBox = new FlxSprite(60, FlxG.height + 20);
    dialogueBox.makeGraphic(FlxG.width - 120, 215, FlxColor.BLACK);
    dialogueBox.scrollFactor.set();
    dialogueBox.camera = subCamera;
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
        border.camera = subCamera;
        add(border);
    }

    dialogueText = new FlxText(dialogueBox.x + 46, dialogueBox.y + 34, dialogueBox.width - 92, '', 34);
    dialogueText.font = Paths.font('deltarune.ttf');
    dialogueText.color = FlxColor.WHITE;
    dialogueText.borderStyle = FlxTextBorderStyle.NONE;
    dialogueText.scrollFactor.set();
    dialogueText.camera = subCamera;
    add(dialogueText);

    dialogueHint = new FlxText(0, dialogueBox.y + dialogueBox.height - 42, FlxG.width, 'Z / ENTER: Continue    X / ESC: Skip', 19);
    dialogueHint.font = Paths.font('deltarune.ttf');
    dialogueHint.color = 0xFFBFBFBF;
    dialogueHint.alignment = 'center';
    dialogueHint.scrollFactor.set();
    dialogueHint.camera = subCamera;
    add(dialogueHint);

    var targetY:Float = FlxG.height - dialogueBox.height - 28;
    FlxTween.tween(dialogueBox, {y: targetY}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[0], {y: targetY}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[1], {y: FlxG.height - 34}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[2], {y: targetY}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueBorders[3], {y: targetY}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueText, {y: targetY + 34}, 0.35, {ease: FlxEase.cubeOut});
    FlxTween.tween(dialogueHint, {y: targetY + dialogueBox.height - 42}, 0.35, {ease: FlxEase.cubeOut});

    FlxTimer.wait(0.35, function()
    {
        ready = true;
    });
}

function onUpdate(elapsed:Float)
{
    if (!ready)
        return;

    updateSecretDialogue(elapsed);
}

function updateSecretDialogue(elapsed:Float)
{
    dialogueBlipCooldown -= elapsed;

    if (!dialogueFinished)
    {
        dialogueTimer += elapsed;

        var currentLine:String = dialogueLines[dialogueLine];

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
            var fullLine:String = dialogueLines[dialogueLine];
            dialogueIndex = fullLine.length;
            dialogueText.text = fullLine;
            dialogueFinished = true;
        }
        else
        {
            dialogueLine++;

            if (dialogueLine >= dialogueLines.length)
                close();
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
        close();
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
