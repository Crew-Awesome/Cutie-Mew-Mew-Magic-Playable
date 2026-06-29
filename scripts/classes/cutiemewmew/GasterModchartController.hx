package cutiemewmew;

import funkin.config.ClientPrefs;
import funkin.states.PlayState;
import flixel.FlxG;
import modcharting.ModchartManager;
import modcharting.modifiers.modifiers.GasterSineModifier;

class GasterModchartController
{
    var manager:ModchartManager;
    var sine:GasterSineModifier;

    public function new() {}

    function play():PlayState
        return PlayState.instance;

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
        sine = new GasterSineModifier();
        manager.prepareMod('gasterSine', function()
        {
            return sine;
        }, -1, -1);

        sync();

        final targetIndex:Int = state.strumLines == null ? -1 : state.members.indexOf(state.strumLines);
        if (targetIndex >= 0)
            state.insert(targetIndex, manager);
        else
            state.add(manager);
    }

    public function update()
    {
        centerPlayerStrumLine();
        sync();
    }

    function sync()
    {
        if (sine == null)
            return;

        sine.value = enabled() ? 1 : 0;
        sine.markDirty();
    }

    function centerPlayerStrumLine()
    {
        final state = play();
        if (state == null || state.playerStrumLines == null || state.playerStrumLines.members == null)
            return;

        final line = state.playerStrumLines.members[0];
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
}
