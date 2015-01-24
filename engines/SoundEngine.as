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
	import flash.events.Event;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import org.as3wavsound.WavSoundChannel;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class SoundEngine {
		//vars
		private static var playingMp3s:Vector.<SoundChannel> = new Vector.<SoundChannel>();
		private static var playingMp3Sounds:Vector.<CustomSound> = new Vector.<CustomSound>();
		
		private static var playingWavs:Vector.<WavSoundChannel> = new Vector.<WavSoundChannel>();
		private static var playingWavSounds:Vector.<CustomWavSound> = new Vector.<CustomWavSound>();
		
		//constructor
		public function SoundEngine() {
			
		}
		
		//public
		public static function playWav(data:ByteArray, repeat:Boolean = false, volume:Number = 1):int {
			if (!data || data.length == 0) {
				return -1;
			}
			
			if (volume > 1) {
				volume = 1;
			}
			if (volume < 0) {
				volume = 0;
			}
			
			var sound:CustomWavSound = new CustomWavSound(data, repeat);
			var channel:WavSoundChannel = sound.play(0, 0, new SoundTransform(volume));
			
			channel.addEventListener(Event.SOUND_COMPLETE, onWavComplete);
			
			playingWavSounds.push(sound);
			playingWavs.push(channel);
			
			return playingWavs.length - 1;
		}
		public static function playMp3(data:ByteArray, repeat:Boolean = false, volume:Number = 1):int {
			if (!data || data.length == 0) {
				return -1;
			}
			
			if (volume > 1) {
				volume = 1;
			}
			if (volume < 0) {
				volume = 0;
			}
			
			var sound:CustomSound = new CustomSound(repeat);
			var channel:SoundChannel;
			
			sound.loadCompressedDataFromByteArray(data, data.length);
			channel = sound.play(0, 0, new SoundTransform(volume));
			channel.addEventListener(Event.SOUND_COMPLETE, onMp3Complete);
			
			playingMp3Sounds.push(sound);
			playingMp3s.push(channel);
			
			return playingMp3s.length - 1;
		}
		
		public static function stopWav(wav:uint):void {
			if (wav >= playingWavs.length) {
				return;
			}
			
			playingWavs[wav].stop();
			playingWavs[wav].removeEventListener(Event.SOUND_COMPLETE, onWavComplete);
			
			playingWavSounds.splice(wav, 1);
			playingWavs.splice(wav, 1);
		}
		public static function stopMp3(mp3:uint):void {
			if (mp3 >= playingMp3s.length) {
				return;
			}
			
			playingMp3s[mp3].stop();
			playingMp3s[mp3].removeEventListener(Event.SOUND_COMPLETE, onMp3Complete);
			
			playingMp3Sounds.splice(mp3, 1);
			playingMp3s.splice(mp3, 1);
		}
		
		public static function getWav(index:uint):CustomWavSound {
			if (index >= playingWavs.length) {
				return null;
			}
			
			return playingWavs[index];
		}
		public static function getMp3(index:uint):CustomSound {
			if (index >= playingMp3s.length) {
				return null;
			}
			
			return playingMp3s[index];
		}
		
		public static function getWavIndex(wav:CustomWavSound):int {
			for (var i:uint = 0; i < playingWavs.length; i++) {
				if (wav === playingWavs[i]) {
					return i;
				}
			}
			
			return -1;
		}
		public static function getMp3Index(mp3:CustomSound):int {
			for (var i:uint = 0; i < playingMp3s.length; i++) {
				if (mp3 === playingMp3s[i]) {
					return i;
				}
			}
			
			return -1;
		}
		
		public static function get numPlayingWavs():uint {
			return playingWavs.length;
		}
		public static function get numPlayingMp3s():uint {
			return playingMp3s.length;
		}
		
		public static function setWavVolume(wav:uint, volume:Number = 1):void {
			if (wav >= playingWavs.length) {
				return;
			}
			
			if (volume > 1) {
				volume = 1;
			}
			if (volume < 0) {
				volume = 0;
			}
			
			//playingWavs[wav].soundTransform = new SoundTransform(volume);
		}
		public static function setMp3Volume(mp3:uint, volume:Number = 1):void {
			if (mp3 >= playingMp3s.length) {
				return;
			}
			
			if (volume > 1) {
				volume = 1;
			}
			if (volume < 0) {
				volume = 0;
			}
			
			playingMp3s[mp3].soundTransform = new SoundTransform(volume);
		}
		
		//private
		private static function onMp3Complete(e:Event):void {
			var channel:SoundChannel = e.target as SoundChannel;
			var sound:CustomSound;
			var soundIndex:uint;
			
			for (var i:uint = 0; i < playingMp3s.length; i++) {
				if (channel === playingMp3s[i]) {
					soundIndex = i;
					break;
				}
			}
			
			sound = playingMp3Sounds[soundIndex];
			
			channel.removeEventListener(Event.SOUND_COMPLETE, onMp3Complete);
			
			if (sound.repeat) {
				playingMp3s[soundIndex] = sound.play();
				playingMp3s[soundIndex].addEventListener(Event.SOUND_COMPLETE, onMp3Complete);
			} else {
				playingMp3Sounds.splice(soundIndex, 1);
				playingMp3s.splice(soundIndex, 1);
			}
		}
		private static function onWavComplete(e:Event):void {
			var channel:WavSoundChannel = e.target as WavSoundChannel;
			var sound:CustomWavSound;
			var soundIndex:uint;
			
			for (var i:uint = 0; i < playingWavs.length; i++) {
				if (channel === playingWavs[i]) {
					soundIndex = i;
					break;
				}
			}
			
			sound = playingWavSounds[soundIndex];
			
			channel.removeEventListener(Event.SOUND_COMPLETE, onWavComplete);
			
			if (sound.repeat) {
				playingWavs[soundIndex] = sound.play();
				playingWavs[soundIndex].addEventListener(Event.SOUND_COMPLETE, onWavComplete);
			} else {
				playingWavSounds.splice(soundIndex, 1);
				playingWavs.splice(soundIndex, 1);
			}
		}
	}
}