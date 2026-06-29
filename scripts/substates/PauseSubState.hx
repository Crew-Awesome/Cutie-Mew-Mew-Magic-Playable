import funkin.visuals.objects.Alphabet;

@:typedef JsonPause = {
    var cameraOffset:Point;
    var optionsSpacing:Point;
    var cameraSpeed:Float;
    var infoCorner:String;
};

final config:JsonPause = Paths.json('data/menus/pause');
final play:PlayState = PlayState.instance;

var options:FlxTypedGroup<Alphabet>;
var selInt:Int = 0;

function postCreate()
{
    final bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.scrollFactor.set();
    bg.alpha = 0;
    add(bg);

    FlxTween.tween(bg, {alpha: 0.58}, 0.35, {ease: FlxEase.cubeOut});

    add(options = new FlxTypedGroup<Alphabet>());

    for (index => opt in ['resume', 'restart', 'options', 'exit'])
    {
        final text:Alphabet = new Alphabet(0, 0, opt);
        options.add(text);
        FlxTween.tween(text, {x: index * config.optionsSpacing.x, y: index * config.optionsSpacing.y}, config.cameraSpeed, {ease: FlxEase.cubeOut});
    }

    final isGaster:Bool = play.song == 'gaster-theme';
    final info:Array<String> = isGaster ? [
        "Song: Gaster's Theme",
        'Difficulty: ' + play.difficulty,
        play.type == 'story' ? 'Story Mode' : 'Freeplay',
        'Artist: Toby Fox',
        'Chart: Paperzi',
        'Coding/Mod: Malloy'
    ] : [
        'Song: Cutie Mew Mew Magic',
        'Difficulty: ' + play.difficulty,
        play.type == 'story' ? 'Story Mode' : 'Freeplay',
        'Artist: Toby Fox',
        'Chart: Gabri_JJBAxd',
        'Coding/Mod: Malloy',
        'ModChart: Nezumieepy'
    ];

    for (index => txt in info)
    {
        final text:FlxText = new FlxText(FlxG.width, 10 + 25 * index, 0, txt, 24);
        text.font = Paths.font('vcr.ttf');
        text.camera = subCamera;
        text.scrollFactor.set();
        text.alpha = 0;
        add(text);

        FlxTween.tween(text, {x: FlxG.width - 19 - text.width, alpha: 1}, 0.45, {ease: FlxEase.cubeOut, startDelay: index * 0.06});
    }

    for (obj in members)
        obj.camera = subCamera;

    changeOption();
}

function changeOption(?change:Int = 0)
{
    selInt += change;

    if (selInt < 0)
        selInt = options.members.length - 1;

    if (selInt > options.members.length - 1)
        selInt = 0;

    for (index => opt in options)
        opt.alpha = selInt == index ? 1 : 0.5;
}

function onUpdate(elapsed:Float)
{
    subCamera.scroll.x = CoolUtil.fpsLerp(subCamera.scroll.x, selInt * config.optionsSpacing.x + config.cameraOffset.x, config.cameraSpeed);
    subCamera.scroll.y = CoolUtil.fpsLerp(subCamera.scroll.y, selInt * config.optionsSpacing.y + config.cameraOffset.y, config.cameraSpeed);

    if (Controls.UI_DOWN_P || Controls.UI_UP_P)
    {
        changeOption(Controls.UI_DOWN_P ? 1 : -1);
        CoolUtil.playSound('scroll');
    }

    if (Controls.ACCEPT)
    {
        switch (options.members[selInt].text)
        {
            case 'restart':
                play.restart();
                close();

            case 'options':
                close();
                CoolUtil.switchState(new CustomState(CoolVars.meta.optionsState));

            case 'exit':
                play.exit();
                close();

            default:
                play.resume();
                close();
        }
    }
}
