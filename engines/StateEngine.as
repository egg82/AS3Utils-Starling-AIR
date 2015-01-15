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
	import feathers.core.FocusManager;
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
		
		private static var _states:Vector.<Vector.<BaseState>> = new Vector.<Vector.<BaseState>>();
		private static var _windows:Vector.<BaseWindow> = new Vector.<BaseWindow>();
		private static var _updateTimer:Timer = new Timer((1.0 / updateFPS) * 1000.0);
		private static var _drawTimer:Timer = new Timer((1.0 / drawFPS) * 1000.0);
		private static var _runOnce:Boolean;
		
		private static var _deltaTime:Number = 0;
		private static var _lastUpdateTime:Number = getTimer();
		private static var _timestep:Number = updateFPS;
		private static var _fixedTimestepAccumulator:Number;
		
		private static var _inits:Vector.<BaseState> = new Vector.<BaseState>();
		
		//constructor
		public function StateEngine(initState:BaseState) {
			if (!initState) {
				throw new Error("initState cannot be null");
			}
			
			_runOnce = false;
			
			Starling.current.stage.addEventListener(ResizeEvent.RESIZE, onResize);
			
			_fixedTimestepAccumulator = 0;
			_timestep = StateEngine.updateFPS;
			
			addWindow(null, initState);
			Starling.current.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		}
		
		//public
		public static function addState(newState:BaseState, window:uint = 0, addAt:uint = 0):void {
			if (!newState || window >= _windows.length || addAt > _states[window].length) {
				return;
			}
			
			if (Starling.current.context) {
				_updateTimer.stop();
				_drawTimer.stop();
			}
			
			_runOnce = false;
			
			for (var i:uint = 0; i < _states[window].length; i++) {
				_states[window][i].touchable = false;
			}
			
			_states[window].splice(addAt, 0, newState);
			
			if (_windows[window]) {
				_windows[window].starling.stage.addChild(newState);
			} else {
				Starling.current.stage.addChild(newState);
			}
			
			newState.window = _windows[window];
			newState.create();
			InputEngine.update();
			newState.update();
			newState.draw();
			
			if (Starling.current.context) {
				_updateTimer.start();
				_drawTimer.start();
			}
		}
		public static function swapStates(newState:BaseState, window:uint = 0, swapAt:uint = 0):void {
			var oldState:BaseState;
			
			if (!newState || window >= _windows.length || swapAt >= _states[window].length) {
				return;
			}
			
			if (Starling.current.context) {
				_updateTimer.stop();
				_drawTimer.stop();
			}
			
			_runOnce = false;
			
			oldState = _states[window].splice(swapAt, 1)[0];
			oldState.destroy();
			
			if (_windows[window]) {
				_windows[window].starling.stage.removeChild(oldState);
			} else {
				Starling.current.stage.removeChild(oldState);
			}
			
			_states[window].splice(swapAt, 0, newState);
			
			if (_windows[window]) {
				_windows[window].starling.stage.addChild(newState);
			} else {
				Starling.current.stage.addChild(newState);
			}
			
			newState.window = _windows[window];
			newState.create();
			InputEngine.update();
			newState.update();
			newState.draw();
			
			if (Starling.current.context) {
				_updateTimer.start();
				_drawTimer.start();
			}
		}
		public static function removeState(index:uint, window:uint = 0):void {
			var state:BaseState;
			
			if (window >= _windows.length || index >= _states[window].length) {
				return;
			}
			
			state = _states[window].splice(index, 1)[0];
			state.destroy();
			
			if (_windows[window]) {
				_windows[window].starling.stage.removeChild(state);
			} else {
				Starling.current.stage.removeChild(state);
			}
			
			if (_states[window].length > 0) {
				_states[window][0].touchable = true;
			}
		}
		
		public static function getState(index:uint, window:uint = 0):BaseState {
			if (window >= _windows.length || index >= _states[window].length) {
				return null;
			}
			
			return _states[window][index];
		}
		public static function numStates(window:uint = 0):uint {
			if (window >= _windows.length) {
				return 0;
			}
			
			return _states[window].length as uint;
		}
		
		public static function addWindow(window:BaseWindow, initState:BaseState):void {
			if ((!window && _windows.length > 0) || !initState) {
				return;
			}
			
			if (Starling.current.context) {
				_updateTimer.stop();
				_drawTimer.stop();
			}
			
			_runOnce = false;
			
			_windows.push(window);
			_states.push(new Vector.<BaseState>);
			_inits.push(initState);
			
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
			var states:Vector.<BaseState>;
			var init:BaseState;
			
			if (index >= _windows.length || index == 0) {
				return;
			}
			
			window = _windows.splice(index, 1)[0];
			states = _states.splice(index, 1)[0];
			init = _inits.splice(index, 1)[0];
			
			window.starling.stage.removeEventListener(ResizeEvent.RESIZE, onWindowResize);
			
			for (var i:uint = 0; i < states.length; i++) {
				states[i].destroy();
				window.starling.stage.removeChild(states[i]);
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
			if (index >= _windows.length) {
				return null;
			}
			
			return _windows[index];
		}
		public static function get numWindows():uint {
			return _windows.length as uint;
		}
		
		public static function get deltaTime():Number {
			return _deltaTime;
		}
		
		public static function resize(window:uint = 0):void {
			if (window >= _windows.length) {
				return;
			}
			
			if (_windows[window]) {
				_windows[window].starling.stage.dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE, _windows[window].starling.nativeStage.stageWidth, _windows[window].starling.nativeStage.stageHeight));
			} else {
				Starling.current.stage.dispatchEvent(new ResizeEvent(ResizeEvent.RESIZE, Starling.all[0].nativeStage.stageWidth, Starling.all[0].nativeStage.stageHeight));
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
			
			if (!_runOnce) {
				for (i = 0; i < _states.length; i++) {
					_states[i][0].runOnce();
				}
				_runOnce = true;
			}
			
			time = getTimer();
			
			_deltaTime = time - _lastUpdateTime;
			_lastUpdateTime = time;
			
			if (updateFPS < 0) {
				_updateTimer.delay = (1.0 / 60) * 1000.0;
			} else {
				_updateTimer.delay = (1.0 / updateFPS) * 1000.0;
			}
			
			steps = calculateSteps();
			
			InputEngine.update();
			
			for (i = 0; i < _states.length; i++) {
				for (var j:uint = 0; j < _states[i].length; j++) {
					if (j == 0 || _states[i][j].forceUpdate) {
						if (useTimestep) {
							for (var k:uint = 0; k < steps; k++) {
								_states[i][j].update();
							}
						} else {
							_states[i][j].update();
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
				_drawTimer.delay = (1.0 / 60) * 1000.0;
			} else {
				_drawTimer.delay = (1.0 / drawFPS) * 1000.0;
			}
			
			for (var i:uint = 0; i < _states.length; i++) {
				for (var j:uint = 0; j < _states[i].length; j++) {
					if (j == 0 || _states[i][j].forceUpdate) {
						_states[i][j].draw();
					}
				}
			}
		}
		
		private static function calculateSteps():uint {
			var steps:uint;
			
			_fixedTimestepAccumulator += _deltaTime / 1000;
			steps = Math.floor(_fixedTimestepAccumulator / (1 / _timestep));
			
			if (steps > 0) {
				_fixedTimestepAccumulator -= steps * (1 / _timestep);
			}
			
			return steps;
		}
		
		private static function onResize(e:ResizeEvent):void {
			Starling.current.viewPort.width = e.width;
			Starling.current.viewPort.height = e.height;
			
			Starling.current.stage.stageWidth = e.width;
			Starling.current.stage.stageHeight = e.height;
			
			for (var i:uint = 0; i < _states[0].length; i++) {
				_states[0][i].resize();
			}
		}
		private static function onWindowResize(e:ResizeEvent):void {
			var stage:Stage = e.target as Stage;
			var window:uint = 0;
			var i:uint;
			
			for (i = 0; i < _windows.length; i++) {
				if (_windows[i] && _windows[i].starling.stage === stage) {
					window = i;
					break;
				}
			}
			if (window == 0) {
				return;
			}
			
			_windows[window].starling.viewPort.width = e.width;
			_windows[window].starling.viewPort.height = e.height;
			
			_windows[window].starling.stage.stageWidth = e.width;
			_windows[window].starling.stage.stageHeight = e.height;
			
			for (i = 0; i < _states[window].length; i++) {
				_states[window][i].resize();
			}
		}
		
		private static function onContextCreated(e:Event):void {
			Starling.current.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			FocusManager.setEnabledForStage(Starling.all[0].stage, true);
			
			addState(_inits[0]);
			_inits[0] = null;
			
			resize();
			
			_updateTimer.addEventListener(TimerEvent.TIMER, onUpdate);
			_drawTimer.addEventListener(TimerEvent.TIMER, onDraw);
			_updateTimer.start();
			_drawTimer.start();
		}
		private static function onWindowContextCreated(e:Event):void {
			var starling:Starling = e.target as Starling;
			var window:uint = 0;
			
			if (!starling) {
				return;
			}
			
			starling.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
			
			FocusManager.setEnabledForStage(starling.stage, true);
			
			for (var i:uint = 0; i < _windows.length; i++) {
				if (_windows[i] && _windows[i].starling === starling) {
					window = i;
					break;
				}
			}
			if (window == 0) {
				return;
			}
			
			addState(_inits[window], window);
			_inits[window] = null;
			
			resize(window);
			
			if (Starling.current.context) {
				_updateTimer.start();
				_drawTimer.start();
			}
		}
	}
}