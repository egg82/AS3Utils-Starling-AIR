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
	import egg82.engines.StateEngine;
	import flash.display.NativeWindow;
	import flash.display.NativeWindowInitOptions;
	import flash.display.NativeWindowSystemChrome;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import org.osflash.signals.Signal;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class BaseWindow extends NativeWindow {
		//vars
		public const ON_CLOSING:Signal = new Signal();
		
		private var _starling:Starling = null;
		
		//constructor
		public function BaseWindow(bounds:Rectangle, resizable:Boolean = false, border:Boolean = true) {
			var options:NativeWindowInitOptions = new NativeWindowInitOptions();
			
			options.systemChrome = (border) ? NativeWindowSystemChrome.STANDARD : NativeWindowSystemChrome.NONE;
			options.renderMode = Starling.all[0].nativeStage.nativeWindow.renderMode;
			options.resizable = resizable;
			
			super(options);
			
			if (!bounds) {
				return;
			}
			
			this.bounds = bounds;
			addEventListener(Event.CLOSING, onClosing);
		}
		
		//public
		public function create():void {
			_starling = new Starling(BaseSprite, stage);
			_starling.start();
		}
		public function destroy():void {
			_starling.stop();
			_starling.dispose();
		}
		
		public function get starling():Starling {
			return _starling;
		}
		
		//private
		private function onClosing(e:Event):void {
			for (var i:uint = 0; i < StateEngine.numWindows; i++) {
				if (StateEngine.getWindow(i) === this) {
					StateEngine.removeWindow(i);
					break;
				}
			}
			
			ON_CLOSING.dispatch();
		}
	}
}