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

package egg82.base {
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.ProgressEvent;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class BasePreloader extends Sprite {
		//vars
		public const ON_PROGRESS:Signal = new Signal(Number, Number);
		public const ON_COMPLETE:Signal = new Signal();
		
		private var _loaded:Number = 0;
		private var _total:Number = 0;
		
		private var _main:Class;
		
		//constructor
		public function BasePreloader(main:Class) {
			if (!main) {
				throw new Error("main cannot be null");
			}
			
			loaderInfo.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loaderInfo.addEventListener(Event.COMPLETE, onComplete);
			
			_main = main;
		}
		
		//public
		public function get loaded():Number {
			return _loaded;
		}
		public function get total():Number {
			return _total;
		}
		
		//private
		private function onProgress(e:ProgressEvent):void {
			_loaded = e.bytesLoaded;
			_total = e.bytesTotal;
			
			ON_PROGRESS.dispatch(_loaded, _total);
		}
		private function onComplete(e:Event):void {
			ON_COMPLETE.dispatch();
			addChild(new _main() as DisplayObject);
		}
	}
}