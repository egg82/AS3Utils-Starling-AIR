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
	import egg82.engines.interfaces.IInputEngine;
	import egg82.enums.MouseEventType;
	import egg82.enums.XboxButtonCodes;
	import egg82.events.InputEngineEvent;
	import egg82.patterns.Observer;
	import flash.display.Stage;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import io.arkeus.ouya.controller.GameController;
	import io.arkeus.ouya.controller.Xbox360Controller;
	import io.arkeus.ouya.ControllerInput;
	import starling.core.Starling;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class InputEngine implements IInputEngine {
		//vars
		public static const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		private var keys:Vector.<Boolean> = new Vector.<Boolean>();
		private var xboxControllers:Vector.<Xbox360Controller> = new Vector.<Xbox360Controller>();
		
		private var _mouseLocation:Point = new Point();
		private var _stickProperties:Point = new Point();
		private var _stickPosition:Point = new Point();
		private var _mouseWheel:int = 0;
		
		private var _leftDown:Boolean = false;
		private var _middleDown:Boolean = false;
		private var _rightDown:Boolean = false;
		
		private var _lastStage:Stage = null;
		
		private var _lastUsingController:Boolean = false;
		
		//constructor
		public function InputEngine() {
			for (var i:uint = 0; i <= 255; i++) {
				keys.push(false);
			}
			
			ControllerInput.initialize(Starling.all[0].nativeStage);
			
			Starling.all[0].nativeStage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			Starling.all[0].nativeStage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			Starling.all[0].nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			Starling.all[0].nativeStage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			Starling.all[0].nativeStage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
		}
		
		//public
		public function addWindow(window:BaseWindow):void {
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
		public function removeWindow(window:BaseWindow):void {
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
		
		public function isKeyDown(keyCode:uint):Boolean {
			if (keyCode < keys.length) {
				return keys[keyCode];
			} else {
				return false;
			}
		}
		public function isButtonDown(controller:uint, buttonCode:uint):Boolean {
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
		
		public function get isLeftMouseDown():Boolean {
			return _leftDown;
		}
		public function get isMiddleMouseDown():Boolean {
			return _middleDown;
		}
		public function get isRightMouseDown():Boolean {
			return _rightDown;
		}
		
		public function get mousePosition():Point {
			return _mouseLocation.clone();
		}
		public function get mouseWheelPosition():int {
			return _mouseWheel;
		}
		
		public function get lastStage():Stage {
			return _lastStage;
		}
		
		public function get numControllers():uint {
			return xboxControllers.length;
		}
		public function getTrigger(controller:uint, trigger:uint):Number {
			if (controller >= xboxControllers.length || trigger > 1) {
				return 0;
			}
			
			return (trigger == 0) ? xboxControllers[controller].lt.value : xboxControllers[controller].rt.value;
		}
		public function getStickProperties(controller:uint, stick:uint):Point {
			_stickProperties.x = 0;
			_stickProperties.y = 0;
			
			if (controller >= xboxControllers.length || stick > 1) {
				return _stickProperties.clone();
			}
			
			_stickProperties.x = (stick == 0) ? xboxControllers[controller].leftStick.angle : xboxControllers[controller].rightStick.angle;
			_stickProperties.y = (stick == 0) ? xboxControllers[controller].leftStick.distance : xboxControllers[controller].rightStick.distance;
			
			return _stickProperties.clone();
		}
		public function getStick(controller:uint, stick:uint):Point {
			_stickPosition.x = 0;
			_stickPosition.y = 0;
			
			if (controller >= xboxControllers.length || stick > 1) {
				return _stickPosition.clone();
			}
			
			_stickPosition.x = (stick == 0) ? xboxControllers[controller].leftStick.x : xboxControllers[controller].rightStick.x;
			_stickPosition.y = (stick == 0) ? xboxControllers[controller].leftStick.y : xboxControllers[controller].rightStick.y;
			
			return _stickPosition.clone();
		}
		
		public function isUsingController(stickDeadZone:Number):Boolean {
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
		
		public function update():void {
			_mouseWheel = 0;
			controllers();
		}
		
		//private
		private function controllers():void {
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
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.A
					});
				} else if (xboxControllers[i].a.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.A
					});
				}
				
				if (xboxControllers[i].b.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.B
					});
				} else if (xboxControllers[i].b.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.B
					});
				}
				
				if (xboxControllers[i].y.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.Y
					});
				} else if (xboxControllers[i].y.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.Y
					});
				}
				
				if (xboxControllers[i].x.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.X
					});
				} else if (xboxControllers[i].x.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.X
					});
				}
				
				if (xboxControllers[i].lb.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.LEFT_BUMPER
					});
				} else if (xboxControllers[i].lb.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.LEFT_BUMPER
					});
				}
				
				if (xboxControllers[i].rb.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT_BUMPER
					});
				} else if (xboxControllers[i].rb.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT_BUMPER
					});
				}
				
				if (xboxControllers[i].leftStick.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.LEFT_STICK
					});
				} else if (xboxControllers[i].leftStick.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.LEFT_STICK
					});
				}
				
				if (xboxControllers[i].rightStick.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT_STICK
					});
				} else if (xboxControllers[i].rightStick.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT_STICK
					});
				}
				
				if (xboxControllers[i].start.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.START
					});
				} else if (xboxControllers[i].start.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.START
					});
				}
				
				if (xboxControllers[i].back.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.BACK
					});
				} else if (xboxControllers[i].back.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.BACK
					});
				}
				
				if (xboxControllers[i].dpad.up.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.UP
					});
				} else if (xboxControllers[i].dpad.up.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.UP
					});
				}
				
				if (xboxControllers[i].dpad.left.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.LEFT
					});
				} else if (xboxControllers[i].dpad.left.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.LEFT
					});
				}
				
				if (xboxControllers[i].dpad.down.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.DOWN
					});
				} else if (xboxControllers[i].dpad.down.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.DOWN
					});
				}
				
				if (xboxControllers[i].dpad.right.pressed) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_DOWN, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT
					});
				} else if (xboxControllers[i].dpad.right.released) {
					_lastUsingController = true;
					dispatch(InputEngineEvent.BUTTON_UP, {
						"controller": i,
						"button": XboxButtonCodes.RIGHT
					});
				}
			}
		}
		
		private function onKeyDown(e:KeyboardEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			
			if (keys[e.keyCode]) {
				return;
			}
			
			keys[e.keyCode] = true;
			dispatch(InputEngineEvent.KEY_DOWN, {
				"stage": stage,
				"keyCode": e.keyCode
			});
		}
		private function onKeyUp(e:KeyboardEvent):void {
			var stage:Stage = e.target as Stage;
			
			keys[e.keyCode] = false;
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			
			dispatch(InputEngineEvent.KEY_UP, {
				"stage": stage,
				"keyCode": e.keyCode
			});
		}
		
		private function onMouseMove(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			
			var oldPoint:Point = new Point(_mouseLocation.x, _mouseLocation.y);
			
			_mouseLocation.x = e.stageX;
			_mouseLocation.y = e.stageY;
			
			dispatch(InputEngineEvent.MOUSE_MOVE, {
				"stage": stage,
				"oldPoint": oldPoint,
				"newPoint": new Point(e.stageX, e.stageY)
			});
		}
		private function onMouseWheel(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_mouseWheel = e.delta;
			
			dispatch(InputEngineEvent.MOUSE_WHEEL, {
				"stage": stage,
				"value": _mouseWheel
			});
		}
		
		private function onMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_leftDown = true;
			
			dispatch(InputEngineEvent.MOUSE_DOWN, {
				"stage": stage,
				"type": MouseEventType.LEFT
			});
		}
		private function onMiddleMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_middleDown = true;
			
			dispatch(InputEngineEvent.MOUSE_DOWN, {
				"stage": stage,
				"type": MouseEventType.MIDDLE
			});
		}
		private function onRightMouseDown(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_rightDown = true;
			
			dispatch(InputEngineEvent.MOUSE_DOWN, {
				"stage": stage,
				"type": MouseEventType.RIGHT
			});
		}
		
		private function onMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_leftDown = false;
			
			dispatch(InputEngineEvent.MOUSE_UP, {
				"stage": stage,
				"type": MouseEventType.LEFT
			});
		}
		private function onMiddleMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_middleDown = false;
			
			dispatch(InputEngineEvent.MOUSE_UP, {
				"stage": stage,
				"type": MouseEventType.MIDDLE
			});
		}
		private function onRightMouseUp(e:MouseEvent):void {
			var stage:Stage = e.target as Stage;
			
			_lastUsingController = false;
			if (stage) {
				_lastStage = stage;
			}
			_rightDown = false;
			
			dispatch(InputEngineEvent.MOUSE_UP, {
				"stage": stage,
				"type": MouseEventType.RIGHT
			});
		}
		
		private function dispatch(event:String, data:Object):void {
			Observer.dispatch(OBSERVERS, null, event, data);
		}
	}
}