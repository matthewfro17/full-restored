package meta.state;

#if debug
import haxeplus.Debugger;
#end

import ui.*;
import reactor.*;
import controls.*;
import openfl.utils.Assets;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import flixel.group.FlxSpriteGroup;
import flixel.ui.FlxButton;
import flixel.addons.editors.ogmo.FlxOgmo3Loader.Point;
import flixel.system.debug.FlxDebugger;
import extension.admob.AdMob;
import ui.FlxVirtualPad.FlxActionMode;
import ui.FlxVirtualPad.FlxDPadMode;
import ui.Controller;
import fmf.characters.*;
import fmf.songs.*;
import flixel.input.keyboard.FlxKey;
import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import flixel.system.FlxAssets;
import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;
import openfl.Lib;
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
// custom transition data
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
#if sys
import Sys;
import sys.FileSystem;
#end

using StringTools;

class GameState extends MusicBeatState
{
	public static var noteTypeList:Array<String> = // Used for backwards compatibility with 0.1 - 0.3.2 charts, though, you should add your hardcoded custom note types here too.
		['', 'Alt Animation', 'Hey!', 'Hurt Note', 'GF Sing', 'No Animation'];


	// Lua and Psych engine friends
	//-------------------------------------------------
	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	function sortByTime(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		var earlyTime1:Float = eventNoteEarlyTrigger(Obj1);
		var earlyTime2:Float = eventNoteEarlyTrigger(Obj2);
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0] - earlyTime1, Obj2[0] - earlyTime2);
	}

	function lightsEvent(value1:String)
	{
		var lightId:Int = Std.parseInt(value1);
		if(Math.isNaN(lightId)) lightId = 0;

		if(lightId > 0 && curLightEvent != lightId) {
			if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

			var color:Int = 0xffffffff;
			switch(lightId) {
				case 1: //Blue
					color = 0xff31a2fd;
				case 2: //Green
					color = 0xff31fd8c;
				case 3: //Pink
					color = 0xfff794f7;
				case 4: //Red
					color = 0xfff96d63;
				case 5: //Orange
					color = 0xfffba633;
			}
			curLightEvent = lightId;

			if (blammedLightsBlack.alpha == 0)
			{
				if (blammedLightsBlackTween != null)
				{
					blammedLightsBlackTween.cancel();
				}
				blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween)
					{
						blammedLightsBlackTween = null;
					}
				});

					var chars:Array<Character> = [dadPE, gfPE, player3, bfPE, bfFE(), dadFE(), gfFE()];
				
					for (i in 0...chars.length)
					{
						if (chars[i] == null)
							continue;

						if (chars[i].colorTween != null)
						{
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {
							onComplete: function(twn:FlxTween)
							{
								chars[i].colorTween = null;
							},
							ease: FlxEase.quadInOut
						});
					}
			}
			else
			{
				if (blammedLightsBlackTween != null)
				{
					blammedLightsBlackTween.cancel();
				}
				blammedLightsBlackTween = null;
				blammedLightsBlack.alpha = 1;

				var chars:Array<Character> = [dadPE, gfPE, bfPE, player3, bfFE(), dadFE(), gfFE()];
				for (i in 0...chars.length)
				{
					//skip shit
					if (chars[i] == null)
						continue;
					
					if (chars[i].colorTween != null)
					{
						chars[i].colorTween.cancel();
					}
					chars[i].colorTween = null;
				}

				for (i in 0...chars.length)
				{
					// skip shit
					if (chars[i] == null)
						continue;

					chars[i].color = color;
				}
					// dadPE.color = color;
					// bfPE.color = color;
					// gfPE.color = color;
			}

			if (curStage == 'philly')
			{
				if (phillyCityLightsEvent != null)
				{
					phillyCityLightsEvent.forEach(function(spr:BGSprite)
					{
						spr.visible = false;
					});
					phillyCityLightsEvent.members[lightId - 1].visible = true;
					phillyCityLightsEvent.members[lightId - 1].alpha = 1;
				}
			}
		}
		else
		{
			if (blammedLightsBlack.alpha != 0)
			{
				if (blammedLightsBlackTween != null)
				{
					blammedLightsBlackTween.cancel();
				}
				blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {
					ease: FlxEase.quadInOut,
					onComplete: function(twn:FlxTween)
					{
						blammedLightsBlackTween = null;
					}
				});
			}

			// if(curStage == 'philly') {
			// 	phillyCityLights.forEach(function(spr:BGSprite) {
			// 		spr.visible = false;
			// 	});
			// 	phillyCityLightsEvent.forEach(function(spr:BGSprite) {
			// 		spr.visible = false;
			// 	});

			// 	var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
			// 	if(memb != null) {
			// 		memb.visible = true;
			// 		memb.alpha = 1;
			// 		if(phillyCityLightsEventTween != null)
			// 			phillyCityLightsEventTween.cancel();

			// 		phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
			// 			phillyCityLightsEventTween = null;
			// 		}, ease: FlxEase.quadInOut});
			// 	}
			// }

			var chars:Array<Character> = [dadPE, gfPE, bfPE, player3, bfFE(), dadFE(), gfFE()];
			for (i in 0...chars.length)
			{
				if (chars[i] == null)
					continue;
				
				if (chars[i].colorTween != null)
				{
					chars[i].colorTween.cancel();
				}
				chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
					chars[i].colorTween = null;
				}, ease: FlxEase.quadInOut});
			}

			curLight = 0;
			curLightEvent = 0;
		}
	}
	public function checkEventNote()
	{
		while (eventNotes.length > 0)
		{
			var early:Float = eventNoteEarlyTrigger(eventNotes[0]);
			
			var leStrumTime:Float = eventNotes[0][0];

			#if debug
			// leStrumTime = eventNotes[0][0] / 5;
			#end

			if (Conductor.songPosition < leStrumTime - early)
			{
				break;
			}

			var eventValue = Std.parseInt(eventNotes[0][1]);

			if (eventValue == -1)
			{
				// old event detected
				var value1:String = '';
				if (eventNotes[0][3] != null)
					value1 = eventNotes[0][3];

				var value2:String = '';
				if (eventNotes[0][4] != null)
					value2 = eventNotes[0][4];

				trace("triggerEventNote[ " + leStrumTime + ']' + eventNotes[0][2] + " with args: " + value1 + ", " + value2);
				triggerEventNote(eventNotes[0][2], value1, value2);
			}
			else
			{
				// this is new event system
				var value1:String = '';
				if (eventNotes[0][2] != null)
					value1 = eventNotes[0][2];

				var value2:String = '';
				if (eventNotes[0][3] != null)
					value2 = eventNotes[0][3];

				trace("triggerEventNote " + eventNotes[0][1] + " with args: " + value1 + ", " + value2);
				triggerEventNote(eventNotes[0][1], value1, value2);
			}

			eventNotes.shift();
		}
	}

	function eventPushed(event:Array<Dynamic>)
	{
		switch (event[2])
		{
			case 'Change Character':
				var charType:Int = 0;
				switch (event[3].toLowerCase())
				{
					case 'boyfriend' | 'bf' | '0':
						charType = 0;
					case 'player3' | '3':
						charType = 3;
					case 'gf' | 'girlfriend' | '2':
						charType = 2;
					case 'dad' | 'opponent' | '1':
						charType = 1;
					default:
						charType = Std.parseInt(event[3]);
						if (Math.isNaN(charType)) charType = 0;
				}
				var newCharacter:String = event[4];
				addCharacterToList(newCharacter, charType);

			default:
				var evKey = Std.parseInt(event[1]);
				switch (event[1])
				{
					case 'Change Character':
						var charType:Int = 0;
						switch (event[2].toLowerCase())
						{
							case 'boyfriend' | 'bf' | '0':
								charType = 0;
							case 'player3' | '3':
								charType = 3;
							case 'gf' | 'girlfriend' | '2':
								charType = 2;
							case 'dad' | 'opponent' | '1':
								charType = 1;
							default:
								charType = Std.parseInt(event[2]);
								if (Math.isNaN(charType)) charType = 0;
						}
						var newCharacter:String = event[3];
						addCharacterToList(newCharacter, charType);
				}

				if ((Math.isNaN(evKey) || evKey != -1) && !eventPushedMap.exists(event[1]))
				{
					trace('Pushed event: ' + event[1]);
					eventPushedMap.set(event[1], true);
				}
		}
	}

	function eventNoteEarlyTrigger(event:Array<Dynamic>):Float
	{
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event[2]]);
		if (returnedValue != 0)
		{
			return returnedValue;
		}

		switch (event[2])
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}
		return 0;
	}

	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var luaArray:Array<FunkinLua> = [];

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var introSoundsSuffix:String = '';
	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	var curLight:Int = 0;
	var curLightEvent:Int = 0;

	public static function createLua(luaFile:String)
	{
		var lua = new FunkinLua(luaFile);
		instance.luaArray.push(lua);
		// lime.app.Application.current.window.alert(luaFile, 'Create Lua');
		lua.call('onCreate', []);
	}

	public static function createLuas(luaFiles:Array<String>)
	{
		var luas:Array<FunkinLua> = [];
		for (luaFile in luaFiles)
		{
			var lua = new FunkinLua(luaFile);
			luas.push(lua);
			instance.luaArray.push(lua);
			// lime.app.Application.current.window.alert(luaFile, 'Create Lua');
			lua.call('onCreate', []);
		}
	}

	// You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		// // TO DO: Make this more flexible, maybe?
		// if(dialogueFile.dialogue.length > 0) {
		// 	inCutscene = true;
		// 	CoolUtil.precacheSound('dialogue');
		// 	CoolUtil.precacheSound('dialogueClose');
		// 	var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
		// 	doof.scrollFactor.set();
		// 	if(endingSong) {
		// 		doof.finishThing = endSong;
		// 	} else {
		// 		doof.finishThing = startCountdown;
		// 	}
		// 	doof.nextDialogueThing = startNextDialogue;
		// 	doof.skipDialogueThing = skipDialogue;
		// 	doof.cameras = [camHUD];
		// 	add(doof);
		// } else {
		// 	FlxG.log.warn('Your dialogue file is badly formatted!');
		// 	if(endingSong) {
		// 		endSong();
		// 	} else {
		// 		startCountdown();
		// 	}
		// }
	}

	function startCharacterPos(char:CharacterPE, ?gfCheck:Bool = false)
	{
		if (char == null)
		{
			trace('Null character!');
			return;
		}

		if (gfCheck && char.curCharacter.startsWith('gf'))
		{ // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function KillNotes()
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public function moveCamera(isDad:Bool)
	{
		// Todo
		// if (isDad)
		// {
		// 	camFollow.set(dadPE.getMidpoint().x + 150, dadPE.getMidpoint().y - 100);
		// 	camFollow.x += dadPE.cameraPosition[0];
		// 	camFollow.y += dadPE.cameraPosition[1];
		// 	// tweenCamIn();
		// }
		// else
		// {
		// 	camFollow.set(bfPE.getMidpoint().x - 100, bfPE.getMidpoint().y - 100);

		// 	camFollow.x -= bfPE.cameraPosition[0];
		// 	camFollow.y += bfPE.cameraPosition[1];

		// 	// if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
		// 	// {
		// 	// 	cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {
		// 	// 		ease: FlxEase.elasticInOut,
		// 	// 		onComplete: function(twn:FlxTween)
		// 	// 		{
		// 	// 			cameraTwn = null;
		// 	// 		}
		// 	// 	});
		// 	// }
		// }
	}

	function startCharacterLua(name:String)
	{
		// todo

		// #if LUA_ALLOWED
		// var doPush:Bool = false;
		// var luaFile:String = 'characters/' + name + '.lua';
		// if(FileSystem.exists(Paths.modFolders(luaFile))) {
		// 	luaFile = Paths.modFolders(luaFile);
		// 	doPush = true;
		// } else {
		// 	luaFile = Paths.getPreloadPath(luaFile);
		// 	if(FileSystem.exists(luaFile)) {
		// 		doPush = true;
		// 	}
		// }

		// if(doPush)
		// {
		// 	for (lua in luaArray)
		// 	{
		// 		if(lua.scriptName == luaFile) return;
		// 	}
		// 	luaArray.push(new FunkinLua(luaFile));
		// }
		// #end
	}

	public function addCharacterToList(newCharacter:String, type:Int)
	{
		switch (type)
		{
			case 0:
				if (!boyfriendMap.exists(newCharacter))
				{
					trace('add new bf: ' + newCharacter);
					var newBoyfriend:BoyfriendPE = new BoyfriendPE(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					newBoyfriend.alreadyLoaded = false;
					startCharacterLua(newBoyfriend.curCharacter);

					// turn on for debug
					#if debug
					// newBoyfriend.visible = true;
					// newBoyfriend.alpha = 1;
					#end
				}

			case 1:
				if (!dadMap.exists(newCharacter))
				{
					trace('add new dad: ' + newCharacter);
					var newDad:CharacterPE = new CharacterPE(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					newDad.alreadyLoaded = false;
					startCharacterLua(newDad.curCharacter);

					// turn on for debug
					#if debug
					// newDad.visible = true;
					// newDad.alpha = 1;
					#end
				}

			case 2:
				if (!gfMap.exists(newCharacter))
				{
					trace('add new gf: ' + newCharacter);
					var newGf:CharacterPE = new CharacterPE(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					newGf.alreadyLoaded = false;
					startCharacterLua(newGf.curCharacter);

					// turn on for debug
					#if debug
					// newGf.visible = true;
					// newGf.alpha = 1;
					#end
				}

			case 3:
				if (!player3Map.exists(newCharacter))
				{
					trace('add new player3: ' + newCharacter);

					var newPlayer3:CharacterPE = new CharacterPE(0, 0, newCharacter);
					player3Map.set(newCharacter, newPlayer3);
					player3Group.add(newPlayer3);
					startCharacterPos(newPlayer3);
					newPlayer3.alpha = 0.00001;
					newPlayer3.alreadyLoaded = false;
					startCharacterLua(newPlayer3.curCharacter);

					// turn on for debug
					// 	newPlayer3.visible = true;
					// 	newPlayer3.alpha = 1;
				}
		}
	}

	public function RecalculateRating()
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) // Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				// trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if (ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0)
				ratingFC = "SFC";
			if (goods > 0)
				ratingFC = "GFC";
			if (bads > 0 || shits > 0)
				ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10)
				ratingFC = "SDCB";
			else if (songMisses >= 10)
				ratingFC = "Clear";
		}

		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	public function addTextToDebug(text:String)
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText)
		{
			spr.y += 20;
		});
		luaDebugGroup.add(new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function getControl(key:String)
	{
		var pressed:Bool = Reflect.getProperty(controls, key);
		// trace('Control result: ' + pressed);
		return pressed;
	}

	public function setOnLuas(variable:String, arg:Dynamic)
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			luaArray[i].set(variable, arg);
		}
		#end
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String)
	{
		// trace('trigger event: ' + eventName);
		switch (eventName)
		{
			case 'Hey!':

			// var value:Int = 0;
			// switch (value1.toLowerCase().trim())
			// {
			// 	case 'bf' | 'boyfriend' | '0':
			// 		value = 0;

			// 	case 'gf' | 'girlfriend' | '1':
			// 		value = 1;

			// 	case 'dad' | '2':
			// 		value = 2;

			// 	case 'player3' | '3':
			// 		value = 3;
			// }

			// var time:Float = Std.parseFloat(value2);
			// if(Math.isNaN(time) || time <= 0) time = 0.6;

			// if(value != 0) {
			// 	if(dadPE.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
			// 		dadPE.playAnim('cheer', true);
			// 		dadPE.specialAnim = true;
			// 		dadPE.heyTimer = time;
			// 	} else {
			// 		gfPE.playAnim('cheer', true);
			// 		gfPE.specialAnim = true;
			// 		gfPE.heyTimer = time;
			// 	}

			// 	if(curStage == 'mall') {
			// 		// bottomBoppers.animation.play('hey', true);
			// 		// heyTimer = time;
			// 	}
			// }
			// if(value != 1) {
			// 	bfPE.playAnim('hey', true);
			// 	bfPE.specialAnim = true;
			// 	bfPE.heyTimer = time;
			// }

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if (Math.isNaN(value))
					value = 1;
				gfSpeed = value;

			case 'Blammed Lights':
				lightsEvent(value1);

			case 'Kill Henchmen':
			// killHenchmen();

			case 'Add Camera Zoom':
			// ClientPrefs.camZooms
			// if(true && FlxG.camera.zoom < 1.35) {
			// 	var camZoom:Float = Std.parseFloat(value1);
			// 	var hudZoom:Float = Std.parseFloat(value2);
			// 	if(Math.isNaN(camZoom)) camZoom = 0.015;
			// 	if(Math.isNaN(hudZoom)) hudZoom = 0.03;

			// 	FlxG.camera.zoom += camZoom;
			// 	camHUD.zoom += hudZoom;
			// }

			case 'Trigger BG Ghouls':
			// shet !ClientPrefs.lowQuality
			// if(curStage == 'schoolEvil' && true) {
			// 	// bgGhouls.dance(true);
			// 	// bgGhouls.visible = true;
			// }

			case 'Lock Animation':
				var playerShit:Int = 0;

				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						playerShit = 1;

					case 'dad' | 'opponent':
						playerShit = 0;

					case 'gf' | 'girlfriend':
						playerShit = 2;

					case 'player3':
						playerShit = 3;

					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) playerShit = 0;
				}


				switch (playerShit)
				{
					case 1:
						if (bf != null)
						{
							bf.playAnim(value1, true);
							bf.isLockAnim = true;
						}

					case 0:
						if (dad != null)
						{
							dad.playAnim(value1, true);
							dad.isLockAnim = true;
						}
					case 2:
						if (gf != null)
						{
							gf.playAnim(value1, true);
							gf.isLockAnim = true;
						}

					case 3:
						if (player3 != null) 
						{
							player3.playAnim(value1, true);
							player3.isLockAnim = true;
						}
					
				}

			case 'Unlock Animation':
								var playerShit:Int = 0;

			switch (value2.toLowerCase().trim())
			{
				case 'bf' | 'boyfriend':
					playerShit = 1;

				case 'dad' | 'opponent':
					playerShit = 0;

				case 'gf' | 'girlfriend':
					playerShit = 2;

				case 'player3':
					playerShit = 3;

				default:
					var val2:Int = Std.parseInt(value2);
					if (Math.isNaN(val2)) playerShit = 0;
			}

			switch (playerShit)
			{
				case 1:
					if (bf != null) bf.isLockAnim = false;

				case 0:
					if (dad != null) dad.isLockAnim = false;
				
				case 2:
					if (gf != null) gf.isLockAnim = false;

				case 3:
					if (player3 != null) player3.isLockAnim = false;
				
			}

			// trace(
			case 'Play Animation':
				// todo
				// create enum shit
				var playerShit:Int = 0;

				switch (value2.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend':
						playerShit = 1;

					case 'dad' | 'opponent':
						playerShit = 0;

					case 'gf' | 'girlfriend':
						playerShit = 2;

					case 'player3':
						playerShit = 3;

					default:
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) playerShit = 0;
				}

				switch (playerShit)
				{
					case -1:
						{
							songPlayer.playAnimation(value1);
						}
					case 1:
						if (bfPE != null)
						{
							bfPE.playAnim(value1, true);
							bfPE.specialAnim = true;
						}
						if (songPlayer.bf != null)
						{
							// todo
							// play anim force.
							songPlayer.bf.playAnim(value1, true);
						}

					case 0:
						if (dadPE != null)
						{
							dadPE.playAnim(value1, true);
							dadPE.specialAnim = true;
						}
						if (songPlayer.dad != null)
						{
							// todo
							// play anim force.
							songPlayer.dad.playAnim(value1, true);
						}

					case 2:
						if (gfPE != null)
						{
							gfPE.playAnim(value1, true);
							gfPE.specialAnim = true;
						}
						if (songPlayer.gf != null)
						{
							// todo
							// play anim force.
							songPlayer.gf.playAnim(value1, true);
						}

					case 3:
						player3.playAnim(value1, true);
						player3.specialAnim = true;
				}

			// trace('trim: ' + value2.toLowerCase().trim());

			// char.playAnim(value1, true);
			// char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = targetCamFollow.x;
				if (Math.isNaN(val2))
					val2 = targetCamFollow.y;

				isCameraOnForcedPos = false;
				if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
				{
					isCameraOnForcedPos = true;
					setCamFollowPosition(val1, val2);
					// camFollow.setPosition(val1, val2);
				}

				// trace('shit');

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = bf;
					default:
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val))
							val = 0;

						switch (val)
						{
							case 1: char = bf;
							case 2: char = gf;
						}
				}
				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if (split[0] != null)
						duration = Std.parseFloat(split[0].trim());
					if (split[1] != null)
						intensity = Std.parseFloat(split[1].trim());
					if (Math.isNaN(duration))
						duration = 0;
					if (Math.isNaN(intensity))
						intensity = 0;

					if (duration > 0 && intensity != 0)
					{
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;

				switch (value1)
				{
					case 'player3':
						charType = 3;
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				switch (charType)
				{
					case 0:
						// Todo
						// if(bfPE.curCharacter != value2) {
						if (!boyfriendMap.exists(value2))
						{
							addCharacterToList(value2, charType);
						}

						if (bfPE != null)
							bfPE.visible = false;

						if (songPlayer.bf != null && songPlayer.bf.visible)
							songPlayer.bf.visible = false;

						bfPE = boyfriendMap.get(value2);

						if (!bfPE.alreadyLoaded)
						{
							bfPE.alpha = 1;
							bfPE.alreadyLoaded = true;
						}

						bfPE.visible = true;
						setOnLuas('boyfriendName', bfPE.curCharacter);

					case 1:
						// if(dadPE.curCharacter != value2) {
						if (!dadMap.exists(value2))
						{
							addCharacterToList(value2, charType);
						}

						// todo
						// var wasGf:Bool = dadPE.curCharacter.startsWith('gf');
						if (dadPE != null)
							dadPE.visible = false;

						if (songPlayer.dad != null && songPlayer.dad.visible)
							songPlayer.dad.visible = false;

						dadPE = dadMap.get(value2);

						if (!dadPE.alreadyLoaded)
						{
							dadPE.alpha = 1;
							dadPE.alreadyLoaded = true;
						}

						dadPE.visible = true;
						trace('change dad to: ' + value2);

						setOnLuas('dadName', dadPE.curCharacter);

					case 2:
						// if(gfPE.curCharacter != value2) {
						if (!gfMap.exists(value2))
						{
							addCharacterToList(value2, charType);
						}

						if (gfPE != null)
						{
							gfPE.visible = false;
						}

						if (songPlayer.gf != null)
						{
							songPlayer.gf.visible = false;
						}

						gfPE = gfMap.get(value2);
						if (!gfPE.alreadyLoaded)
						{
							gfPE.alpha = 1;
							gfPE.alreadyLoaded = true;
						}
						gfPE.visible = true;

						// }
						setOnLuas('gfName', gfPE.curCharacter);

					case 3:
						// if(dadPE.curCharacter != value2) {
						if (!player3Map.exists(value2))
						{
							addCharacterToList(value2, charType);
						}

						if (player3 != null)
							player3.visible = false;

						player3 = player3Map.get(value2);

						// readd
						// remove(player3);
						// add(player3);

						if (!player3.alreadyLoaded)
						{
							player3.alpha = 1;
							player3.alreadyLoaded = true;
						}

						player3.visible = true;

						// if (songPlayer.dad != null)
						// {
						// 	remove(songPlayer.dad);
						// 	add(songPlayer.dad);
						// }

						// if (dadPE != null)
						// {
						// 	trace('re add dadpe');

						// 	remove(dadPE);
						// 	add(dadPE);
						// }

						setOnLuas('player3Name', player3.curCharacter);
				}
			// reloadHealthBarColors();

			// case 'BG Freaks Expression':
			// if(bgGirls != null) bgGirls.swapDanceType();
			case 'Change Character X':
				var charType:Int = 0;
				switch (value1)
				{
					case 'player3':
						charType = 3;
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newX = Std.parseInt(value2);
				if (Math.isNaN(newX))
					newX = 0;

				switch (charType)
				{
					// todo
					// refactor name shit

					case 0:
					// bf
					case 1:
						// dad
						if (dadPE != null)
							dadPE.x = newX;

						if (songPlayer.dad != null) songPlayer.dad.x = newX;

					case 2:
					// gf

					case 3:
						// player3
				}

			case 'Change Character Y':
				var charType:Int = 0;

				switch (value1)
				{
					case 'player3':
						charType = 3;
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
				}

				var newY = Std.parseInt(value2);
				if (Math.isNaN(newY))
					newY = 0;

				switch (charType)
				{
					// todo
					// refactor name shit

					case 0:
					// bf
					case 1:
						// dad
						if (dadPE != null)
							dadPE.y = newY;

						if (songPlayer.dad != null) songPlayer.dad.y = newY;

					case 2:
					// gf

					case 3:
						// player3
				}

			case "Set Cam Zoom" | 'Set cam Zoom':
				var val1:Float = Std.parseFloat(value1);
				trace('set cam zomm ono: ' + val1);
				if (!Math.isNaN(val1))
					defaultCamZoom = val1;


			case 'Change Scroll Speed':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if (Math.isNaN(val1))
					val1 = 1;
				if (Math.isNaN(val2))
					val2 = 0;

				// ClientPrefs.getGameplaySetting('scrollspeed', 1)
				var newValue:Float = SONG.speed * 1 * val1;

				if (val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}

		trace('Call event: ' + eventName + " | " + value1 + "," + value2);
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var ret:Dynamic = luaArray[i].call(event, args);
			if (ret != FunkinLua.Function_Continue)
			{
				returnVal = ret;
			}
		}
		#end
		return returnVal;
	}

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();

	public var modchartSpritesGroup:Map<String, Array<ModchartSprite>> = new Map<String, Array<ModchartSprite>>();

	public static var ratingStuff:Array<Dynamic> = [
		['You Suck!', 0.2], // From 0% to 19%
		['Shit', 0.4], // From 20% to 39%
		['Bad', 0.5], // From 40% to 49%
		['Bruh', 0.6], // From 50% to 59%
		['Meh', 0.69], // From 60% to 68%
		['Nice', 0.7], // 69%
		['Good', 0.8], // From 70% to 79%
		['Great', 0.9], // From 80% to 89%
		['Sick!', 1], // From 90% to 99%
		['Perfect!!', 1] // The value on this one isn't used actually, since Perfect is always "1"
	];

	// event variables
	private var isCameraOnForcedPos:Bool = false;

	#if (haxe >= "4.0.0")
	public var boyfriendMap:Map<String, BoyfriendPE> = new Map();
	public var dadMap:Map<String, CharacterPE> = new Map();
	public var gfMap:Map<String, CharacterPE> = new Map();
	public var player3Map:Map<String, CharacterPE> = new Map();
	#else
	public var boyfriendMap:Map<String, BoyfriendPE> = new Map<String, CharacterPE>();
	public var dadMap:Map<String, CharacterPE> = new Map<String, CharacterPE>();
	public var gfMap:Map<String, CharacterPE> = new Map<String, CharacterPE>();
	public var player3Map:Map<String, CharacterPE> = new Map<String, CharacterPE>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;

	public var songSpeed(default, set):Float = 1;

	function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
			for (note in notes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					// if (es)
						// note.scale.y *= esNoteScale;

					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					// if (es)
						// note.scale.y *= esNoteScale;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		return value;
	}

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var player3Group:FlxSpriteGroup;
	public var frontGroup:FlxSpriteGroup;

	public var dadPE:CharacterPE;
	public var gfPE:CharacterPE;
	public var bfPE:BoyfriendPE;
	public var player3:CharacterPE;

	public var eventNotes:Array<Dynamic> = [];

	// Handles the new epic mega sexy cam code that i've done
	// private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;

	// private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	// Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var songMisses:Int = 0;
	public var songHits:Int = 0;

	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	// rating sheet
	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;

	//-------------------------------------------------
	public static var instance:GameState = null;

	// SONG name in the json file
	public static var CURRENT_SONG:String;

	// SONG name in the SongManager (filtered)
	public static var SONG_NAME:String;

	// SONG name in the SongManager (raw)
	public static var RAW_SONG_NAME:String;

	public static var songPlayer:SongPlayer;
	public static var playingSong:SongData;

	public static var curStage:String = '';
	public static var SONG:SwagSong;
	public static var isPixelStage:Bool = false;

	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];

	static public var storyDifficulty(get, never):Int;
	static public inline function get_storyDifficulty()
		return StoryState.curDifficulty;

	public static var weekSong:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;

	public static var songPosBG:FlxSprite;
	public static var songPosBar:FlxBar;

	public static var healthBarShitBG:FlxSprite;
	public static var healthBarShit:FlxBar;

	public static var noteBools:Array<Bool> = [false, false, false, false];


	var pracicleMode:Bool = false;
	var halloweenLevel:Bool = false;
	var songLength:Float = 0;
	var kadeEngineWatermark:FlxText;

	public var camFollowSpeed:Float = 1;

	public var vocals:FlxSound;

	public var dad(get, never):Character;
	inline function get_dad()
	{
		if (songPlayer.dad != null && songPlayer.dad.visible)
			return songPlayer.dad;

		if (dadPE != null && dadPE.visible)
			return dadPE;

		if(player3 != null && player3.visible)
			return player3;

		trace('no dad found!');
		return null;
	}

	public var bf(get, never):Character;
	inline function get_bf()
	{
		if (songPlayer.bf != null && songPlayer.bf.visible)
			return songPlayer.bf;

		if (bfPE != null && bfPE.visible)
			return bfPE;

		trace('no bf found!');
		return null;
	}

	
	public var boyfriend(get, never):Character;
	inline function get_boyfriend()
	{
		return bf;
	}


	public var gf(get, never):Character;
	inline function get_gf()
	{
		if (songPlayer.gf != null && songPlayer.gf.visible)
			return songPlayer.gf;

		if (gfPE != null && gfPE.visible)
			return gfPE;


		trace('no gf found!');
		return null;
	}

	public static function dadFE()
	{
		return songPlayer.dad;
	}

	public static function gfFE()
	{
		return songPlayer.gf;
	}

	public static function bfFE():Character
	{
		return songPlayer.bf;
	}

	public var isMidSongEvent:Bool;

	public var restartGame:Bool;

	public var notes:FlxTypedGroup<Note>;

	private var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;

	private var curSection:Int = 0;

	public var camFollow:FlxObject;

	public var prevCamFollow:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote> = null;
	public var playerStrums:FlxTypedGroup<FlxSprite> = null;
	public var cpuStrums:FlxTypedGroup<FlxSprite> = null;

	public var effectStrums:FlxTypedGroup<FlxSprite> = null;

	public var camZooming:Bool = false;

	private var curSong:String = "";

	public var gfSpeed:Float = 1;
	public var health:Float = 2; // making public because sethealth doesnt work without it

	private var combo:Int = 0;

	public static var misses:Int = 0;

	private var accuracy:Float = 0.00;
	private var accuracyDefault:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalNotesHitDefault:Float = 0;
	private var totalPlayed:Int = 0;
	private var ss:Bool = false;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	private var songPositionBar:Float = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:Icon; // making these public again because i may be stupid
	public var iconP2:Icon; // what could go wrong?
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	var scoreTxt:FlxText;
	var missTxt:FlxText;
	var accuracyTxt:FlxText;
	var npsTxt:FlxText;
	var speedTxt:FlxText;

	var gfTimer:Float;

	public var daTutorial:Bool;

	var lerpScore:Int;

	// immortal godlike
	var invisible:Bool;

	public static var offsetTesting:Bool = false;

	var notesHitArray:Array<Date> = [];
	var currentFrames:Int = 0;

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	// lua shit again
	var dialogueJson:DialogueFile = null;
	var cameraTwn:FlxTween;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;
	var trainSound:FlxSound;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;

	//------------------------------------

	public function gfStep():Bool
	{
		return (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null);
	}

	var daAuto:String;
	var songName:FlxText;

	var wiggleShit:WiggleEffect = new WiggleEffect();

	public var talking:Bool = true;
	public var songScore:Int = 0;

	var songScoreDef:Int = 0;
	var isOver:Bool;

	public static var campaignScore:Int = 0;

	public var defaultCamZoom:Float = 0.85;
	public var camZoomShit(get, never):Float;

	public inline function get_camZoomShit():Float
	{
		return defaultCamZoom * Main.fuckZoom;
	}

	public static var daPixelZoom:Float = 6;

	public static var theFunne:Bool = true;

	public var lastNote:String;

	var funneEffect:FlxSprite;

	public var inCutscene:Bool = false;

	public static var repPresses:Int = 0;
	public static var repReleases:Int = 0;

	public static var timeCurrently:Float = 0;
	public static var timeCurrentlyR:Float = 0;

	// Will fire once to prevent debug spam messages and broken animations
	private var triggeredAlready:Bool = false;

	// Will decide if she's even allowed to headbang at all depending on the song
	private var allowedToHeadbang:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;

	// BotPlay text
	private var botState:FlxText;

	private var executeModchart = false;

	public static var playAsDad:Bool = false;

	// determine which's turn, 1 is player, -1 is dad
	public var turn:Int;

	public var bfTurn(get, never):Bool;

	inline function get_bfTurn()
		return turn == 1;

	public var dadTurn(get, never):Bool;

	inline function get_dadTurn()
		return !bfTurn;

	// API stuff

	public function addObject(object:FlxBasic)
	{
		add(object);
	}

	public function removeObject(object:FlxBasic)
	{
		remove(object);
	}

	private var preventLuaRemove:Bool = false;

	override function destroy()
	{
		preventLuaRemove = true;
		for (i in 0...luaArray.length)
		{
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		//oh my goods please destroy shit
		// Assets.cache.clear();
		// FlxG.bitmap.clearCache();
		// trace('clear cache shit!');
		super.destroy();
	}

	override public function create()
	{
		instance = this;

		AdMob.hideBanner();

		songOffset = 0;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		misses = 0;

		repPresses = 0;
		repReleases = 0;

		CURRENT_SONG = SONG_NAME;

		botPlayShit = FlxG.save.data.botplay && isUnlocked();
		practicleMode = FlxG.save.data.handsome && isUnlocked();
		playAsDad =  playAsDad && isUnlocked();


		// pre lowercasing the song name (create)
		var songLowercase = SongFilter.filter(CURRENT_SONG);

		#if !cpp
		executeModchart = false; // FORCE disable for non cpp targets
		#end

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();

		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		// trace('total camera: ' + FlxG.cameras.list.length);
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);

		FlxCamera.defaultCameras = [camGame];
		// CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		// @notrace('INFORMATION ABOUT WHAT U PLAYIN WIT:\nFRAMES: ' + Conductor.safeFrames + '\nZONE: ' + Conductor.safeZoneOffset + '\nTS: '
		// + Conductor.timeScale + '\nBotPlay : ' + botPlayShit);

		// @notrace("cur song shit: " + CURRENT_SONG);

		songPlayer = SongPlayerManager.getCurrentSong(RAW_SONG_NAME);

		// hardcode this shit
		if (CURRENT_SONG == 'sepai' || CURRENT_SONG == 'roses')
			curStage = 'school';

		if (CURRENT_SONG == 'thorns')
			curStage = 'schoolEvil';


		initCharacterGroups();

		songPlayer.init();

		// no need create dialogue shit in freeplay, yay
		// if (isStoryMode)
		// songPlayer.createDialogue(startCountdown);

		songPlayer.applyCamPosition();

		Conductor.songPosition = -5000;

		strumLine = new FlxSprite(0, 20).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<FlxSprite>();
		effectStrums = new FlxTypedGroup<FlxSprite>();
		cpuStrums = new FlxTypedGroup<FlxSprite>();

		// startCountdown();

		// if (CURRENT_SONG == null)
		// @notrace('song is null???');
		// else
		// @notrace('song looks gucci');

		generateSong(CURRENT_SONG);

		// trace('fffff 1');
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			#if android
			var file = notetype + '.lua';
			var luaType = 'custom_notetypes';
			FunkinLua.createLuaAndroid(file, SongPlayer.luaFolder, luaType);
			#else
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if (FileSystem.exists(luaToLoad))
			{
				createLua(luaToLoad);
			}
			#end
		}
		// trace('fffff 4');

		for (event in eventPushedMap.keys())
		{
			#if android
			var file = event + '.lua';
			var luaType = 'custom_events';
			FunkinLua.createLuaAndroid(file, SongPlayer.luaFolder, luaType);
			#else
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			// trace('load custom event: ' + luaToLoad);
			if (FileSystem.exists(luaToLoad))
			{
				createLua(luaToLoad);
			}
			#end
		}
		#end

		for (note in unspawnNotes)
		{
			// re-set it again to load the texture, lmao
			var tmp = note.noteType;
			note.noteType = 'holyshitfuckyou';
			note.noteType = tmp;
		}



		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;
		// trace('fffff 111');

		// trace('1653');
		camFollow = new FlxObject(0, 0, 1, 1);

		var daX = songPlayer.bf.x;
		var daY = songPlayer.bf.y + 50;

		setCamFollowPosition(daX, daY);
		camFollow.setPosition(daX, daY);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		camGame.follow(camFollow, LOCKON, 0.04);
		// camGame.follow(camFollow, LOCKON, 0.04 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()));
		// camGame.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		camGame.zoom = camZoomShit;
		camGame.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image('healthBar'));

		healthBarBG.color = FlxColor.BLACK;

		healthBarBG.alpha = 0.85;

		if (FlxG.save.data.downscroll)
			healthBarBG.y = 50;

		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		add(healthBarBG);


		if (playAsDad)
		{
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, LEFT_TO_RIGHT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
		}
		else
		{
			healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
				'health', 0, 2);
		}

		healthBar.scrollFactor.set();
		healthBar.createFilledBar(0x000000FF, FlxColor.RED);

		healthBarBG.setGraphicSize(Std.int(healthBarBG.width * 0.35));
		healthBar.setGraphicSize(Std.int(healthBarBG.width * 0.35));

		// healthBar.alpha = 0;

		// healthBar
		add(healthBar);

		//------------------------mic c up copy ----------------------------

		daAuto = botPlayShit ? " [A]" : practicleMode ?  "[P]" : "";
		songName = new FlxText(35, healthBarBG.y + 26, 0, CURRENT_SONG.toUpperCase()  + getDiff().toUpperCase() + daAuto, 20);
		if (FlxG.save.data.downscroll)
			songName.y = healthBarBG.y - 18;

		songName.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		songName.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		songName.scrollFactor.set();
		add(songName);

		scoreTxt = new FlxText(songName.x, songName.y - 26, 0, "", 20);
		if (FlxG.save.data.downscroll)
			scoreTxt.y = scoreTxt.y + 26 + 26;

		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);

		missTxt = new FlxText(scoreTxt.x, scoreTxt.y - 26, 0, "", 20);
		if (FlxG.save.data.downscroll)
			missTxt.y = scoreTxt.y + 26;
		missTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		missTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		missTxt.scrollFactor.set();
		add(missTxt);

		accuracyTxt = new FlxText(missTxt.x, missTxt.y - 26, 0, "", 20);
		if (FlxG.save.data.downscroll)
			accuracyTxt.y = missTxt.y + 26;
		accuracyTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		accuracyTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		accuracyTxt.scrollFactor.set();
		add(accuracyTxt);

		npsTxt = new FlxText(accuracyTxt.x, accuracyTxt.y - 26, 0, "", 20);
		if (FlxG.save.data.downscroll)
			npsTxt.y = accuracyTxt.y + 26;
		npsTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		npsTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		npsTxt.scrollFactor.set();
		add(npsTxt);

		// speedTxt = new FlxText(npsTxt.x, npsTxt.y - 26, 0, "", 20);
		// if (FlxG.save.data.downscroll)
		// 	speedTxt.y = npsTxt.y + 26 + 26;

		// speedTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		// speedTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		// speedTxt.scrollFactor.set();
		// add(speedTxt);

		//-----------------------------------------------------------------------------

		// Add Kade Engine watermark
		kadeEngineWatermark = new FlxText(4, healthBarBG.y + 50, 0, SONG.song + " " + getDiff());

		// + (Main.watermarks ? " - KE " + MenuState.kadeEngineVer : ""));
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		// add(kadeEngineWatermark);

		if (FlxG.save.data.downscroll)
			kadeEngineWatermark.y = FlxG.height * 0.9 + 45;

	

		if (!modchartSprites.exists('blammedLightsBlack'))
		{ // Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if (members.indexOf(boyfriendGroup) < position)
			{
				position = members.indexOf(boyfriendGroup);
			}
			else if (members.indexOf(dadGroup) < position)
			{
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if (curStage == 'philly')
			insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;




		iconP1 = new Icon();
		iconP2 = new Icon();

		songPlayer.getDadIcon(iconP2);
		songPlayer.getBFIcon(iconP1);

		//iconP1.y = healthBar.y - (//iconP1.height / 2); // so subtract half babe
		add(iconP1);

		//iconP2.y = healthBar.y - (//iconP2.height / 2); // subtract half babe
		add(iconP2);

		dtrace('1865');

		// new system disable heatlhbar and icon

		healthBar.visible = false;
		healthBarBG.visible = false;

		//iconP1.visible = false;
		//iconP2.visible = false;

		// //iconP1.y = healthBar.y;
		// //iconP2.y = healthBar.y;
		add(effectStrums);

		effectStrums.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		//iconP1.cameras = [camHUD];
		//iconP2.cameras = [camHUD];

		scoreTxt.cameras = [camHUD];
		missTxt.cameras = [camHUD];
		accuracyTxt.cameras = [camHUD];
		npsTxt.cameras = [camHUD];
		songName.cameras = [camHUD];

		// trace('1851');

		// // doof.cameras = [camHUD];
		// if (FlxG.save.data.songPosition)
		// {
		// 	songPosBG.cameras = [camHUD];
		// 	songPosBar.cameras = [camHUD];
		// }

		// healthBarShitBG.cameras = [camHUD];
		// healthBarShit.cameras = [camHUD];

		kadeEngineWatermark.cameras = [camHUD];

		startingSong = true;

		gfSpeed = (SONG.bpm);

		// @notrace('starting');

		if (isStoryMode)
		{
			startCountdown();
			// songPlayer.showDialogue();
		}
		else
		{
			switch (curSong.toLowerCase())
			{
				default:
					startCountdown();
			}
		}

		mcontrols = new Mobilecontrols();
		mcontrols.cameras = [camOther];

		if (!botPlayShit)
			add(mcontrols);

		Controller.init(this, NONE, B);
		Controller._pad.cameras = [camOther];


		calculateNPS();

		listeningModeCheck();


		

		super.create();

		LoadingState.isAlertVisible = false;
		LoadingState.didLoadout = false;
		LoadingState.hasCachedSong = true;
		AdMob.hideBanner();

		createBlackFadeOut();

		if (es)
		{
			mcontrolsArray = [
				mcontrols._padSimple.buttonLeft, mcontrols._padSimple.buttonDown,
				  mcontrols._padSimple.buttonUp, mcontrols._padSimple.buttonRight
			];

			remove(mcontrols);
			remove(strumLineNotes);
			remove(effectStrums);

			mcontrols.cameras = [camHUD];
			add(mcontrols);
			add(strumLineNotes);
			add(effectStrums);

		}
		
	}

	//easier control in my life
	public static var es(get, never):Bool;
	inline static function get_es():Bool
	{
		return FlxG.save.data.mobileControl == 8;
	}
	static public var esNoteScale:Float = 0.5;
	public var esNoteOffsetX:Int = -13;
	public var esNoteOffsetY:Int = -1;

	var mcontrolsArray:Array<FlxSprite>;

	public function initCharacterGroups()
	{
		this.boyfriendGroup = new FlxSpriteGroup(0, 0);
		this.dadGroup = new FlxSpriteGroup(0, 0);
		this.gfGroup = new FlxSpriteGroup(0, 0);
		this.player3Group = new FlxSpriteGroup(0, 0);
		this.frontGroup = new FlxSpriteGroup(0, 0);

	}
	
	function whereAmI()
	{
		if ((health <= 0 || instakillOnMiss) && !isOver)
		{
			if (practicleMode)
			{	
				health += FlxG.random.float(0.1, 2);
				return;
			}

			isOver = true;
			bfFE().stunned = true;
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			pauseGame();

			if (true)
			{
				// 	var bfX = bfFE() != null && bfFE().visible ? bfFE().x : bfPE.x;
				// 	var bfY = bfFE() != null && bfFE().visible ? bfFE().y : bfPE.y;

				// 	openSubState(new StoryGameOverSubstate(bfX, bfY, camFollowPos.x, camFollowPos.y));
				// }
				// else
				// {
				LoadingState.createBlackFadeIn(this, function()
				{
					openSubState(new GameOverSubstate(bfFE().getScreenPosition().x, bfFE().getScreenPosition().y));
				}, camOther, true);
			}
		}
	}

	function createBounds()
	{
		boundMin = new FlxText(0, 0, "");
		boundMax = new FlxText(0, 25, "");

		boundMin.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		boundMin.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);

		boundMax.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, RIGHT);
		boundMax.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);

		boundMin.cameras = [camHUD];
		boundMax.cameras = [camHUD];

		add(boundMin);
		add(boundMax);
	}

	function isUnlocked():Bool
	{
		return (storyWeek + 1 >= StoryState.weekUnlocked.length && FlxG.save.data.unlockedAllWeekShit)
			|| (StoryState.weekUnlocked[storyWeek + 1]);
	}

	var mcontrols:Mobilecontrols;
	var botPlayShit:Bool;
	var musicListeningShit:Bool;
	var practicleMode:Bool;

	public var startTimer:FlxTimer;

	var perfectMode:Bool = false;

	var luaWiggles:Array<WiggleEffect> = [];
	public static var storyCompleted:Bool;

	public static function getDiff():String
	{
		if(isStoryMode && !storyCompleted)
		{
			return "";
		}
		var dif:String = storyDifficulty == 3 ? "Shit" : storyDifficulty == 2 ? "Hard" : storyDifficulty == 1 ? "Normal" : "Easy";
		return ":" +  dif;
	}

	function listeningModeCheck()
	{
		musicListeningShit = FlxG.save.data.musicListening && isUnlocked();
		#if debug
		// musicListeningShit = true;
		// botPlayShit = true;
		#end

		if (musicListeningShit)
		{
			effectStrums.visible = false;
			strumLineNotes.visible = false;
			notes.visible = false;
			healthBar.visible = false;
			healthBarBG.visible = false;
			//iconP1.visible = false;
			//iconP2.visible = false;

			scoreTxt.visible = false;
			missTxt.visible = false;
			accuracyTxt.visible = false;
			npsTxt.visible = false;
			// botState.visible = false;
		}
	}

	public function startCountdown():Void
	{
		callOnLuas('onStartCountdown', []);
		inCutscene = false;
		generateStaticArrows(0);
		generateStaticArrows(1);

		for (i in 0...playerStrums.length)
		{
			setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
			setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
		}
		for (i in 0...cpuStrums.length)
		{
			setOnLuas('defaultOpponentStrumX' + i, cpuStrums.members[i].x);
			setOnLuas('defaultOpponentStrumY' + i, cpuStrums.members[i].y);
			// if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
		}


		songPlayer.startCountdown();
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	var songStarted = false;
	var kudoradoHandsome:Bool = true;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused)
		{
			FlxG.sound.playMusic(Paths.inst(CURRENT_SONG, playingSong.folder), 1, false);
		}

		FlxG.sound.music.onComplete = endSong;
		vocals.play();

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;

		// @notrace('songLength: ' + songLength);

		if (kudoradoHandsome)
		{
			createHealthBarShit();
			createSongPosBar();
		}
	}

	public function shakeMinimal()
	{
		camGame.shake(0.005, 0.05);
	}

	public function shakeNormal()
	{
		camGame.shake(0.01, 0.1);
	}

	public function shakeBig()
	{
		camGame.shake(0.05, 0.25);
	}

	public function shakeGenocide()
	{
		playAnimAllBF('scared', true);
		camGame.shake();
	}

	public function shakePrettyBig()
	{
		camGame.shake(0.035, 0.15);
	}

	var targetNPS:Int;

	function calculateNPS()
	{
		var minTime = 100.0;
		var maxTime = 0.0;
		var noteCount = 0;
		for (section in SONG.notes)
		{
			for (songNotes in section.sectionNotes)
			{
				var gottaHitNote:Bool = playAsDad ? !section.mustHitSection : section.mustHitSection;
				if (songNotes[1] > 3)
				{
					gottaHitNote = (playAsDad ? section.mustHitSection : !section.mustHitSection);
				}

				if (gottaHitNote)
					noteCount++;

				var daStrumTime:Float = songNotes[0];
				if (daStrumTime < 0)
					daStrumTime = 0;
				else
				{
					daStrumTime = daStrumTime / 1000;

					if (daStrumTime < minTime)
						minTime = daStrumTime;

					if (daStrumTime > maxTime)
						maxTime = daStrumTime;
				}
			}
		}

		// var lastSections = SONG.notes[ - 1].sectionNotes;

		var shit = (maxTime - minTime);
		var npsData = noteCount / shit;
		var npm = npsData * 60;
		targetNPS = Std.int(npm);
	}

	var npsShit:Int;

	public var gfNodSpeed:Float;

	public function updateGFNodSpeed()
	{
		var daBeat = (1.0 / (gfSpeed / 60));
		gfNodSpeed = 1 / daBeat;
	}

	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;

		Conductor.changeBPM(songData.bpm);

		curSong = songData.song;

		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(CURRENT_SONG, playingSong.folder));
		else
			vocals = new FlxSound();

		// @notrace('loaded vocals');

		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		// pre lowercasing the song name (generateSong)
		var songLowercase = SongFilter.filter(CURRENT_SONG);

		// Per song offset check
		// var songPath = 'assets/data/' + songLowercase + '/';

		// for (file in sys.FileSystem.readDirectory(songPath))
		// {
		// 	var path = haxe.io.Path.join([songPath, file]);
		// 	if (!sys.FileSystem.isDirectory(path))
		// 	{
		// 		if (path.endsWith('.offset'))
		// 		{
		// 			// @notrace('Found offset file: ' + path);
		// 			songOffset = Std.parseFloat(file.substring(0, file.indexOf('.off')));
		// 			break;
		// 		}
		// 		else
		// 		{
		// 			// @notrace('Offset file not found. Creating one @: ' + songPath);
		// 			sys.io.File.saveContent(songPath + songOffset + '.offset', '');
		// 		}
		// 	}
		// }

		var file:String = '';

		#if ios
		file = "assets/assets/data/" + SongPlayer.folder + SONG_NAME + '/events.json';
		#else
		file = "assets/data/" + SongPlayer.folder + SONG_NAME + '/events.json';
		#end

		#if !android
		if (FileSystem.exists(file))
		{
		#else
		if (openfl.utils.Assets.exists(file))
		{
		#end

			var jsonEvent = Song.loadFromJson("events", SongPlayer.folder + SONG_NAME);
			var eventsData = jsonEvent.events;

			// trace('chess ass 1');
			// check ass
			if (jsonEvent != null)
			{
				// lime.app.Application.current.window.alert("yeah", 'Loaded Event');
				// trace('chess ass 2');

				// check this or crash your ass
				if (eventsData != null)
				{
					// trace('chess ass 3');

					for (event in eventsData) // Event Notes
					{
						// trace('chess ass 4');

						// lime.app.Application.current.window.alert(eventsData[0], 'Loaded Event');
						for (i in 0...event[1].length)
						{
							// trace('chess ass 5');
							// lime.app.Application.current.window.alert(event[1][i][0], 'Loaded Event');
							var subEvent:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
							eventNotes.push(subEvent);
							eventPushed(subEvent);
							trace('push custom event: ' + subEvent);
						}
					}
				}

				// this shouldn't be add, but idk
				// old system
				// trace('12');
				var notesData = jsonEvent.notes;
				// trace('13');
				if (notesData != null)
				{
					// trace('14');

					for (section in notesData)
					{
						// trace('16');
						for (songNotes in section.sectionNotes)
						{
							// trace('17');
							if (songNotes[1] < 0)
							{
								// trace('19');
								var subEvent:Array<Dynamic> = [songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]];
								eventNotes.push(subEvent);
								eventPushed(subEvent);
								trace('push old system custom event: ' + subEvent);
							}
						}
					}
				}
			}
			else
				trace('Null event shit: ' + SONG_NAME);
		}

		//load shit
		var script:String = '';
		#if ios
		script = "assets/assets/data/" + SongPlayer.folder + SONG_NAME + '/script.lua';
		#else
		script = "assets/data/" + SongPlayer.folder + SONG_NAME + '/script.lua';
		#end

		#if MOD_ALLOWED
		#if !android
		if (FileSystem.exists(script))
		{
		#else
		if (openfl.utils.Assets.exists(script))
		{	
		#end	
			#if android
			var file = 'script.lua';
			var daFolder = "assets/data/" + SongPlayer.folder;
			var luaType = SONG_NAME;
			FunkinLua.createLuaAndroid(file, daFolder, luaType);
			#else
			createLua(script);
			#end
		}
		#end



		// trace('No event found for song: ' + SONG_NAME);
		// Not exactly representative of 'daBeats' lol,
		// just how much it has looped
		var daBeats:Int = 0;
		// trace('chess 111');
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				// old event shit, i hate you bjtch
				// if this is not number, this was an event shit, fuck you
				if (Std.is(songNotes[2], std.String) || songNotes[1] < 0)
				{
					var subEvent:Array<Dynamic> = [songNotes[0], songNotes[1], songNotes[2], songNotes[3], songNotes[4]];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
					trace('push in-song note event: ' + subEvent);
					continue;
				}
				var daStrumTime:Float = songNotes[0] + FlxG.save.data.offset + songOffset;

				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = playAsDad ? !section.mustHitSection : section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = (playAsDad ? section.mustHitSection : !section.mustHitSection);
				}
				var oldNote:Note;

				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);

				var sLength = songNotes[2];
				swagNote.sustainLength = songNotes[2];
				swagNote.scrollFactor.set(0, 0);
				swagNote.gfSection = section.gfSection;
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));
				swagNote.noteType = songNotes[3];

				if (!Std.isOfType(songNotes[3], String))
					swagNote.noteType = noteTypeList[songNotes[3]]; // Backward compatibility + compatibility with Week 7 charts
			
				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);
				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true);

					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);
					sustainNote.mustPress = gottaHitNote;
					sustainNote.gfSection = section.gfSection;
					sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
					sustainNote.noteType = swagNote.noteType;
					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 2; // general offset
					}
				}
				swagNote.mustPress = gottaHitNote;
				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else
				{
				}
				if (swagNote.noteType != null && swagNote.noteType != '')
				{
					// if not type wasn't add to list, just add it.
					if (!noteTypeMap.exists(swagNote.noteType))
					{
						// trace('add custom note type!');
						noteTypeMap.set(swagNote.noteType, true);
					}
				}
			}
			daBeats += 1;
		}
		// some song didn't have events field
		// will crash your ass
		trace('load songData events!');
		if (songData.events != null)
		{
			// trace('chess 33333');
			for (event in songData.events) // Event Notes
			{
				// trace('chess 4444');
				for (i in 0...event[1].length)
				{
					// trace('chess 55555');
					var subEvent:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					eventNotes.push(subEvent);
					eventPushed(subEvent);
					trace('push song event: ' + subEvent);
				}
			}
		}
		else
			trace('Empty events: ' + SONG_NAME);
		// //@notrace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if (eventNotes.length > 1)
		{ // No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}


		checkEventNote();
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var midScroll = FlxG.save.data.scrollId <= 1;
			// midScroll ? STRUM_X_MIDDLESCROLL : STRUM_X
			var babyArrow:StrumNote = new StrumNote(0, strumLine.y, i, player);

			// get arrow skin depending on song playing
			songPlayer.getArrowSkin(i, babyArrow);

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			// fade arrow in
			babyArrow.y -= 10;
			babyArrow.alpha = 0;
			FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});

			babyArrow.ID = i;

			var easyControl =  FlxG.save.data.mobileControl == 7;
			var hideDadNote:Bool = es || !FlxG.save.data.showDadNote || !FlxG.save.data.showDad || easyControl;
			var w:Float = FlxG.width; // / Main.fx;
			var shit:Float = 50;
			switch (player)
			{
				case 0:
					cpuStrums.add(babyArrow);
					if (hideDadNote)
						babyArrow.visible = false;
				case 1:
					if (hideDadNote)
					{
						babyArrow.x = w * 0.46;
						babyArrow.x -= (babyArrow.width * 2);
						babyArrow.x += Note.swagWidth * i;
						babyArrow.x += shit; // * Main.fx;

						if (easyControl)
						{
							var quater = (FlxG.width  / 4) / 2;
							var selfSize = quater - (babyArrow.width / 2);
							
							switch (i)
							{
								case 0:
									babyArrow.x = 0 + selfSize;

								case 1:
									babyArrow.x = FlxG.width - (FlxG.width * 0.75) + selfSize;

								case 2:
									babyArrow.x = FlxG.width - (FlxG.width * 0.5) + selfSize;

								case 3:
									babyArrow.x = FlxG.width - (FlxG.width * 0.25) + selfSize;


							}
						}

						if (es)
						{
							var shift = 0.275 * w;
							var quater = i * ((0.6 * w) / 4);
							var selfSize = quater - (babyArrow.width / 2);
							babyArrow.x = shift + selfSize;
						}
					}
					playerStrums.add(babyArrow);
			}

			babyArrow.animation.play('static');

			if (!hideDadNote)
			{
				var px:Int = player;
				px = playAsDad ? px == 0 ? 1 : 0 : px;

				babyArrow.x += shit;
				babyArrow.x += ((w / 2) * px);
			}

			cpuStrums.forEach(function(spr:FlxSprite)
			{
				spr.centerOffsets(); // CPU arrows start out slightly off-center
			});

			if (player == 1)
			{
				var vfx:FlxSprite = new FlxSprite(0, strumLine.y);
				vfx.x = babyArrow.x;
				vfx.y = babyArrow.y + 10;
				vfx.centerOffsets();
				songPlayer.getVFX(i, vfx);
				effectStrums.add(vfx);
			}

			strumLineNotes.add(babyArrow);
		}
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				pauseGame();
			}

			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if (!startTimer.finished)
				startTimer.active = false;

			for (tween in modchartTweens)
			{
				tween.active = false;
			}
			for (timer in modchartTimers)
			{
				timer.active = false;
			}

			if (blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if (phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;

			// if(carTimer != null) carTimer.active = false;

			// Todo
			// do it later due no case use and lazy dude.

			// var chars:Array<CharacterPE> = [];

			// if(bfPE != null)
			// 	chars.push(bfPE);

			// if(bfPE != null)
			// 	chars.push(bfPE);

			// for (i in 0...chars.length) {
			// 	if(chars[i].colorTween != null) {
			// 		chars[i].colorTween.active = false;
			// 	}
			// }
		}

		super.openSubState(SubState);
	}

	public function resyncTweens()
	{
		if (!startTimer.finished)
			startTimer.active = true;
		// if (finishTimer != null && !finishTimer.finished)
		// finishTimer.active = true;

		if (songSpeedTween != null)
			songSpeedTween.active = true;

		if (!startTimer.finished)
			startTimer.active = true;

		for (tween in modchartTweens)
		{
			tween.active = true;
		}
		for (timer in modchartTimers)
		{
			timer.active = true;
		}
		if (blammedLightsBlackTween != null)
			blammedLightsBlackTween.active = false;
		if (phillyCityLightsEventTween != null)
			phillyCityLightsEventTween.active = false;

	}

	override function closeSubState()
	{
		if (paused)
		{
			if (!restartGame)
			{
				if (FlxG.sound.music != null && !startingSong)
				{
					resyncVocals();
				}

				resyncTweens();

				// Todo

				paused = false;
			}

			if (startTimer.finished)
			{
			}
		}

		super.closeSubState();
	}

	function createSongPosBar()
	{
		songPosBG = new FlxSprite(10, songName.y).loadGraphic(Paths.image('fuckbar', 'shared'));
		songPosBG.color = FlxColor.BLACK;

		songPosBG.y -= songPosBG.height / 2;

		songPosBG.x += 5;

		if (FlxG.save.data.downscroll)
			songPosBG.y += 62.5;
		else
			songPosBG.y -= 40;

		add(songPosBG);

		songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, BOTTOM_TO_TOP, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), this,
			'songPositionBar', 0, Math.max(songLength - 1000, 30));

		songPosBG.scrollFactor.set(1, 1);
		songPosBar.scrollFactor.set(1, 1);

		songPosBar.createFilledBar(FlxColor.TRANSPARENT, FlxColor.WHITE);
		add(songPosBar);

		songPosBG.cameras = [camHUD];
		songPosBar.cameras = [camHUD];

		songPosBG.setGraphicSize(Std.int(songPosBG.width * 0.5), Std.int(songPosBG.height * 0.2));
		songPosBar.setGraphicSize(Std.int(songPosBar.width * 0.5), Std.int(songPosBar.height * 0.2));

		songPosBG.cameras = [camHUD];
		songPosBar.cameras = [camHUD];
		songName.cameras = [camHUD];

		if (musicListeningShit)
		{
			songName.visible = false;
			songPosBG.visible = false;
			songPosBar.visible = false;
		}
	}

	function createHealthBarShit()
	{
		healthBarShitBG = new FlxSprite(0, songName.y).loadGraphic(Paths.image('fuckbar', 'shared'));
		healthBarShitBG.color = FlxColor.BLACK;

		healthBarShitBG.y -= healthBarShitBG.height / 2;

		healthBarShitBG.x += 5;

		if (FlxG.save.data.downscroll)
			healthBarShitBG.y += 62.5;
		else
			healthBarShitBG.y -= 40;

		healthBarShitBG.scrollFactor.set();
		add(healthBarShitBG);

		healthBarShitBG.cameras = [camHUD];
		healthBarShit = new FlxBar(healthBarShitBG.x + 4, healthBarShitBG.y + 4, BOTTOM_TO_TOP, Std.int(healthBarShitBG.width - 8),
			Std.int(healthBarShitBG.height - 8), this, 'health', 0, 2);
		healthBarShit.scrollFactor.set();
		healthBarShit.createFilledBar(FlxColor.TRANSPARENT, FlxColor.RED);
		add(healthBarShit);
		healthBarShit.cameras = [camHUD];

		healthBarShitBG.setGraphicSize(Std.int(healthBarShitBG.width * 0.5), Std.int(healthBarShitBG.height * 0.2));
		healthBarShit.setGraphicSize(Std.int(healthBarShit.width * 0.5), Std.int(healthBarShit.height * 0.2));

		if (musicListeningShit)
		{
			healthBarShitBG.visible = false;
			healthBarShit.visible = false;
		}
	}

	function truncateFloat(number:Float, precision:Int):Float
	{
		var num = number;
		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);
		return num;
	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		#if debug
		//no sync 
		// Conductor.songPosition = FlxG.sound.music.time * FlxG.timeScale;
		#else
		Conductor.songPosition = FlxG.sound.music.time;
		#end
		vocals.time = Conductor.songPosition;
		vocals.play();
	}

	private var paused:Bool = false;
	public var startedCountdown:Bool = false;
	var itFuckingEnd = false;
	var canPause:Bool = true;
	var nps:Int = 0;
	var maxNPS:Int = 0;
	var secondToBeat:Float = 1.67164;
	public static var songRate = 1.5;

	public function restorePad()
	{
		Controller.init(this, NONE, B);
		Controller._pad.cameras = [camOther];
	}

	public  function disableCameras()
	{
		camHUD.visible = false;
		camOther.visible = false;
	}

	public function switchState(callback:Void->Void)
	{
		LoadingState.setDynamicTransition();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		restartGame = true;

		var shitCam = new FlxCamera();
		shitCam.bgColor.alpha = 0;
		FlxG.cameras.add(shitCam);

		var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);

		blackScreen.cameras = [shitCam];
		blackScreen.alpha = 0;
		add(blackScreen);

		FlxTween.tween(blackScreen, {alpha: 1}, 1, {});
		new FlxTimer().start(1.1, function(tmr:FlxTimer)
		{
			// place shit here
			callback();
		});
	}

	var lockCamFollow:Bool;
	var maxCamFollowSafeFrame = 48;
	var camFollowSafeFrame = 0;

	function checkUnlockCamFollow()
	{
		if (camFollowSafeFrame >= maxCamFollowSafeFrame)
			lockCamFollow = false;
		else
			camFollowSafeFrame++;
	}

	function updateSongPosBar()
	{
		if (startingSong)
		{
			if (startedCountdown)
			{
				#if debug
				Conductor.songPosition += FlxG.elapsed * 1000 * FlxG.timeScale;
				#else
				Conductor.songPosition += FlxG.elapsed * 1000;
				#end
				
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			if (itFuckingEnd)
				return;

			#if debug
			Conductor.songPosition += FlxG.elapsed * 1000 * FlxG.timeScale;
			#else
			Conductor.songPosition += FlxG.elapsed * 1000;
			#end
			songPositionBar = Conductor.songPosition;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// //@notrace('MISSED FRAME');
				}
			}
		}
	}

	public var bfCamFollowY(get, never):Float;

	inline function get_bfCamFollowY()
	{
		var offsetY = 0;
		var bfY:Float = 0;

		if (bfFE() != null && bfFE().visible)
			bfY = bfFE().getMidpoint().y;

		if (bfPE != null && bfPE.visible)
			bfY = bfPE.getMidpoint().y;

		return clamp(bfY - 100 + offsetY, songPlayer.bfCamFollowYMin(), songPlayer.bfCamFollowYMax());
	}

	public function setCamFollowBF()
	{
		var offsetX = 0;
		var bfX:Float = 0;
		if (bfFE() != null && bfFE().visible)
			bfX = bfFE().getMidpoint().x;

		if (bfPE != null && bfPE.visible)
			bfX = bfPE.getMidpoint().x;

		setCamFollowPosition(bfX - 100 + offsetX, bfCamFollowY);
	}

	public function setCamFollowDad()
	{
		var offsetX = 0;
		var offsetY = 0;
		var dadX:Float = 0;
		var dadY:Float = 0;

		if (dadFE() != null && dadFE().visible)
		{
			dadX = dadFE().getMidpoint().x;
			dadY = dadFE().getMidpoint().y;
		}

		if (dadPE != null && dadPE.visible)
		{
			dadX = dadPE.getMidpoint().x;
			dadY = dadPE.getMidpoint().y;
		}

		setCamFollowPosition(dadX + 150 + offsetX, dadY - 100 + offsetY);
	}

	function updateTextShit()
	{
		if (itFuckingEnd)
			return;

		npsTxt.text = getSongTimeLeft();
		accuracyTxt.text = "Score: " + songScore;
		missTxt.text = "Misses: " + misses;
		scoreTxt.text = CURRENT_SONG.toUpperCase()  + getDiff() + daAuto;
		songName.text = playingSong.songTitle;
	}

	function getSongTimeLeft():String
	{
		var daTime = (songLength - songPositionBar) / 1000;

		if (daTime <= 0)
			return "...";

		var daMinute = Std.int(daTime / 60);
		var daSecond = Std.int(daTime - (60 * daMinute));

		if (daMinute < 1)
		{
			var shit = (daTime > 10 ? Std.int(daSecond) + "" : "0" + Std.int(daSecond));
			return "0:" + shit;
		}
		return daMinute + ":" + (daSecond > 10 ? daSecond + "" : "0" + daSecond);
	}

	override public function update(elapsed:Float)
	{
		dtrace('2906');
		callOnLuas('onUpdate', [elapsed]);

		dtrace('2908');

		checkUnlockCamFollow();

		#if !mobile
		// #if debug
		// boundMin.text = "holdTimer: " + bfFE().holdTimer + ", camFollow: " + camFollow.getPosition() + ", safe frame: " + camFollowSafeFrame;
		// boundMax.text = "lockCamFollow: " + lockCamFollow + ", targetPosition: " + targetCamFollow;
		// #end
		#end
		dtrace('2918');
		#if !debug
		perfectMode = false;
		#end

		if (botPlayShit && FlxG.keys.justPressed.ONE)
			camHUD.visible = !camHUD.visible;

		// reverse iterate to remove oldest notes first and not invalidate the iteration
		// stop iteration as soon as a note is not removed
		// all notes should be kept in the correct order and this is optimal, safe to do every frame/update
		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}

		// immortal babe
		if (invisible)
			health = 2;

		songPlayer.update(elapsed);

		if (npsShit < targetNPS)
		{
			npsShit++;
		}
		
		dtrace('2056');


		#if !mobile
		#if debug
		health = 2;
		#end
		#end


		if (mcontrols != null && mcontrols._padSimple != null)
		{
			if (es)
			{
				var i = 0;
				for (strum in playerStrums)
				{
					strum.scale.x = esNoteScale;
					strum.scale.y = esNoteScale;

					if (i < mcontrolsArray.length)
					{
						var ci = mcontrolsArray[i];
						if (ci != null)
						{
							ci.x = strum.x + esNoteOffsetX;
							ci.y = strum.y + esNoteOffsetY;
						}
					}
					i++;
				}
			
			}
		}

		#if debug
			// if (FlxG.keys.justPressed.Y)
			// {
			// 	esNoteOffsetX++;
			// 	trace('ES Offset X: ' + esNoteOffsetX);
			// }
			// if (FlxG.keys.justPressed.T)
			// {
			// 	esNoteOffsetX--;
			// 	trace('ES Offset X: ' + esNoteOffsetX);
			// }

			// if (FlxG.keys.justPressed.I)
			// {
			// 	esNoteOffsetY++;
			// 	trace('ES Offset Y: ' + esNoteOffsetY);
			// }
			// if (FlxG.keys.justPressed.U)
			// {
			// 	esNoteOffsetY--;
			// 	trace('ES Offset Y: ' + esNoteOffsetY);
			// }
		#end
		super.update(elapsed);

		gfTimer += elapsed;
		// 1 / bps
		// 1 / (bpm / 60)
		var daBeat = (1.0 / (gfSpeed / 60));
		if (gfTimer > daBeat)
		{
			if (daTutorial)
			{
				if (dadFE().animation.curAnim != null && dadFE().animation.curAnim.finished)
				{
					dadFE().dance();
				}
			}
			else
				gfFE().dance();

			gfTimer = 0;
		}

		var daX = FlxMath.lerp(camFollow.x, targetCamFollow.x, (1 / 30.0) * camFollowSpeed);
		var daY = FlxMath.lerp(camFollow.y, targetCamFollow.y, (1 / 30.0) * camFollowSpeed);

		camFollow.setPosition(daX, daY);

		updateTextShit();

		dtrace('2992');

		if (!FlxG.save.data.accuracyDisplay)
			scoreTxt.text = "Score: " + songScore;

		if (Controller.BACK && startedCountdown && canPause && !paused)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new PauseSubState(bfFE().getScreenPosition().x, bfFE().getScreenPosition().y));
		}
		#if !mobile
		#if debug
		if (FlxG.keys.justPressed.P)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			openSubState(new DebugPauseSubState(bfFE().getScreenPosition().x, bfFE().getScreenPosition().y));
		}
		#end
		#end
		dtrace('3012');

		// if (FlxG.keys.justPressed.SEVEN)
		// {
		// 	FlxG.switchState(new ChartingState());
		// }

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		//iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, //iconP1.width, 0.50)));
		//iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, //iconP2.width, 0.50)));

		//iconP1.updateHitbox();
		//iconP2.updateHitbox();
		dtrace('3033');

		var iconOffset:Int = 26;

		
		//todo 
		//good memories
		// if (playAsDad)
		// {
		// 	//iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(100 - healthBar.percent, 100, 0, 0, 100) * 0.01) - iconOffset);
		// 	//iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(100 - healthBar.percent, 100, 0, 0, 100) * 0.01)) - (//iconP2.width - iconOffset);

		// 	if (health > 2)
		// 		health = 2;

		// 	if (healthBar.percent < 20)
		// 		//iconP2.animation.curAnim.curFrame = 1;
		// 	else
		// 		//iconP2.animation.curAnim.curFrame = 0;

		// 	if (healthBar.percent > 80)
		// 		//iconP1.animation.curAnim.curFrame = 1;
		// 	else
		// 		//iconP1.animation.curAnim.curFrame = 0;
		// }
		// else
		// {
		// 	//iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		// 	//iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (//iconP2.width - iconOffset);

		// 	if (health > 2)
		// 		health = 2;
		// 	if (healthBar.percent < 20)
		// 		//iconP1.animation.curAnim.curFrame = 1;
		// 	else
		// 		//iconP1.animation.curAnim.curFrame = 0;

		// 	if (healthBar.percent > 80)
		// 		//iconP2.animation.curAnim.curFrame = 1;
		// 	else
		// 		//iconP2.animation.curAnim.curFrame = 0;
		// }

		dtrace('3073');

		#if !mobile
		#if debug
		if (FlxG.keys.justPressed.EIGHT)
		{
			FlxG.switchState(new AnimationState(DAD));
		}

		if (FlxG.keys.justPressed.ZERO)
		{
			FlxG.switchState(new AnimationState(BF));
		}

		if (FlxG.keys.justPressed.NINE)
		{
			FlxG.switchState(new AnimationState(BF, true));
		}

		if (FlxG.keys.justPressed.SEVEN)
		{
			FlxG.switchState(new AnimationState(GF, true));
		}
		#end
		#end

		updateSongPosBar();
		updateCamFollow();

		if (camZooming)
		{
			camGame.zoom = FlxMath.lerp(camZoomShit, camGame.zoom, 0.95);
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		whereAmI();

		if (FlxG.save.data.resetButton)
		{
			if (FlxG.keys.justPressed.R)
			{
				bfFE().stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				openSubState(new GameOverSubstate(bfFE().getScreenPosition().x, bfFE().getScreenPosition().y));
			}
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}
		dtrace('3132');

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				// instead of doing stupid y > FlxG.height
				// we be men and actually calculate the time :)
				if (daNote.tooLate)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}

				if (!daNote.modifiedByLua)
				{
					if (FlxG.save.data.downscroll)
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
								+
								0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
									2));
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
								+
								0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
									2));
						if (daNote.isSustainNote)
						{
							// Remember = minus makes notes go up, plus makes them go down
						
							if (daNote.animation.curAnim != null)
							{
								if (daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
									daNote.y += daNote.prevNote.height; // holy shit
								else
									daNote.y += daNote.height / 2;
							}
						

								

							// If not in botplay, only clip sustain notes when properly hit, botplay gets to clip it everytime
							if (!botPlayShit)
							{
								if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
									&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
									swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
										+ Note.swagWidth / 2
										- daNote.y) / daNote.scale.y;
									swagRect.y = daNote.frameHeight - swagRect.height;

									daNote.clipRect = swagRect;
								}
							}
							else
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
								swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
									+ Note.swagWidth / 2
									- daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
					}
					else
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
								- 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
									2));
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
								- 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(FlxG.save.data.scrollSpeed == 1 ? SONG.speed : FlxG.save.data.scrollSpeed,
									2));

						if (daNote.isSustainNote)
						{
							daNote.y -= daNote.height / 2;
							if (daNote.animation.curAnim != null)
								if (daNote.animation.curAnim.name.endsWith('end') && daNote.prevNote != null)
									daNote.y -= 7 + daNote.height / 2;//holy shit
							// else
							// 	daNote.y -= daNote.height / 2;



							if (!botPlayShit)
							{
								if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
									&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
								{
									// Clip to strumline
									var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
									swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
										+ Note.swagWidth / 2
										- daNote.y) / daNote.scale.y;
									swagRect.height -= swagRect.y;

									daNote.clipRect = swagRect;
								}
							}
							else
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				// opponent note hit
				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.ignoreNote)
				{
					camZooming = true;

					if (playAsDad)
					{
						var altAnim:String = "";
						if (SONG.notes[Math.floor(curStep / 16)] != null)
						{
							if (SONG.notes[Math.floor(curStep / 16)].altAnim)
								altAnim = '-alt';
						}
						var fuckNote:String = '';
						switch (Math.abs(daNote.noteData))
						{
							case 2:
								fuckNote = "singUP";

							case 3:
								fuckNote = "singRIGHT";

							case 1:
								fuckNote = "singDOWN";

							case 0:
								fuckNote = "singLEFT";
						}

						if (dadFE().animation.getByName(fuckNote + altAnim) == null)
						{
							// no alt anim
						}
						else
							fuckNote += altAnim;

						if (daNote.gfNote)
						{
							playAnimAllGF(fuckNote, true);
						}
						else
							playAnimAllBF(fuckNote, true);

						var isSus:Bool = daNote.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
						var leData:Int = Math.round(Math.abs(daNote.noteData));
						var leType:String = daNote.noteType;

						// process note ev
						// enemy good note hit
						callOnLuas('goodNoteHit', [notes.members.indexOf(daNote), leData, leType, isSus]);

						if (leType != '')
							trace('calllua: ' + leType);
					}
					else
					{
						setLastNote(daNote);
						if ((daNote.gfNote))
						{
							playAnimAllGF(lastNote, true);
						}
						else
							playAnimAllDad(lastNote, true);
					}

					// enemy note highlight
					if (FlxG.save.data.cpuStrums)
					{
						cpuStrums.forEach(function(spr:FlxSprite)
						{
							if (Math.abs(daNote.noteData) == spr.ID)
							{
								spr.animation.play('confirm', true);
							}
							if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
							{
								spr.centerOffsets();
								spr.offset.x -= 13;
								spr.offset.y -= 13;
							}
							else
								spr.centerOffsets();
						});
					}

					// songPlayer.noteEvent(daNote);
					// trigger when dad hit a note
					if (daNote != null && (daNote.gfSection || daNote.gfNote))
					{
						songPlayer.gfNoteEvent(daNote);
					}
					else
					{
						if (playAsDad)
							songPlayer.bfNoteEvent(daNote);
						else
							songPlayer.dadNoteEvent(daNote);
					}

					if (playAsDad)
						bfFE().holdTimer = 0;
					else
					{
						dadFE().holdTimer = 0;
					}

					shitMode(daNote);

					if (SONG.needsVoices)
						vocals.volume = 1;


					if(daNote != null)
						callOnLuas('opponentNoteHit', [
							notes.members.indexOf(daNote),
							Math.abs(daNote.noteData),
							daNote.noteType,
							daNote.isSustainNote
						]);

					daNote.active = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				// else if (daNote.mustPress)
				// {
				// 	// trigger when bf note spawn
				// 	songPlayer.bfNoteEvent(curBeat, daNote);
				// }

				if (daNote.mustPress && !daNote.modifiedByLua)
				{
					daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.x = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
					if (!daNote.isSustainNote)
						daNote.angle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				}
				else if (!daNote.wasGoodHit && !daNote.modifiedByLua)
				{
					daNote.visible = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].visible;
					daNote.x = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].x;
					if (!daNote.isSustainNote)
						daNote.angle = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].angle;
					daNote.alpha = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].alpha;
				}

				if (daNote.isSustainNote)
				{
					daNote.x += daNote.width / 2 + 17;
					if(es)
						daNote.x += daNote.width * esNoteScale;
				}
				// //@notrace(daNote.y);
				// WIP interpolation shit? Need to fix the pause issue
				// daNote.y = (strumLine.y - (songTime - daNote.strumTime) * (0.45 * SONG.speed));

				if ((daNote.mustPress && daNote.tooLate && !FlxG.save.data.downscroll)
					|| (daNote.mustPress && daNote.tooLate && FlxG.save.data.downscroll))
				{
					if (daNote.isSustainNote && daNote.wasGoodHit)
					{
						daNote.kill();
						notes.remove(daNote, true);
					}
					else
					{
						if (!isMidSongEvent)
							vocals.volume = 0;

						if (theFunne && !daNote.ignoreNote)
							noteMiss(daNote.noteData, daNote);
					}

					daNote.visible = false;
					daNote.kill();
					notes.remove(daNote, true);
				}
			});
		}

		if (FlxG.save.data.cpuStrums)
		{
			cpuStrums.forEach(function(spr:FlxSprite)
			{
				if (spr.animation.finished)
				{
					spr.animation.play('static');
					spr.centerOffsets();
				}
			});
		}

		effectStrums.forEach(function(spr:FlxSprite)
		{
			if (spr.animation.finished)
			{
				#if debug
				spr.animation.play('hit');
				//no set alpha le zero
				#else
				spr.alpha = 0;
				#end
			}
		});

		#if debug	
			if (FlxG.keys.justPressed.TWO)
			{
				Debugger.instance.Debug(effectStrums.members[0]);
			}

			if (FlxG.keys.justPressed.THREE)
			{
				Debugger.instance.Debug(effectStrums.members[1]);
			}
			if (FlxG.keys.justPressed.FOUR)
			{
				Debugger.instance.Debug(effectStrums.members[2]);
			}
			if (FlxG.keys.justPressed.FIVE)
			{
				Debugger.instance.Debug(effectStrums.members[3]);
			}

	
		#end

		if (!inCutscene)
			keyShit();

		checkEventNote();

		#if !mobile
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
	}

	function shitMode(daNote:Note)
	{
		if (storyDifficulty == 3)
		{
			// shit difficulty only
			if (health > 0.1)
			{
				var npsCalculated = Math.min(targetNPS, 100);
				npsCalculated = Math.max(targetNPS, 500);

				if (daNote.isSustainNote)
				{
					var subtract = 0.00275;
					subtract *= (100 / npsCalculated);

					// if(CURRENT_SONG == 'tutorial' || CURRENT_SONG == 'tutorial-remix')
					// 	subtract /= 2;

					health -= subtract;
				}
				else
				{
					// health -= 0.04;
					var subtract = 0.2;
					subtract *= (100 / npsCalculated);
					health -= subtract;
				}
			}
		}
	}

	function setLastNote(daNote:Note)
	{
		var altAnim:String = "";
		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].altAnim)
				altAnim = '-alt';
		}

		switch (Math.abs(daNote.noteData))
		{
			case 2:
				lastNote = "singUP";

			case 3:
				lastNote = "singRIGHT";

			case 1:
				lastNote = "singDOWN";

			case 0:
				lastNote = "singLEFT";
		}

		if (dadFE().animation.getByName(lastNote + altAnim) == null)
		{
			// no alt anim
		}
		else
			lastNote += altAnim;
	}

	public function endSong():Void
	{
		// wait next beat plus a bit offset (0.1) before ending.
		new FlxTimer().start(1 / secondToBeat + 0.1, function shit(tmr:FlxTimer)
		{
			itFuckingEnd = true;
		}, 1);

		botPlayShit = false;
		FlxG.save.data.scrollSpeed = 1;

		songPlayer.endSongEvent(endSongCallback);
	}

	public var targetCamFollow:FlxPoint;

	public function setCamFollowPosition(x:Float, y:Float)
	{
		lockCamFollow = true;
		targetCamFollow = new FlxPoint(x, y);
	}

	function updateCamFollow()
	{
		var note = Std.int(curStep / 16);
		// always soon than one note

		if (generatedMusic && SONG.notes[note] != null)
		{
			// Make sure Girlfriend cheers only for certain songs
			if (allowedToHeadbang)
			{
				// Don't animate GF if something else is already animating her (eg. train passing)
				if (gfFE().animation.curAnim.name == 'danceLeft'
					|| gfFE().animation.curAnim.name == 'danceRight'
					|| gfFE().animation.curAnim.name == 'idle')
				{
				}
			}


			if (SONG.notes[note].gfSection && songPlayer.gfSection())
			{
				songPlayer.updateCamFollowGF();
				trace('omg gf section');
				//do nothing
				// trace('gf singing, ignore camera shit!');
			}
			else
			{
				if (!SONG.notes[note].mustHitSection && camFollow.x != dadFE().getMidpoint().x + 150)
				{
					if (turn == -1) // repeat
						camFollowSafeFrame = 0;

					setCamFollowDad();

					songPlayer.updateCamFollowDad();
					turn = -1;
				}

				if (SONG.notes[note].mustHitSection && camFollow.x != bfFE().getMidpoint().x - 100 && !lockCamFollow)
				{
					if (turn == 1) // repeat
						camFollowSafeFrame = 0;

					setCamFollowBF();
					turn = 1;
					songPlayer.updateCamFollowBF();
				}
			}
		}
	}

	function clamp(raw:Float, min:Float, max:Float)
	{
		if (raw < min)
			raw = min;
		if (raw > max)
			raw = max;

		return raw;
	}

	private function endSongCallback()
	{
		canPause = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		if (SONG.validScore)
		{
			// adjusting the highscore song name to be compatible
			// would read original scores if we didn't change packages
			var songHighscore = SongFilter.filter(CURRENT_SONG);

			#if !switch
			Highscore.saveScore(songHighscore, Math.round(songScore), storyDifficulty);
			#end
		}

		if (offsetTesting)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			offsetTesting = false;
			LoadingState.loadAndSwitchState(new OptionsMenu());
			FlxG.save.data.offset = offsetTest;
		}
		else
		{
			if (isStoryMode)
			{
				campaignScore += Math.round(songScore);
				storyPlaylist.remove(storyPlaylist[0]);
				if (storyPlaylist.length <= 0)
				{

					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
				

					backHome();

					var daUnlocked = StoryState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryState.weekUnlocked.length - 1))];
			
					// if this week are not unlocked yet
					if (!daUnlocked)
						FreePlayState.unlockSong(RAW_SONG_NAME);
				
					StoryState.weekUnlocked[Std.int(Math.min(storyWeek + 1, StoryState.weekUnlocked.length - 1))] = true;


					if (SONG.validScore)
					{
						// //NGio.unlockMedal(60961);
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty);
					}

					FreePlayState.saveSongData();
					if (!daUnlocked) // if new unlocked week, so here we go
						LoadingState.showNewWeekUnlocked(this, function()
						{
							createBlackFadeIn(function()
							{
								backToMenuShit();
							});
						});
					else
					{
						createBlackFadeIn(function()
						{
							backToMenuShit();
						});
					}
					
				}
				else
				{

					// @notrace('LOADING NEXT SONG');
					// pre lowercasing the next story song name
					var nextSongLowercase = SongFilter.filter(storyPlaylist[0]);


					//try unlock da song
					FreePlayState.unlockSong(RAW_SONG_NAME);

					// @notrace(nextSongLowercase + difficulty);

					// pre lowercasing the song name (endSong)
					var songLowercase = SongFilter.filter(CURRENT_SONG);

					if (songLowercase == 'eggnog')
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * camGame.zoom,
							-FlxG.height * camGame.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					// FlxTransitionableState.skipNextTransIn = true;
					// FlxTransitionableState.skipNextTransOut = true;
					
					//clear fucking song caching
					LoadingState.clearCachedSong();

					prevCamFollow = camFollow;

					GameState.SONG_NAME = nextSongLowercase;
					GameState.RAW_SONG_NAME = storyPlaylist[0];
					StoryState.loadDataFile(nextSongLowercase);

					CURRENT_SONG = SONG_NAME;

					FlxG.sound.music.stop();

					moveNext();

					// LoadingState.loadAndSwitchState(new GameState());
				}
			}
			else
			{
				backHome();
				createBlackFadeIn(function()
				{
					backToMenuShit();
				});
			}
		}
	}

	function backToMenuShit()
	{
		createEmptyBlack();
		GameState.instance.gameNa();
		AdMob.showInterstitial(60);

		if (GameState.isStoryMode)
			FlxG.switchState(new StoryState());
		else
			FlxG.switchState(new FreePlayState());		// FlxG.sound.play(Paths.music('gameOverEnd'));
		
	}
	public function createEmptyBlack()
	{
		var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);
		var shitCam = new FlxCamera();
		shitCam.bgColor.alpha = 0;
		FlxG.cameras.add(shitCam);

		blackScreen.cameras = [shitCam];
		add(blackScreen);
	}

	public function gameNa()
	{
		restartGame = true;
		vocals.stop();
		FlxG.sound.music.stop();
		// createEmptyBlack();
	}

	function dtrace(msg:String)
	{
		#if debug
		// trace(msg);
		#end
	}

	public function nextSong()
	{
		FlxG.resetState();
	}

	public function revivePlayer()
	{
		invisible = true;
		health = 2;
		isOver = false;
		bfFE().stunned = false;
		persistentUpdate = true;
		persistentDraw = true;
		paused = false;
		Controller.init(this, NONE, B);
		Controller._pad.cameras = [camOther];
		resumeGame();

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			invisible = false;
		});
	}

	public function pauseGame()
	{
		vocals.volume = 0;
		vocals.pause();
		FlxG.sound.music.pause();
	}

	public function resumeGame()
	{
		resyncVocals();
	}

	function backHome()
	{
		isOver = true;
		bfFE().stunned = true;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		camHUD.visible = false;
		camOther.visible = false;

		pauseGame();
	}

	function moveNext()
	{
		if (isOver)
			return;

		isOver = true;
		bfFE().stunned = true;
		persistentUpdate = false;
		persistentDraw = true;
		paused = true;
		camHUD.visible = false;
		camOther.visible = false;
		
		pauseGame();

		createBlackFadeIn(function()
		{
			openSubState(new VictorySubState(0, 0));
		});
	}

	function zoomInAndFading()
	{
		camZooming = false;
		camGame.stopFX();

		new FlxTimer().start(0.016, function(tmr:FlxTimer)
		{
			camGame.zoom += 0.016;
		}, 120);
	}

	function createBlackFadeIn(callback:Void->Void)
	{
		zoomInAndFading();

		var shitCam = new FlxCamera();
		shitCam.bgColor.alpha = 0;
		FlxG.cameras.add(shitCam);

		var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.BLACK);

		blackScreen.cameras = [shitCam];
		blackScreen.alpha = 0;
		add(blackScreen);

		FlxTween.tween(blackScreen, {alpha: 1}, {});
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			callback();
			// place shit here
			remove(blackScreen);
			blackScreen = null;
		});
	}

	private function createBlackFadeOut()
	{
		// LoadingState.createWeekLoadout(this, null, camOther, true);
		var blackShit:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		blackShit.scrollFactor.set(0.5, 0.5);
		blackShit.cameras = [camOther];
		add(blackShit);
		FlxTween.tween(blackShit, {alpha: 0}, 1.5, {
			ease: FlxEase.quartInOut,
			onComplete: function(callback:FlxTween)
			{
				remove(blackShit);
				blackShit = null;
			}
		});
	}

	public var endingSong:Bool = false;
	var hits:Array<Float> = [];
	var offsetTest:Float = 0;
	var timeShown = 0;

	function popUpHealth(daRating:String, rating:Float)
	{
		var healthRating:FlxText = new FlxText(0, 0, 0, "");
		healthRating.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.CYAN, CENTER);

		switch (daRating)
		{
			case 'shit' | 'bad' | 'fuck':
				healthRating.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.RED, CENTER);

			case 'good' | 'sick':
				healthRating.setFormat(Paths.font("vcr.ttf"), 15, FlxColor.CYAN, CENTER);
		}

		healthRating.setBorderStyle(OUTLINE, 0xFF000000, 1, 1);
		healthRating.text = rating == 0 ? "" : (rating > 0 ? "+" : "") + (rating * 50);

		healthRating.x = healthBarShitBG.x - 5;

		if (FlxG.save.data.downscroll)
			healthRating.y = songName.y + 125;
		else
			healthRating.y = songName.y - 125;

		healthRating.size = 20;

		if (healthRating.alpha != 1)
			healthRating.alpha = 1;

		if (!botPlayShit)
			add(healthRating);

		healthRating.updateHitbox();
		healthRating.cameras = [camHUD];

		FlxTween.tween(healthRating, {alpha: 0}, 0.2, {
			startDelay: Conductor.crochet * 0.0005,
		});
	}

	function popUpRating(daRating:String)
	{
		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (curStage.startsWith('school'))
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		var rating:FlxSprite = new FlxSprite();

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.screenCenter();
		var xPos:Float = FlxG.width * 0.55;

		rating.y -= 40;

		if (FlxG.save.data.downscroll)
		{
			rating.y -= 200;
			rating.x = xPos - 125;
		}
		else
		{
			rating.y += 100;

			if (playAsDad)
				rating.x = xPos + 25;
			else
				rating.x = xPos - 5;
		}

		if (FlxG.save.data.changedHit)
		{
			rating.x = FlxG.save.data.changedHitX;
			rating.y = FlxG.save.data.changedHitY;
		}

		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		if (!botPlayShit)
			add(rating);

		if (!curStage.startsWith('school'))
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7 * 0.5));
			rating.antialiasing = true;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.5 * 0.7));
		}

		rating.updateHitbox();
		rating.cameras = [camHUD];

		FlxTween.tween(rating, {alpha: 0}, 0.2, {
			onComplete: function(tween:FlxTween)
			{
				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001
		});
	}

	private function popUpScore(daNote:Note, missNote:Bool = false):Void
	{
		if (musicListeningShit)
			return;

		var noteDiff:Float = Math.abs(Conductor.songPosition - daNote.strumTime);
		var wife:Float = EtternaFunctions.wife3(noteDiff, Conductor.timeScale);
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var score:Float = 350;
		var healthRating:Float = 0;
		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit += wife;

		var daRating = daNote.rating;

		if (missNote)
			daRating = "fuck";

		var scoreShit:Float = 0;

		switch (daRating)
		{
			case 'fuck':
				scoreShit = -500;
				combo = 0;
				healthRating = -0.2;
				ss = false;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;

			case 'shit':
				scoreShit = -300;
				healthRating = -0.1;
				ss = false;
				shits++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.25;
			case 'bad':
				daRating = 'bad';
				scoreShit = 0;
				healthRating -= 0.06;
				ss = false;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				daRating = 'good';
				scoreShit = 200;
				ss = false;
				goods++;

				healthRating = 0.04;

				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
			case 'sick':
				healthRating = 0.1;

				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
		}

		var newbie =  isStoryMode && !storyCompleted;
	
	
		//story, newbie code
		if (healthRating < 0 && newbie)
		{
			healthRating /= 5;
			scoreShit /= 5;
		}

		//easy, make it more easy
		if (!newbie && healthRating < 0)
		{
			switch (storyDifficulty)
			{
				//make it more easy
				case 0:
					healthRating /= 2.5;
					scoreShit /= 2.5;

				// make it a bit easy
				case 1:
					healthRating /= 1.5;
					scoreShit /= 1.5;

				//hard, yeah, here we go
				case 2:
					healthRating *= 1.25;
					scoreShit *= 1.25;

				case 3:
					//you wanna hard, go fuck it
					healthRating *= 2;
					scoreShit *= 2;
			}
		}


		score += scoreShit;
		health += healthRating;

		if (health > 2)
			health = 2;

		popUpHealth(daRating, Std.int(healthRating));

		if (daRating != 'shit' || daRating != 'bad')
		{
			songScore += Math.round(score);
			songScoreDef += Math.round(ConvertScore.convertScore(noteDiff));

			/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

			if (!FlxG.save.data.showCombo)
				return;

			var pixelShitPart1:String = "";
			var pixelShitPart2:String = '';

			if (curStage.startsWith('school'))
			{
				pixelShitPart1 = 'weeb/pixelUI/';
				pixelShitPart2 = '-pixel';
			}

			var coolText:FlxText = new FlxText(0, 0, 0, placement, 5);
			coolText.screenCenter();
			coolText.x = FlxG.width * 0.55;

			if (FlxG.save.data.downscroll)
			{
				coolText.y -= 1000;
			}
			else
			{
				coolText.y -= 350;
			}

			coolText.cameras = [camHUD];

			//

			var rating:FlxSprite = new FlxSprite();

			rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
			rating.screenCenter();
			if (FlxG.save.data.downscroll)
			{
				rating.y -= 200;
				rating.x = coolText.x - 125;
			}
			else
			{
				rating.y += 100;

				if (playAsDad)
					rating.x = coolText.x + 25;
				else
					rating.x = coolText.x - 5;
			}

			if (FlxG.save.data.changedHit)
			{
				rating.x = FlxG.save.data.changedHitX;
				rating.y = FlxG.save.data.changedHitY;
			}

			rating.acceleration.y = 550;
			rating.velocity.y -= FlxG.random.int(140, 175);
			rating.velocity.x -= FlxG.random.int(0, 10);

			var msTiming = HelperFunctions.truncateFloat(noteDiff, 3);
			if (botPlayShit)
				msTiming = 0;

			if (msTiming >= 0.03 && offsetTesting)
			{
				// Remove Outliers
				hits.shift();
				hits.shift();
				hits.shift();
				hits.pop();
				hits.pop();
				hits.pop();
				hits.push(msTiming);

				var total = 0.0;

				for (i in hits)
					total += i;

				offsetTest = HelperFunctions.truncateFloat(total / hits.length, 2);
			}

			// ah shit here we go again!

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
			comboSpr.screenCenter();
			comboSpr.x = rating.x;
			comboSpr.y = rating.y + 100;
			comboSpr.acceleration.y = 600;
			comboSpr.velocity.y -= 150;

			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.5));

			comboSpr.velocity.x += FlxG.random.int(1, 10);

			if (!botPlayShit)
				add(rating);

			if (!curStage.startsWith('school'))
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7 * 0.5));
				rating.antialiasing = true;
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7 * 0.5));
				comboSpr.antialiasing = true;
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.5 * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.5 * 0.7));
			}

			comboSpr.updateHitbox();
			rating.updateHitbox();

			comboSpr.cameras = [camHUD];
			rating.cameras = [camHUD];

			var seperatedScore:Array<Int> = [];

			var comboSplit:Array<String> = (combo + "").split('');

			// make sure we have 3 digits to display (looks weird otherwise lol)
			if (comboSplit.length == 1)
			{
				seperatedScore.push(0);
				seperatedScore.push(0);
			}
			else if (comboSplit.length == 2)
				seperatedScore.push(0);

			for (i in 0...comboSplit.length)
			{
				var str:String = comboSplit[i];
				seperatedScore.push(Std.parseInt(str));
			}

			var daLoop:Int = 0;
			for (i in seperatedScore)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
				numScore.screenCenter();
				numScore.x = rating.x + (43 * daLoop * 0.425) - 50;
				numScore.y = rating.y + 100;
				numScore.cameras = [camHUD];

				if (!curStage.startsWith('school'))
				{
					numScore.antialiasing = true;
					numScore.setGraphicSize(Std.int(numScore.width * 0.25));
				}
				else
				{
					numScore.setGraphicSize(Std.int(numScore.width * 0.25 * daPixelZoom));
				}
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300);
				numScore.velocity.y -= FlxG.random.int(140, 160);
				numScore.velocity.x = FlxG.random.float(-5, 5);

				add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});

				daLoop++;
			}
			/* 
			//@notrace(combo);
			//@notrace(seperatedScore);
		 */

			coolText.text = Std.string(seperatedScore);
			// add(coolText);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001,
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					coolText.destroy();
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.001
			});

			curSection += 1;
		}
	}

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;
	public var isGameStarted:Bool;
	var boundMin:FlxText;
	var boundMax:FlxText;

	private function keyShit():Void // I've invested in emma stocks
	{
		// control arrays, order L D R U
		var holdArray:Array<Bool> = [mcontrols.LEFT, mcontrols.DOWN, mcontrols.UP, mcontrols.RIGHT];
		var pressArray:Array<Bool> = [mcontrols.LEFT_P, mcontrols.DOWN_P, mcontrols.UP_P, mcontrols.RIGHT_P];
		var releaseArray:Array<Bool> = [mcontrols.LEFT_R, mcontrols.DOWN_R, mcontrols.UP_R, mcontrols.RIGHT_R];

		// Prevent player input if botplay is on
		if (botPlayShit)
		{
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}
		// HOLDS, check for sustain notes
		if (holdArray.contains(true) && /*!bfFE().stunned && */ generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData])
					goodNoteHit(daNote);
			});
		}

		// PRESSES, check for note hits
		if (pressArray.contains(true) && /*!bfFE().stunned && */ generatedMusic)
		{
			if (playAsDad)
			{
				dadFE().holdTimer = 0;
			}
			else
				bfFE().holdTimer = 0;

			var possibleNotes:Array<Note> = []; // notes that can be hit
			var directionList:Array<Int> = []; // directions that can be hit
			var dumbNotes:Array<Note> = []; // notes to kill later
			var directionsAccounted:Array<Bool> = [false, false, false, false]; // we don't want to do judgments for more than one presses

			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit)
				{
					if (!directionsAccounted[daNote.noteData])
					{
						if (directionList.contains(daNote.noteData))
						{
							directionsAccounted[daNote.noteData] = true;
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				}
			});

			// //@notrace('\nCURRENT LINE:\n' + directionsAccounted);

			for (note in dumbNotes)
			{
				FlxG.log.add("killing dumb ass note at " + note.strumTime);
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}

			possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

			var dontCheck = false;

			for (i in 0...pressArray.length)
			{
				if (pressArray[i] && !directionList.contains(i))
					dontCheck = true;
			}

			if (perfectMode)
				goodNoteHit(possibleNotes[0]);
			else if (possibleNotes.length > 0 && !dontCheck)
			{
				if (!FlxG.save.data.ghost)
				{
					for (shit in 0...pressArray.length)
					{ // if a direction is hit that shouldn't be
						if (pressArray[shit] && !directionList.contains(shit))
							noteMiss(shit, null);
					}
				}
				for (coolNote in possibleNotes)
				{
					if (pressArray[coolNote.noteData])
					{
						if (mashViolations != 0)
							mashViolations--;

						accuracyTxt.color = FlxColor.WHITE;
						goodNoteHit(coolNote);
					}
				}
			}
			else if (!FlxG.save.data.ghost)
			{
				for (shit in 0...pressArray.length)
					if (pressArray[shit])
						noteMiss(shit, null);
			}

			if (dontCheck && possibleNotes.length > 0 && FlxG.save.data.ghost && !botPlayShit)
			{
				if (mashViolations > 8)
				{
					// @notrace('mash violations ' + mashViolations);
					accuracyTxt.color = FlxColor.RED;

					noteMiss(0, null);
				}
				else
					mashViolations++;
			}
		}

		notes.forEachAlive(function(daNote:Note)
		{
			if (FlxG.save.data.downscroll && daNote.y > strumLine.y || !FlxG.save.data.downscroll && daNote.y < strumLine.y)
			{
				// Force good note hit regardless if it's too late to hit it or not as a fail safe
				if (botPlayShit && daNote.canBeHit && daNote.mustPress || botPlayShit && daNote.tooLate && daNote.mustPress)
				{
					goodNoteHit(daNote);
					if (playAsDad)
						dadFE().holdTimer = daNote.sustainLength;
					else
						bfFE().holdTimer = daNote.sustainLength;
				}
			}
		});

		if (playAsDad)
		{
			if (dadFE().holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || botPlayShit))
			{
				if (!dadFE().animation.curAnim.name.endsWith('miss'))
				{
					// && (bfFE().animation.curAnim != null && bfFE().animation.curAnim.finished))
					playAnimAllDad('idle');
				}
			}
		}
		else
		{
			if (bfFE().holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || botPlayShit))
			{
				if (!bfFE().animation.curAnim.name.endsWith('miss'))
					// && (bfFE().animation.curAnim != null && bfFE().animation.curAnim.finished))
					playAnimAllBF('idle');
			}
		}

		if (!botPlayShit)
		{
			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (pressArray[spr.ID] && spr.animation.curAnim.name != 'confirm')
				{
					spr.animation.play('pressed');
					spr.centerOffsets();
					if (es)
					{
						spr.offset.x -= 10;
						spr.offset.y += 10;

					}
				}
				if (!holdArray[spr.ID])
					spr.animation.play('static');

				if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
				{
					spr.centerOffsets();
					if (!es)
					{
						spr.offset.x -= 13;
						spr.offset.y -= 13;
					}
					else
					{
						spr.offset.x -= 20;
						spr.offset.y -= 20;
					}
				}
				else
					spr.centerOffsets();
			});
		}
		else
		{
			// if botplay, fuck you
			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (spr.animation.finished)
				{
					spr.animation.play('static');
					spr.centerOffsets();
				}
			});
		}
	}

	function noteMiss(direction:Int = 1, daNote:Note):Void
	{
		// var stunned:Bool = playAsDad ? dadFE().stunned : bfFE().stunned;
		var amIHandSomeBabe = true; // true//verytrue
		if (amIHandSomeBabe)
		{
			// Dupe note remove, copy shit from psych engine
			// Sorry :( and thank you bbpanzu

			// fuck you bbpanzu, crash code :(

			// notes.forEachAlive(function(note:Note)
			// {
			// 	if (daNote != note
			// 		&& daNote.mustPress
			// 		&& daNote.noteData == note.noteData
			// 		&& daNote.isSustainNote == note.isSustainNote
			// 		&& Math.abs(daNote.strumTime - note.strumTime) < 1)
			// 	{
			// 		note.kill();
			// 		notes.remove(note, true);
			// 		note.destroy();
			// 	}
			// });

			if (instakillOnMiss)
			{
				whereAmI();
			}

			if (combo > 5 && gfFE() != null && gfFE().visible && gfFE().animOffsets.exists('sad'))
			{
				gfFE().playAnimForce('sad', 0.5, function()
				{
					gfFE().playAnim('idle');
				});
			}

			combo = 0;
			misses++;

			var scoreShit:Float = -500;
			var healthRating:Float = -0.1;


			var newbie = isStoryMode && !storyCompleted;

			// story, newbie code
			if (healthRating < 0 && newbie)
			{
				healthRating /= 5;
				scoreShit /= 5;
			}

			// easy, make it more easy
			if (!newbie && healthRating < 0)
			{
				switch (storyDifficulty)
				{
					// make it more easy
					case 0:
						healthRating /= 2.5;
						scoreShit /= 2.5;

					// make it a bit easy
					case 1:
						healthRating /= 1.5;
						scoreShit /= 1.5;

					// hard, yeah, here we go
					case 2:
						healthRating *= 1.25;
						scoreShit *= 1.25;

					case 3:
						// you wanna hard, go fuck it
						healthRating *= 2;
						scoreShit *= 2;
				}
			}

			
			songScore += Std.int(scoreShit);
			health += healthRating;

			popUpRating('fuck');
			popUpHealth('fuck', healthRating);

			// var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition);
			// var wife:Float = EtternaFunctions.wife3(noteDiff, FlxG.save.data.etternaMode ? 1 : 1.7);

			// if (FlxG.save.data.accuracyMod == 1)
			// 	totalNotesHit -= 1;

			if (!isMidSongEvent)
				FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			songPlayer.playerMissNoteEvent();

			// if (daNote.gfNote)
			// {
			// 	// temp ignore
			// }
			if (playAsDad)
			{
				// temp ignore
			}
			else
			{
				var fuckyou:String = '';
				switch (direction)
				{
					case 0:
						fuckyou = 'singLEFTmiss';
					case 1:
						fuckyou = 'singDOWNmiss';
					case 2:
						fuckyou = 'singUPmiss';
					case 3:
						fuckyou = 'singRIGHTmiss';
				}

				playAnimAllBF(fuckyou, true);
			}

			// some time the note killed for some reason idk
			if (daNote == null)
			{
				trace('Null at: callOnLuas(noteMiss)');
			}
			else
			{
				var dNote = notes.members.indexOf(daNote);
				var nData = daNote.noteData;
				var nType = daNote.noteType;
				var isSus = daNote.isSustainNote;

				callOnLuas('noteMiss', [dNote, nData, nType, isSus]);
				// trace('callonlua note miss: ' + nType);
			}

			updateAccuracy();
		}
	}

	/*function badNoteCheck()
	{
		// just double pasting this shit cuz fuk u
		// REDO THIS SYSTEM!
		var upP = mcontrols.UP_P;
		var rightP = mcontrols.RIGHT_P;
		var downP = mcontrols.DOWN_P;
		var leftP = mcontrols.LEFT_P;

		if (leftP)
			noteMiss(0);
		if (upP)
			noteMiss(2);
		if (rightP)
			noteMiss(3);
		if (downP)
			noteMiss(1);
		updateAccuracy();
	}
 */
	function updateAccuracy()
	{
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
	}

	function getKeyPresses(note:Note):Int
	{
		var possibleNotes:Array<Note> = []; // copypasted but you already know that

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate)
			{
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;
	var etternaModeScore:Int = 0;

	function noteCheck(controlArray:Array<Bool>, note:Note):Void // sorry lol
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		if (controlArray[note.noteData])
		{
			goodNoteHit(note, (mashing > getKeyPresses(note)));
		}
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (mashing != 0)
			mashing = 0;

		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.CalculateRating(noteDiff);

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		if (!note.wasGoodHit)
		{
			if (botPlayShit && (note.ignoreNote || note.hitCausesMiss))
				return;

			if (note.hitCausesMiss)
			{
				noteMiss(note);
				// TODO
				// if (!note.noteSplashDisabled && !note.isSustainNote)
				// {
				// 	spawnNoteSplashOnNote(note);
				// }

				switch (note.noteType)
				{
					case 'Hurt Note' | 'EX Note' | 'Hell Note': // Hurt note
						if (bfFE() != null && bfFE().animation.getByName('hurt') != null)
						{
							bfFE().playAnim('hurt', true);
							bfFE().specialAnim = true;
						}

						if (bfPE != null && bfPE.animation.getByName('hurt') != null)
						{
							bfPE.playAnim('hurt', true);
							bfPE.specialAnim = true;
						}
				}

				note.wasGoodHit = true;
				var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
				var leData:Int = Math.round(Math.abs(note.noteData));
				var leType:String = note.noteType;

				// process note ev
				callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				return;
			}

			if (!note.isSustainNote)
			{
				popUpScore(note);
				combo += 1;
			}
			else
				totalNotesHit += 1;

			if (playAsDad)
			{
				var noteShit:String = "";
				switch (note.noteData)
				{
					case 2:
						noteShit = 'singUP';
					case 3:
						noteShit = 'singRIGHT';
					case 1:
						noteShit = 'singDOWN';
					case 0:
						noteShit = 'singLEFT';
				}

				if (note.gfNote)
				{
					playAnimAllGF(noteShit, true);
				}
				else
					playAnimAllDad(noteShit, true);
			}
			else
			{
				var noteShit:String = "";
				switch (note.noteData)
				{
					case 2:
						noteShit = 'singUP';
					case 3:
						noteShit = 'singRIGHT';
					case 1:
						noteShit = 'singDOWN';
					case 0:
						noteShit = 'singLEFT';
				}

				if (note.gfNote)
				{
					playAnimAllGF(noteShit, true);
				}
				else
					playAnimAllBF(noteShit, true);
			}

			effectStrums.forEach(function(spr:FlxSprite)
			{
				if (note != null && !note.isSustainNote)
				{
					var daRating = note.rating;

					if (daRating == 'sick' && Math.abs(note.noteData) == spr.ID && spr.animation.finished)
					{
						spr.alpha = 1;
						spr.animation.play('hit', true);
					}
				}
			});

			playerStrums.forEach(function(spr:FlxSprite)
			{
				if (Math.abs(note.noteData) == spr.ID)
				{
					spr.animation.play('confirm', true);
					if (playAsDad)
					{
						setLastNote(note);
						songPlayer.dadNoteEvent(note);
					}
					else
						songPlayer.bfNoteEvent(note);
					
				}
				if (spr.animation.curAnim.name == 'confirm' && !curStage.startsWith('school'))
				{
					spr.centerOffsets();
					spr.offset.x -= 13;
					spr.offset.y -= 13;
				}
				else
					spr.centerOffsets();
			});

			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			note.kill();
			notes.remove(note, true);
			note.destroy();

			updateAccuracy();
		}
	}

	var danced:Bool = false;

	override function stepHit()
	{
		super.stepHit();
		songPlayer.midSongStepUpdate();

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			if (!restartGame)
				resyncVocals();
		}

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	function moveCameraSection(?id:Int = 0):Void
	{
		if (SONG.notes[id] == null)
			return;

		//todo
		// if (SONG.notes[id].gfSection)
		// {
		// 	camFollow.set(gfFE().getMidpoint().x, gfFE().getMidpoint().y);
		// 	camFollow.x += gf.cameraPosition[0];
		// 	camFollow.y += gf.cameraPosition[1];
		// 	tweenCamIn();
		// 	callOnLuas('onMoveCamera', ['gf']);
		// 	return;
		// }

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, (FlxG.save.data.downscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		songPlayer.midSongEventUpdate(curBeat);

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				FlxG.log.add('CHANGED BPM!');

				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			// else
			// Conductor.changeBPM(SONG.bpm);

			// Dad doesnt interupt his own notes
			if (SONG.notes[Math.floor(curStep / 16)].mustHitSection)
			{
				// if (!playAsDad)
				// dadFE().dance();
			}
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);
		wiggleShit.update(Conductor.crochet);

		//i'll merge this later, lazy shit
		
		//todo
		// if (generatedMusic && SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		// {
		// 	moveCameraSection(Std.int(curStep / 16));
		// }

		// HARDCODING FOR MILF ZOOMS!
		if (curSong.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && camGame.zoom < 1.35)
		{
			// camGame.zoom += 0.005;
			camGame.zoom += 0.015;
		}

		if (camZooming && camGame.zoom < 1.25 && curBeat % 4 == 0)
		{
			camGame.zoom += 0.0075;
			// camHUD.zoom += 0.015;
			songPlayer.playBeatEvent();
		}

		//iconP1.setGraphicSize(Std.int(//iconP1.width + 30));
		//iconP2.setGraphicSize(Std.int(//iconP2.width + 30));

		//iconP1.updateHitbox();
		//iconP2.updateHitbox();

		// if (playAsDad)
		// {
		if (!dadFE().animation.curAnim.name.startsWith("idle") && dadFE().animation.curAnim.finished)
		{
			playAnimAllDad('idle');
		}

		if (!bfFE().animation.curAnim.name.startsWith("idle") && bfFE().animation.curAnim.finished)
		{
			playAnimAllBF('idle');
		}

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	//-----------here we make shit again ----------------------------

	public function playAnimAllBF(anim:String, force:Bool = false, specialAnim:Bool = false)
	{
		if (bfFE() != null && bfFE().visible)
		{
			if (bfFE().animation.getByName(anim) == null)
				return;

			var d = bfFE().animation.getByName(anim);
			var fps = d.frameRate;
			var fc = d.frames == null ? -1 : d.frames.length;

			var animDur = fc / fps;

			if (animDur <= 0)
				return;

			bfFE().specialAnim = specialAnim;
			if (specialAnim)
			{
				bfFE().playAnimForce(anim, animDur);
			}
			else
			{
				bfFE().playAnim(anim, force);
			}
		}

		if (bfPE != null && bfPE.visible)
		{
			bfPE.playAnim(anim, force);
			bfPE.specialAnim = specialAnim;
		}
		// todo
		// add player 4 in bf side yeah fuck you!
		// if (player4 != null && player4.visible)
		// player4.playAnim(anim, force);
	}

	public function playAnimAllDad(anim:String, force:Bool = false, specialAnim:Bool = false)
	{
		if (dadFE() != null && dadFE().visible)
		{
			if (dadFE().animation.getByName(anim) == null)
				return;
		
			var d = dadFE().animation.getByName(anim);
			var fps = d.frameRate;
			var fc = d.frames == null ? -1 : d.frames.length;
			
			var animDur = fc / fps;

			if (animDur <= 0)
				return;


			dadFE().specialAnim = specialAnim;
			if (specialAnim)
			{
				dadFE().playAnimForce(anim, animDur);
			}
			else
			{
				dadFE().playAnim(anim, force);
			}
		}

		if (dadPE != null && dadPE.visible)
		{
			dadPE.playAnim(anim, force);
			dadPE.specialAnim = specialAnim;
		}

		if (player3 != null && player3.visible)
		{
			player3.playAnim(anim, force);
			player3.specialAnim = specialAnim;
		}
	}

	public function playAnimAllGF(anim:String, force:Bool = false, specialAnim:Bool = false)
	{
		if (gfFE() != null && gfFE().visible)
		{
			if (gfFE().animation.getByName(anim) == null)
				return;

			var d = gfFE().animation.getByName(anim);
			var fps = d.frameRate;
			var fc = d.frames == null ? -1 : d.frames.length;

			var animDur = fc / fps;

			if (animDur <= 0)
				return;

			gfFE().specialAnim = specialAnim;
			if (specialAnim)
			{
				gfFE().playAnimForce(anim, animDur);
			}
			else
			{
				gfFE().playAnim(anim, force);
			}
		}
		
		if (gfPE != null && gfPE.visible)
		{
			gfPE.playAnim(anim, force);
			gfPE.specialAnim = specialAnim;
		}
	}

	public function removeAllGF()
	{
		if (gfFE() != null && gfFE().visible)
		{
			gfFE().visible = false;
		}
		if (gfPE != null && gfPE.visible)
		{
			gfPE.visible = false;
		}
	}

	//---------------------------------------------------------------------------------------------------------
}
