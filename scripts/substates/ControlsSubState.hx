import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText.FlxTextBorderStyle;

var bg:FlxSprite;
var title:FlxText;
var helpText:FlxText;
var rows:Array<Dynamic> = [];
var rowTexts:Array<FlxText> = [];
var selInt:Int = 0;
var slotInt:Int = 0;
var waitingForKey:Bool = false;
var captureDelay:Float = 0;
var canSelect:Bool = true;

function postCreate()
{
    bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    bg.alpha = 0;
    bg.scrollFactor.set();
    bg.camera = subCamera;
    add(bg);

    FlxTween.tween(bg, {alpha: 0.82}, 0.25, {ease: FlxEase.cubeOut});

    title = new FlxText(0, 22, FlxG.width, 'CONTROLS', 38);
    title.setFormat(Paths.font('vcr.ttf'), 38, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    title.borderSize = 1.5;
    title.scrollFactor.set();
    title.camera = subCamera;
    add(title);

    helpText = new FlxText(0, FlxG.height - 66, FlxG.width, 'UP/DOWN: Select    LEFT/RIGHT: Slot    ENTER: Rebind    BACKSPACE: Clear    R: Reset    ESC: Save + Back', 18);
    helpText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, 'center', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    helpText.borderSize = 1.25;
    helpText.scrollFactor.set();
    helpText.camera = subCamera;
    add(helpText);

    buildRows();
    drawRows();
    updateSelection();
}

function addCategory(name:String)
{
    rows.push({category: true, label: name});
}

function addAction(group:String, field:String, label:String)
{
    rows.push({category: false, group: group, field: field, label: label});
}

function buildRows()
{
    rows = [];

    addCategory('NOTES');
    addAction('notes', 'left', 'Note Left');
    addAction('notes', 'down', 'Note Down');
    addAction('notes', 'up', 'Note Up');
    addAction('notes', 'right', 'Note Right');

    addCategory('UI');
    addAction('ui', 'left', 'Menu Left');
    addAction('ui', 'down', 'Menu Down');
    addAction('ui', 'up', 'Menu Up');
    addAction('ui', 'right', 'Menu Right');
    addAction('ui', 'accept', 'Accept');
    addAction('ui', 'back', 'Back');
    addAction('ui', 'reset', 'Reset');
    addAction('ui', 'pause', 'Pause');
    addAction('ui', 'mute', 'Mute');
    addAction('ui', 'volume_up', 'Volume Up');
    addAction('ui', 'volume_down', 'Volume Down');

    addCategory('ENGINE');
    addAction('engine', 'chart', 'Chart Editor');
    addAction('engine', 'character', 'Character Editor');
    addAction('engine', 'switch_mod', 'Switch Mod');
    addAction('engine', 'reset_game', 'Reset Game');
    addAction('engine', 'master_menu', 'Master Menu');
    addAction('engine', 'fps_counter', 'FPS Counter');

    normalizeSelection();
}

function drawRows()
{
    for (text in rowTexts)
    {
        remove(text);
        text.destroy();
    }

    rowTexts = [];

    for (index => row in rows)
    {
        final text = new FlxText(0, 98 + index * 36, FlxG.width, rowText(row), row.category ? 24 : 22);
        text.setFormat(Paths.font('vcr.ttf'), row.category ? 24 : 22, row.category ? 0xFFFF9DD8 : FlxColor.WHITE, row.category ? 'center' : 'left', FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        text.borderSize = 1.25;
        text.scrollFactor.set();
        text.camera = subCamera;

        if (!row.category)
            text.x = 160;

        add(text);
        rowTexts.push(text);
    }
}

function rowText(row:Dynamic):String
{
    if (row.category)
        return row.label;

    final keys:Array<Null<Int>> = getKeys(row.group, row.field);

    return padRight(row.label, 20) + slotText(keys, 0) + '    ' + slotText(keys, 1);
}

function padRight(value:String, length:Int):String
{
    while (value.length < length)
        value += ' ';

    return value;
}

function slotText(keys:Array<Null<Int>>, index:Int):String
{
    final selected:String = index == slotInt ? '>' : ' ';
    final key:Null<Int> = keys != null && keys.length > index ? keys[index] : null;

    return selected + '[' + keyName(key) + ']';
}

function keyName(key:Null<Int>):String
{
    if (key == null || key == 0)
        return 'NONE';

    final name = FlxKey.toStringMap.get(key);

    return name == null ? Std.string(key) : name;
}

function getGroup(group:String):Dynamic
{
    var controlsGroup:Dynamic = Reflect.field(ClientPrefs.controls, group);

    if (controlsGroup == null)
    {
        controlsGroup = {};
        Reflect.setField(ClientPrefs.controls, group, controlsGroup);
    }

    return controlsGroup;
}

function getKeys(group:String, field:String):Array<Null<Int>>
{
    final controlsGroup:Dynamic = getGroup(group);
    var keys:Array<Null<Int>> = cast Reflect.field(controlsGroup, field);

    if (keys == null)
    {
        keys = [null, null];
        Reflect.setField(controlsGroup, field, keys);
    }

    while (keys.length < 2)
        keys.push(null);

    return keys;
}

function setKey(group:String, field:String, slot:Int, key:Null<Int>)
{
    final keys = getKeys(group, field);
    keys[slot] = key;
    Reflect.setField(getGroup(group), field, keys);
    Save.save();
}

function defaultKeys(group:String, field:String):Array<Null<Int>>
{
    switch (group + '.' + field)
    {
        case 'notes.left': return [FlxKey.A, FlxKey.LEFT];
        case 'notes.down': return [FlxKey.S, FlxKey.DOWN];
        case 'notes.up': return [FlxKey.W, FlxKey.UP];
        case 'notes.right': return [FlxKey.D, FlxKey.RIGHT];
        case 'ui.left': return [FlxKey.A, FlxKey.LEFT];
        case 'ui.down': return [FlxKey.S, FlxKey.DOWN];
        case 'ui.up': return [FlxKey.W, FlxKey.UP];
        case 'ui.right': return [FlxKey.D, FlxKey.RIGHT];
        case 'ui.accept': return [FlxKey.ENTER, FlxKey.SPACE];
        case 'ui.back': return [FlxKey.ESCAPE, null];
        case 'ui.reset': return [FlxKey.R, FlxKey.F5];
        case 'ui.pause': return [FlxKey.ENTER, FlxKey.ESCAPE];
        case 'ui.mute': return [FlxKey.ZERO, null];
        case 'ui.volume_up': return [FlxKey.PLUS, null];
        case 'ui.volume_down': return [FlxKey.MINUS, null];
        case 'engine.chart': return [FlxKey.SEVEN, null];
        case 'engine.character': return [FlxKey.EIGHT, null];
        case 'engine.switch_mod': return [FlxKey.M, null];
        case 'engine.reset_game': return [FlxKey.N, null];
        case 'engine.master_menu': return [FlxKey.SEVEN, null];
        case 'engine.fps_counter': return [FlxKey.F3, null];
        default: return [null, null];
    }
}

function resetDefaults()
{
    for (row in rows)
    {
        if (row.category)
            continue;

        Reflect.setField(getGroup(row.group), row.field, defaultKeys(row.group, row.field));
    }

    Save.save();
    drawRows();
    updateSelection();
}

function normalizeSelection()
{
    if (rows.length <= 0)
        return;

    if (selInt < 0)
        selInt = rows.length - 1;

    if (selInt > rows.length - 1)
        selInt = 0;

    while (rows[selInt].category)
        selInt = (selInt + 1) % rows.length;
}

function changeSelection(change:Int)
{
    selInt += change;
    normalizeSelection();
    updateSelection();
    CoolUtil.playSound('scroll');
}

function updateSelection()
{
    for (index => text in rowTexts)
    {
        final row = rows[index];

        text.text = rowText(row);
        text.alpha = row.category || index == selInt ? 1 : 0.45;
        text.color = row.category ? 0xFFFF9DD8 : (index == selInt ? FlxColor.WHITE : 0xFFBFBFBF);
    }

    final selected = rows[selInt];
    helpText.text = waitingForKey
        ? 'Press a key for ' + selected.label + ' slot ' + (slotInt + 1) + '... ESC cancels'
        : 'UP/DOWN: Select    LEFT/RIGHT: Slot    ENTER: Rebind    BACKSPACE: Clear    R: Reset    ESC: Save + Back';
}

function onUpdate(elapsed:Float)
{
    if (!canSelect)
        return;

    subCamera.scroll.y = CoolUtil.fpsLerp(subCamera.scroll.y, selInt * 36 - 180, 0.25);

    if (waitingForKey)
    {
        captureDelay -= elapsed;

        if (captureDelay > 0)
            return;

        if (FlxG.keys.justPressed.ESCAPE)
        {
            waitingForKey = false;
            updateSelection();
            return;
        }

        if (FlxG.keys.justPressed.ANY)
        {
            final key:Int = FlxG.keys.firstJustPressed();
            final row = rows[selInt];

            setKey(row.group, row.field, slotInt, key);
            waitingForKey = false;
            updateSelection();
            CoolUtil.playSound('confirm');
        }

        return;
    }

    if (Controls.BACK || FlxG.keys.justPressed.ESCAPE)
    {
        canSelect = false;
        Save.save();
        CoolUtil.playSound('cancel');
        close();
        return;
    }

    if (Controls.UI_DOWN_P || FlxG.keys.justPressed.DOWN)
        changeSelection(1);

    if (Controls.UI_UP_P || FlxG.keys.justPressed.UP)
        changeSelection(-1);

    if (Controls.UI_LEFT_P || Controls.UI_RIGHT_P || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
    {
        slotInt = 1 - slotInt;
        updateSelection();
        CoolUtil.playSound('scroll');
    }

    if (FlxG.keys.justPressed.BACKSPACE)
    {
        final row = rows[selInt];
        setKey(row.group, row.field, slotInt, null);
        updateSelection();
        CoolUtil.playSound('cancel');
    }

    if (FlxG.keys.justPressed.R)
        resetDefaults();

    if (Controls.ACCEPT || FlxG.keys.justPressed.ENTER)
    {
        waitingForKey = true;
        captureDelay = 0.12;
        updateSelection();
        CoolUtil.playSound('confirm');
    }
}
