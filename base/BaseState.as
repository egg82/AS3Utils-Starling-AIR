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
	import egg82.engines.interfaces.IStateEngine;
	import egg82.patterns.Observer;
	import egg82.patterns.ServiceLocator;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class BaseState extends BaseSprite {
		//vars
		public static const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		public var active:Boolean = true;
		public var forceUpdate:Boolean = false;
		private var _window:BaseWindow = null;
		
		protected var _prevState:BaseState;
		protected var _nextState:BaseState;
		
		private var stateEngine:IStateEngine = ServiceLocator.getService("state") as IStateEngine;
		
		//constructor
		public function BaseState() {
			
		}
		
		//public
		public function resize():void {
			
		}
		
		public function get window():BaseWindow {
			return _window;
		}
		public function set window(val:BaseWindow):void {
			if (!_window && stage != Starling.all[0].stage) {
				_window = val;
			}
		}
		
		//private
		protected final function dispatch(event:String, data:Object = null):void {
			Observer.dispatch(OBSERVERS, this, event, data);
		}
		
		protected function prevState():void {
			if (!_prevState) {
				return;
			}
			
			if (!window) {
				stateEngine.swapStates(_prevState);
			} else {
				for (var i:uint = 0; i < stateEngine.numWindows; i++) {
					if (window === stateEngine.getWindow(i)) {
						stateEngine.swapStates(_prevState, i);
						return;
					}
				}
			}
		}
		protected function nextState():void {
			if (!_nextState) {
				return;
			}
			
			if (!window) {
				stateEngine.swapStates(_nextState);
			} else {
				for (var i:uint = 0; i < stateEngine.numWindows; i++) {
					if (window === stateEngine.getWindow(i)) {
						stateEngine.swapStates(_nextState, i);
						return;
					}
				}
			}
		}
	}
}