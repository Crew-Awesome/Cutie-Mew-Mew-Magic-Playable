import FPSCounter;

HotReloading.add('scripts/classes/FPSCounter.hx');

FlxG.game.debugTray?.destroy();

FlxG.stage.addChild(FlxG.game.debugTray = new FPSCounter());

CoolUtil.switchState(new CustomState(CoolVars.meta.titleState), true, true);