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
	import egg82.base.BaseWindow;
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import io.arkeus.ouya.controller.GameController;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import io.arkeus.ouya.ControllerInput;
	import org.osflash.signals.Signal;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class InputEngine {
		//vars
		public static const MOUSE_LEFT:String = "mouseLeft";
		public static const MOUSE_MIDDLE:String = "mouseMiddle";
		public static const MOUSE_RIGHT:String = "mouseRight";
		
		public static const ON_KEY_DOWN:Signal = new Signal(Stage, uint);
		public static const ON_KEY_UP:Signal = new Signal(Stage, uint);
		
		public static const ON_BUTTON_DOWN:Signal = new Signal(uint, uint);
		public static const ON_BUTTON_UP:Signal = new Signal(uint, uint);
		
		public static const ON_MOUSE_DOWN:Signal = new Signal(Stage, String);
		public static const ON_MOUSE_UP:Signal = new Signal(Stage, String);
		public static const ON_MOUSE_MOVE:Signal = new Signal(Stage, Point, Point);
		public static const ON_MOUSE_WHEEL:Signal = new Signal(Stage, int);
		
		public static const ON_ACTION:Signal = new Signal(Stage);
		
		private static var _keys:Vector.<Boolean> = new Vector.<Boolean>();
		
		private static var _mouseLocation:Point = new Point();
		private static var _stickProperties:Point = new Point();
		private static var _stickPosition:Point = new Point();
		private static var _mouseWheel:int = 0;
		
		private static var _leftDown:Boolean = false;
		private static var _middleDown:Boolean = false;
		private static var _rightDown:Boolean = false;
		
		private static var _lastStage:Stage = null;
		
		private static var xboxControllers:Vector.<Xbox360Controller> = new Vector.<Xbox360Controller>();
		private static var _lastUsingController:Boolean = false;
		
		//constructor
		public function InputEngine() {
			for (var i:uint = 0; i <= 255; i++) {
				_keys.push(false);
			}
			
			ControllerInput.initialize(Starling.current.nativeStage);
			
			Starling.current.nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Starling.current.nativeStage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			Starling.current.nativeStage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			
			Starling.current.nativeStage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			Starling.current.nativeStage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			Starling.current.nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
		}
		
		//public
		public static function addWindow(window:BaseWindow):void {
			window.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			window.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			window.stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			window.stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			window.stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			window.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			window.stage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			
			window.stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			window.stage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			window.stage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
		}
		public static function removeWindow(window:BaseWindow):void {
			window.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			window.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			window.stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			window.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			window.stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			window.stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			window.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			
			window.stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			window.stage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			window.stage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
		}
		
		public static function isKeyDown(keyCode:uint):Boolean {
			if (keyCode < _keys.length) {
				return _keys[keyCode];
			} else {
				return false;
			}
		}
		public static function isButtonDown(controller:uint, buttonCode:uint):Boolean {
			if (controller >= xboxControllers.length) {
				return false;
			}
			
			if (buttonCode == 0) {
				return xboxControllers[controller].a.held;
			} else if (buttonCode == 1) {
				return xboxControllers[controller].b.held;
			} else if (buttonCode == 2) {
				return xboxControllers[controller].y.held;
			} else if (buttonCode == 3) {
				return xboxControllers[controller].x.held;
			} else if (buttonCode == 4) {
				return xboxControllers[controller].lb.held;
			} else if (buttonCode == 5) {
				return xboxControllers[controller].rb.held;
			} else if (buttonCode == 6) {
				return xboxControllers[controller].leftStick.held;
			} else if (buttonCode == 7) {
				return xboxControllers[controller].rightStick.held;
			} else if (buttonCode == 8) {
				return xboxControllers[controller].start.held;
			} else if (buttonCode == 9) {
				return xboxControllers[controller].back.held;
			} else if (buttonCode == 10) {
				return xboxControllers[controller].dpad.up.held;
			} else if (buttonCode == 11) {
				return xboxControllers[controller].dpad.left.held;
			} else if (buttonCode == 12) {
				return xboxControllers[controller].dpad.down.held;
			} else if (buttonCode == 13) {
				return xboxControllers[controller].dpad.right.held;
			}
			
			return false;
		}
		
		public static function get isLeftMouseDown():Boolean {
			return _leftDown;
		}
		public static function get isMiddleMouseDown():Boolean {
			return _middleDown;
		}
		public static function get isRightMouseDown():Boolean {
			return _rightDown;
		}
		
		public static function get mousePosition():Point {
			return _mouseLocation.clone();
		}
		public static function get mouseWheelPosition():int {
			return _mouseWheel;
		}
		
		public static function get lastStage():Stage {
			return _lastStage;
		}
		
		public static function get numControllers():uint {
			return xboxControllers.length;
		}
		public static function getTrigger(controller:uint, trigger:uint):Number {
			if (controller >= xboxControllers.length || trigger > 1) {
				return 0;
			}
			
			return (trigger == 0) ? xboxControllers[controller].lt.value : xboxControllers[controller].rt.value;
		}
		public static function getStickProperties(controller:uint, stick:uint):Point {
			_stickProperties.x = 0;
			_stickProperties.y = 0;
			
			if (controller >= xboxControllers.length || stick > 1) {
				return _stickProperties.clone();
			}
			
			_stickProperties.x = (stick == 0) ? xboxControllers[controller].leftStick.angle : xboxControllers[controller].rightStick.angle;
			_stickProperties.y = (stick == 0) ? xboxControllers[controller].leftStick.distance : xboxControllers[controller].rightStick.distance;
			
			return _stickProperties.clone();
		}
		public static function getStick(controller:uint, stick:uint):Point {
			_stickPosition.x = 0;
			_stickPosition.y = 0;
			
			if (controller >= xboxControllers.length || stick > 1) {
				return _stickPosition.clone();
			}
			
			_stickPosition.x = (stick == 0) ? xboxControllers[controller].leftStick.x : xboxControllers[controller].rightStick.x;
			_stickPosition.y = (stick == 0) ? xboxControllers[controller].leftStick.y : xboxControllers[controller].rightStick.y;
			
			return _stickPosition.clone();
		}
		
		public static function isUsingController(stickDeadZone:Number):Boolean {
			if (xboxControllers.length == 0) {
				return false;
			}
			
			if (stickDeadZone < 0) {
				stickDeadZone = 0;
			}
			while (stickDeadZone > 1) {
				stickDeadZone /= 10;
			}
			
			for (var i:uint = 0; i < xboxControllers.length; i++) {
				if (getStickProperties(i, 0).y > stickDeadZone) {
					_lastUsingController = true;
					return true;
				} else if (getStickProperties(i, 1).y > stickDeadZone) {
					_lastUsingController = true;
					return true;
				}
				if (getTrigger(i, 0)) {
					_lastUsingController = true;
					return true;
				} else if (getTrigger(i, 1)) {
					_lastUsingController = true;
					return true;
				}
			}
			
			return _lastUsingController;
		}
		
		public static function update():void {
			_mouseWheel = 0;
			controllers();
		}
		
		//private
		private static function controllers():void {
			var i:uint;
			
			while (ControllerInput.hasReadyController()) {
				var addedController:GameController = ControllerInput.getReadyController();
				if (addedController is Xbox360Controller) {
					xboxControllers.push(addedController as Xbox360Controller);
				}
			}
			
			while (ControllerInput.hasRemovedController()) {
				var removedController:GameController = ControllerInput.getRemovedController();
				if (addedController is Xbox360Controller) {
					for (i = 0; i < xboxControllers.length; i++) {
						if (removedController === xboxControllers[i]) {
							xboxControllers.splice(i, 1);
							break;
						}
					}
				}
			}
			
			for (i = 0; i < xboxControllers.length; i++) {
				if (xboxControllers[i].a.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 0);
				} else if (xboxControllers[i].a.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 0);
				}
				
				if (xboxControllers[i].b.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 1);
				} else if (xboxControllers[i].b.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 1);
				}
				
				if (xboxControllers[i].y.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 2);
				} else if (xboxControllers[i].y.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 2);
				}
				
				if (xboxControllers[i].x.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 3);
				} else if (xboxControllers[i].x.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 3);
				}
				
				if (xboxControllers[i].lb.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 4);
				} else if (xboxControllers[i].lb.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 4);
				}
				
				if (xboxControllers[i].rb.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 5);
				} else if (xboxControllers[i].rb.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 5);
				}
				
				if (xboxControllers[i].leftStick.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 6);
				} else if (xboxControllers[i].leftStick.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 6);
				}
				
				if (xboxControllers[i].rightStick.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 7);
				} else if (xboxControllers[i].rightStick.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 7);
				}
				
				if (xboxControllers[i].start.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 8);
				} else if (xboxControllers[i].start.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 8);
				}
				
				if (xboxControllers[i].back.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 9);
				} else if (xboxControllers[i].back.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 9);
				}
				
				if (xboxControllers[i].dpad.up.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 10);
				} else if (xboxControllers[i].dpad.up.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 10);
				}
				
				if (xboxControllers[i].dpad.left.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 11);
				} else if (xboxControllers[i].dpad.left.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 11);
				}
				
				if (xboxControllers[i].dpad.down.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 12);
				} else if (xboxControllers[i].dpad.down.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 12);
				}
				
				if (xboxControllers[i].dpad.right.pressed) {
					_lastUsingController = true;
					ON_BUTTON_DOWN.dispatch(i, 13);
				} else if (xboxControllers[i].dpad.right.released) {
					_lastUsingController = true;
					ON_BUTTON_UP.dispatch(i, 13);
				}
			}
		}
		
		private static function onKeyDown(e:KeyboardEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			
			if (_keys[e.keyCode]) {
				return;
			}
			
			_keys[e.keyCode] = true;
			ON_KEY_DOWN.dispatch(stage, e.keyCode);
			ON_ACTION.dispatch(stage);
		}
		private static function onKeyUp(e:KeyboardEvent):void {
			var stage:Stage = e.target as Stage;
			
			_keys[e.keyCode] = false;
			_lastUsingController = false;
			_lastStage = stage;
			
			ON_KEY_UP.dispatch(stage, e.keyCode);
			ON_ACTION.dispatch(stage);
		}
		
		private static function onMouseMove(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			
			ON_MOUSE_MOVE.dispatch(stage, new Point(_mouseLocation.x, _mouseLocation.y), new Point(e.stageX, e.stageY));
			ON_ACTION.dispatch(stage);
			
			_mouseLocation.x = e.stageX;
			_mouseLocation.y = e.stageY;
		}
		private static function onMouseWheel(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_mouseWheel = e.delta;
			
			ON_MOUSE_WHEEL.dispatch(stage, _mouseWheel);
			ON_ACTION.dispatch(stage);
		}
		
		private static function onMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_leftDown = true;
			
			ON_MOUSE_DOWN.dispatch(stage, MOUSE_LEFT);
			ON_ACTION.dispatch(stage);
		}
		private static function onMiddleMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_middleDown = true;
			
			ON_MOUSE_DOWN.dispatch(stage, MOUSE_MIDDLE);
			ON_ACTION.dispatch(stage);
		}
		private static function onRightMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_rightDown = true;
			
			ON_MOUSE_DOWN.dispatch(stage, MOUSE_RIGHT);
			ON_ACTION.dispatch(stage);
		}
		
		private static function onMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_leftDown = false;
			
			ON_MOUSE_UP.dispatch(stage, MOUSE_LEFT);
			ON_ACTION.dispatch(stage);
		}
		private static function onMiddleMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_middleDown = false;
			
			ON_MOUSE_UP.dispatch(stage, MOUSE_MIDDLE);
			ON_ACTION.dispatch(stage);
		}
		private static function onRightMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			_lastStage = stage;
			_rightDown = false;
			
			ON_MOUSE_UP.dispatch(stage, MOUSE_RIGHT);
			ON_ACTION.dispatch(stage);
		}
	}
}