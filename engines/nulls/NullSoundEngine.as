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

package egg82.engines.nulls {
	import egg82.custom.CustomSound;
	import egg82.custom.CustomWavSound;
	import egg82.engines.interfaces.ISoundEngine;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class NullSoundEngine implements ISoundEngine {
		//vars
		
		//constructor
		public function NullSoundEngine() {
			
		}
		
		public function playWav(data:ByteArray, repeat:Boolean = false, volume:Number = 1):int {
			return 0;
		}
		public function playMp3(data:ByteArray, repeat:Boolean = false, volume:Number = 1):int {
			return 0;
		}
		
		public function stopWav(wav:uint):void {
			
		}
		public function stopMp3(mp3:uint):void {
			
		}
		
		public function getWav(index:uint):CustomWavSound {
			return null;
		}
		public function getMp3(index:uint):CustomSound {
			return null;
		}
		
		public function getWavIndex(wav:CustomWavSound):int {
			return 0;
		}
		public function getMp3Index(mp3:CustomSound):int {
			return 0;
		}
		
		public function get numPlayingWavs():uint {
			return 0;
		}
		public function get numPlayingMp3s():uint {
			return 0;
		}
		
		public function setWavVolume(wav:uint, volume:Number = 1):void {
			
		}
		public function setMp3Volume(mp3:uint, volume:Number = 1):void {
			
		}
		
		//public
		
		//private
		
	}
}