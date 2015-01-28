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
	import egg82.base.BaseState;
	import egg82.base.BaseWindow;
	import flash.events.TimerEvent;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import starling.core.Starling;
	import starling.display.Stage;
	import starling.events.Event;
	import starling.events.ResizeEvent;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class StateEngine {
		//vars
		public static var updateFPS:Number = 60.0;
		public static var drawFPS:Number = 60.0;
		public static var useTimestep:Boolean = true;
		
		private static var states:Vector.<Vector.<BaseState>> = new Vector.<Vector.<BaseState>>();
		private static var windows:Vector.<BaseWindow> = new Vector.<BaseWindow>();
		private static var updateTimer:Timer = new Timer((1.0 / updateFPS) * 1000.0);
		private static var drawTimer:Timer = new Timer((1.0 / drawFPS) * 1000.0);
		private static var runOnce:Boolean;
		
		private static var _deltaTime:Number = 0;
		private static var lastUpdateTime:Number = getTimer();
		private static var timestep:Number = updateFPS;
		private static var fixedTimestepAccumulator:Number;
		
		private static var inits:Vector.<BaseState> = new Vector.<BaseState>();
		
		//constructor
		public function StateEngine(initState:BaseState) {
			if (!initState) {
				throw new Error("initState cannot be null");
			}
			
			runOnce = false;
			
			Starling.all[0].stage.addEventListener(ResizeEvent.RESIZE, onResize);
			
			fixedTimestepAccumulator = 0;
			timestep = StateEngine.updateFPS;
			
			addWindow(null, initState);
			Starling.all[0].addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		}
		
		//public
		public static function addState(newState:BaseState, window:uint = 0, addAt:uint = 0):void {
			if (!newState || window >= windows.length || addAt > states[window].length) {
				return;
			}
			
			if (Starling.all[0].context) {
				updateTimer.stop();
				drawTimer.stop();
			}
			
			runOnce = false;
			
			for (var i:uint = 0; i < states[window].length; i++) {
				states[window][i].touchable = false;
			}
			
			states[window].splice(addAt, 0, newState);
			
			if (windows[window]) {
				windows[window].starling.stage.addChild(newState);
			} else {
				Starling.all[0].stage.addChild(newState);
			}
			
			newState.window = windows[window];
			newState.create();
			InputEngine.update();
			newState.update();
			newState.draw();
			
			if (Starling.all[0].context) {
				updateTimer.start();
				drawTimer.start();
			}
		}
		public static function swapStates(newState:BaseState, window:uint = 0, swapAt:uint = 0):void {
			var oldState:BaseState;
			
			if (!newState || window >= windows.length || swapAt >= states[window].length) {
				return;
			}
			
			if (Starling.all[0].context) {
				updateTimer.stop();
				drawTimer.stop();
			}
			
			runOnce = false;
			
			oldState = states[window].splice(swapAt, 1)[0];
			oldState.destroy();
			
			if (windows[window]) {
				windows[window].starling.stage.removeChild(oldState);
			} else {
				Starling.all[0].stage.removeChild(oldState);
			}
			
			states[window].splice(swapAt, 0, newState);
			
			if (windows[window]) {
				windows[window].starling.stage.addChild(newState);
			} else {
				Starling.all[0].stage.addChild(newState);
			}
			
			newState.window = windows[window];
			newState.create();
			InputEngine.update();
			newState.update();
			newState.draw();
			
			if (Starling.all[0].context) {
				updateTimer.start();
				drawTimer.start();
			}
		}
		public static function removeState(index:uint, window:uint = 0):void {
			var state:BaseState;
			
			if (window >= windows.length || index >= states[window].length) {
				return;
			}
			
			state = states[window].splice(index, 1)[0];
			state.destroy();
			
			if (windows[window]) {
				windows[window].starling.stage.removeChild(state);
			} else {
				Starling.all[0].stage.removeChild(state);
			}
			
			if (states[window].length > 0) {
				states[window][0].touchable = true;
			}
		}
		
		public static function getState(index:uint, window:uint = 0):BaseState {
			if (window >= windows.length || index >= states[window].length) {
				return null;
			}
			
			return states[window][index];
		}
		public static function numStates(window:uint = 0):uint {
			if (window >= windows.length) {
				return 0;
			}
			
			return states[window].length as uint;
		}
		
		public static function addWindow(window:BaseWindow, initState:BaseState):void {
			if ((!window && windows.length > 0) || !initState) {
				return;
			}
			
			if (Starling.all[0].context) {
				updateTimer.stop();
				drawTimer.stop();
			}
			
			runOnce = false;
			
			windows.push(window);
			states.push(new Vector.<BaseState>);
			inits.push(initState);
			
			if (window) {
				InputEngine.addWindow(window);
				
				window.activate();
				window.create();
				
				window.starling.stage.addEventListener(ResizeEvent.RESIZE, onWindowResize);
				window.starling.addEventListener(Event.CONTEXT3D_CREATE, onWindowContextCreated);
			}
		}
		public static function removeWindow(index:uint):void {
			var window:BaseWindow;
			var tStates:Vector.<BaseState>;
			var init:BaseState;
			
			if (index >= windows.length || index == 0) {
				return;
			}
			
			window = windows.splice(index, 1)[0];
			tStates = states.splice(index, 1)[0];
			init = inits.splice(index, 1)[0];
			
			window.starling.stage.removeEventListener(ResizeEvent.RESIZE, onWindowResize);
			
			for (var i:uint = 0; i < tStates.length; i++) {
				tStates[i].destroy();
				window.starling.stage.removeChild(tStates[i]);
			}
			if (init) {
				init.destroy();
				window.starling.stage.removeChild(init);
			}
			
			InputEngine.removeWindow(window);
			
			window.destroy();
			window.close();
		}
		
		public static function getWindow(index:uint):BaseWindow {
			if (index >= windows.length) {
				return null;
			}
			
			return windows[index];
		}
		public static function get numWindows():uint {
			return windows.length as uint;
		}
		
		public static function get deltaTime():Number {
			return _deltaTime;
		}
		
		public static function resize(window:uint = 0):void {
			if (window >= windows.length) {
				return;
			}
			
			if (windows[window]) {
				windows[window].starling.stage.dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE, windows[window].starling.nativeStage.stageWidth, windows[window].starling.nativeStage.stageHeight));
			} else {
				Starling.all[0].stage.dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE, Starling.all[0].nativeStage.stageWidth, Starling.all[0].nativeStage.stageHeight));
			}
		}
		
		//private
		private static function onUpdate(e:TimerEvent):void {
			var time:Number;
			var steps:uint;
			var i:uint;
			
			if (!updateFPS) {
				return;
			}
			
			if (!runOnce) {
				for (i = 0; i < states.length; i++) {
					states[i][0].runOnce();
				}
				runOnce = true;
			}
			
			time = getTimer();
			
			_deltaTime = time - lastUpdateTime;
			lastUpdateTime = time;
			
			if (updateFPS < 0) {
				updateTimer.delay = (1.0 / 60) * 1000.0;
			} else {
				updateTimer.delay = (1.0 / updateFPS) * 1000.0;
			}
			
			steps = calculateSteps();
			
			InputEngine.update();
			
			for (i = 0; i < states.length; i++) {
				for (var j:uint = 0; j < states[i].length; j++) {
					if (j == 0 || states[i][j].forceUpdate) {
						if (useTimestep) {
							for (var k:uint = 0; k < steps; k++) {
								if (states[i][j].active) {
									states[i][j].update();
								}
							}
						} else {
							if (states[i][j].active) {
								states[i][j].update();
							}
						}
					}
				}
			}
		}
		private static function onDraw(e:TimerEvent):void {
			if (!drawFPS) {
				return;
			}
			
			if (drawFPS < 0) {
				drawTimer.delay = (1.0 / 60) * 1000.0;
			} else {
				drawTimer.delay = (1.0 / drawFPS) * 1000.0;
			}
			
			for (var i:uint = 0; i < states.length; i++) {
				for (var j:uint = 0; j < states[i].length; j++) {
					if (j == 0 || states[i][j].forceUpdate) {
						if (states[i][j].active) {
							states[i][j].draw();
						}
					}
				}
			}
		}
		
		private static function calculateSteps():uint {
			var steps:uint;
			
			fixedTimestepAccumulator += _deltaTime / 1000;
			steps = Math.floor(fixedTimestepAccumulator / (1 / timestep));
			
			if (steps > 0) {
				fixedTimestepAccumulator -= steps * (1 / timestep);
			}
			
			return steps;
		}
		
		private static function onResize(e:ResizeEvent):void {
			Starling.all[0].viewPort.width = e.width;
			Starling.all[0].viewPort.height = e.height;
			
			Starling.all[0].stage.stageWidth = e.width;
			Starling.all[0].stage.stageHeight = e.height;
			
			for (var i:uint = 0; i < states[0].length; i++) {
				states[0][i].resize();
			}
		}
		private static function onWindowResize(e:ResizeEvent):void {
			var stage:Stage = e.target as Stage;
			var window:uint = 0;
			var i:uint;
			
			for (i = 0; i < windows.length; i++) {
				if (windows[i] && windows[i].starling.stage === stage) {
					window = i;
					break;
				}
			}
			if (window == 0) {
				return;
			}
			
			windows[window].starling.viewPort.width = e.width;
			windows[window].starling.viewPort.height = e.height;
			
			windows[window].starling.stage.stageWidth = e.width;
			windows[window].starling.stage.stageHeight = e.height;
			
			for (i = 0; i < states[window].length; i++) {
				states[window][i].resize();
			}
		}
		
		private static function onContextCreated(e:Event):void {
			Starling.all[0].removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			addState(inits[0]);
			inits[0] = null;
			
			resize();
			
			updateTimer.addEventListener(TimerEvent.TIMER, onUpdate);
			drawTimer.addEventListener(TimerEvent.TIMER, onDraw);
			updateTimer.start();
			drawTimer.start();
		}
		private static function onWindowContextCreated(e:Event):void {
			var starling:Starling = e.target as Starling;
			var window:uint = 0;
			
			if (!starling) {
				return;
			}
			
			starling.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			for (var i:uint = 0; i < windows.length; i++) {
				if (windows[i] && windows[i].starling === starling) {
					window = i;
					break;
				}
			}
			if (window == 0) {
				return;
			}
			
			addState(inits[window], window);
			inits[window] = null;
			
			resize(window);
			
			if (Starling.all[0].context) {
				updateTimer.start();
				drawTimer.start();
			}
		}
	}
}