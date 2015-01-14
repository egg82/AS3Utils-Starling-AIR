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
	import flash.utils.ByteArray;
	import egg82.mod.Mod;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class ModEngine {
		//vars
		public const ON_ERROR:Signal = new Signal(String, uint);
		public const ON_PROGRESS:Signal = new Signal(Number, Number, uint);
		public const ON_LOADED:Signal = new Signal();
		public const ON_MESSAGE:Signal = new Signal(Object, String, uint);
		
		private var mods:Vector.<Mod> = new Vector.<Mod>();
		private var loaded:Vector.<Boolean> = new Vector.<Boolean>();
		
		//constructor
		public function ModEngine() {
			
		}
		
		//public
		public function load(path:String):uint {
			mods.push(new Mod());
			loaded.push(false);
			
			mods[mods.length - 1].ON_ERROR.add(onError);
			mods[mods.length - 1].ON_PROGRESS.add(onProgress);
			mods[mods.length - 1].ON_LOADED.add(onLoaded);
			mods[mods.length - 1].ON_MESSAGE.add(onMessage);
			mods[mods.length - 1].load(path);
			
			return mods.length - 1;
		}
		public function loadBytes(bytes:ByteArray):uint {
			mods.push(new Mod());
			loaded.push(false);
			
			mods[mods.length - 1].ON_ERROR.add(onError);
			mods[mods.length - 1].ON_PROGRESS.add(onProgress);
			mods[mods.length - 1].ON_LOADED.add(onLoaded);
			mods[mods.length - 1].loadBytes(bytes);
			
			return mods.length - 1;
		}
		public function unload(mod:uint):void {
			if (mod >= mods.length) {
				return;
			}
			
			mods[mod].ON_ERROR.removeAll();
			mods[mod].ON_LOADED.removeAll();
			mods[mod].ON_MESSAGE.removeAll();
			mods[mod].ON_PROGRESS.removeAll();
			
			mods[mod].unload();
			mods.splice(mod, 1);
			loaded.splice(mod, 1);
		}
		
		public function createChannel(name:String):void {
			for (var i:uint = 0; i < mods.length; i++) {
				mods[i].createChannel(name);
			}
		}
		public function removeChannel(name:String):void {
			for (var i:uint = 0; i < mods.length; i++) {
				mods[i].removeChannel(name);
			}
		}
		public function sendMessage(obj:Object, mod:uint, channel:String):void {
			if (mod >= mods.length) {
				return;
			}
			
			mods[mod].sendMessage(obj, channel);
		}
		
		public function get numMods():uint {
			return mods.length;
		}
		
		//private
		private function onError(error:String, mod:Mod):void {
			for (var i:uint = 0; i < mods.length; i++) {
				if (mod === mods[i]) {
					ON_ERROR.dispatch(error, i);
					break;
				}
			}
		}
		private function onProgress(loaded:Number, total:Number, mod:Mod):void {
			for (var i:uint = 0; i < mods.length; i++) {
				if (mod === mods[i]) {
					ON_PROGRESS.dispatch(loaded, total, i);
					break;
				}
			}
		}
		private function onLoaded(mod:Mod):void {
			var allLoaded:Boolean = true;
			for (var i:uint = 0; i < mods.length; i++) {
				if (mod === mods[i]) {
					loaded[i] = true;
				}
				
				if (!loaded[i]) {
					allLoaded = false;
				}
			}
			
			if (allLoaded) {
				ON_LOADED.dispatch();
			}
		}
		private function onMessage(obj:Object, channel:String, mod:Mod):void {
			for (var i:uint = 0; i < mods.length; i++) {
				if (mod === mods[i]) {
					ON_MESSAGE.dispatch(obj, channel, i);
					break;
				}
			}
		}
	}
}