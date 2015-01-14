/**
 * Copyright (c) 2015 egg82 (Alexander Mason)
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package egg82.engines {
	import egg82.custom.CustomSound;
	import egg82.custom.CustomWavSound;
	import egg82.objects.SoundLoader;
	import flash.events.Event;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import org.as3wavsound.WavSoundChannel;
	import reg.RegOptions;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class SoundEngine {
		//vars
		public static var masterVolume:Number = 1;
		public static var soundVolume:Number = 1;
		public static var musicVolume:Number = 1;
		
		private static var playingMP3s:Vector.<SoundChannel> = new Vector.<SoundChannel>();
		private static var playingMP3Sounds:Vector.<CustomSound> = new Vector.<CustomSound>();
		
		private static var playingWAVs:Vector.<WavSoundChannel> = new Vector.<WavSoundChannel>();
		private static var playingWAVSounds:Vector.<CustomWavSound> = new Vector.<CustomWavSound>();
		
		//constructor
		public function SoundEngine() {
			
		}
		
		//public
		public static function setVolume():void {
			var musicVolume:SoundTransform = new SoundTransform(masterVolume * SoundEngine.musicVolume);
			var soundVolume:SoundTransform = new SoundTransform(masterVolume * SoundEngine.soundVolume);
			var i:uint;
			
			for (i = 0; i < playingMP3s.length; i++) {
				if (playingMP3Sounds[i].name.substring(0, playingMP3Sounds[i].name.indexOf("_")) == "music") {
					playingMP3s[i].soundTransform = musicVolume;
				} else {
					playingMP3s[i].soundTransform = soundVolume;
				}
			}
			/*for (i = 0; i < playingWAVs.length; i++) {
				if (name.substring(0, name.indexOf("_")) == "music") {
					playingWAVs[i].soundTransform = musicVolume;
				} else {
					playingWAVs[i].soundTransform = soundVolume;
				}
			}*/
		}
		
		public static function playWAV(name:String, repeat:Boolean = false):void {
			var sound:CustomWavSound;
			var channel:WavSoundChannel;
			
			if (!SoundLoader.sounds[name]) {
				return;
			}
			
			sound = new CustomWavSound(name, repeat, SoundLoader.sounds[name]);
			sound.id = playingMP3s.length;
			
			if (name.substring(0, name.indexOf("_")) == "music") {
				channel = sound.play(0, 0, new SoundTransform(masterVolume * musicVolume));
			} else {
				channel = sound.play(0, 0, new SoundTransform(masterVolume * soundVolume));
			}
			
			channel.addEventListener(Event.SOUND_COMPLETE, onWAVComplete);
			
			playingWAVSounds.push(sound);
			playingWAVs.push(channel);
		}
		public static function playMP3(name:String, repeat:Boolean = false):void {
			var sound:CustomSound;
			var channel:SoundChannel;
			
			if (!SoundLoader.sounds[name]) {
				return;
			}
			
			sound = new CustomSound(name, repeat);
			sound.loadCompressedDataFromByteArray(SoundLoader.sounds[name], SoundLoader.sounds[name].length);
			sound.id = playingMP3s.length;
			
			if (name.substring(0, name.indexOf("_")) == "music") {
				channel = sound.play(0, 0, new SoundTransform(masterVolume * musicVolume));
			} else {
				channel = sound.play(0, 0, new SoundTransform(masterVolume * soundVolume));
			}
			
			channel.addEventListener(Event.SOUND_COMPLETE, onMP3Complete);
			
			playingMP3Sounds.push(sound);
			playingMP3s.push(channel);
		}
		
		public static function stopMP3(name:String):void {
			for (var i:uint = 0; i < playingMP3s.length; i++) {
				if (playingMP3Sounds[i].name == name) {
					playingMP3s[i].stop();
					playingMP3s[i].removeEventListener(Event.SOUND_COMPLETE, onMP3Complete);
					stopMP3Internal(i);
				}
			}
		}
		public static function stopWAV(name:String):void {
			for (var i:uint = 0; i < playingWAVs.length; i++) {
				if (playingWAVSounds[i].name == name) {
					playingWAVs[i].stop();
					playingWAVs[i].removeEventListener(Event.SOUND_COMPLETE, onWAVComplete);
					stopWAVInternal(i);
				}
			}
		}
		
		//private
		private static function onMP3Complete(e:Event):void {
			var channel:SoundChannel = e.target as SoundChannel;
			var sound:CustomSound;
			
			for (var i:uint = 0; i < playingMP3s.length; i++) {
				if (channel === playingMP3s[i]) {
					break;
				}
			}
			
			sound = playingMP3Sounds[i];
			
			playingMP3s[sound.id].removeEventListener(Event.SOUND_COMPLETE, onMP3Complete);
			
			if (sound.repeat) {
				playingMP3s[sound.id] = sound.play();
				playingMP3s[sound.id].addEventListener(Event.SOUND_COMPLETE, onMP3Complete);
			} else {
				stopMP3Internal(sound.id);
			}
		}
		private static function onWAVComplete(e:Event):void {
			var sound:CustomWavSound = e.target.sound as CustomWavSound;
			
			playingWAVs[sound.id].removeEventListener(Event.SOUND_COMPLETE, onWAVComplete);
			
			if (sound.repeat) {
				playingWAVs[sound.id] = sound.play();
				playingWAVs[sound.id].addEventListener(Event.SOUND_COMPLETE, onWAVComplete);
			} else {
				stopWAVInternal(sound.id);
			}
		}
		
		private static function reshuffleMP3s(beginIndex:uint):void {
			if (beginIndex >= playingMP3s.length || playingMP3s.length == 0) {
				return;
			}
			
			for (var i:uint = beginIndex; i < playingMP3s.length; i++) {
				playingMP3Sounds[i].id = i;
			}
		}
		private static function reshuffleWAVs(beginIndex:uint):void {
			if (beginIndex >= playingWAVs.length || playingWAVs.length == 0) {
				return;
			}
			
			for (var i:uint = beginIndex; i < playingWAVs.length; i++) {
				playingWAVSounds[i].id = i;
			}
		}
		
		private static function stopMP3Internal(index:uint):void {
			playingMP3Sounds.splice(index, 1);
			playingMP3s.splice(index, 1);
			reshuffleMP3s(index);
		}
		private static function stopWAVInternal(index:uint):void {
			playingWAVSounds.splice(index, 1);
			playingWAVs.splice(index, 1);
			reshuffleWAVs(index);
		}
	}
}