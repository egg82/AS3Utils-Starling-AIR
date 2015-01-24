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

package egg82.patterns.command {
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author ...
	 */
	
	public class Command {
		//vars
		public const ON_COMPLETE:Signal = new Signal(Object, Object);
		
		private var timer:Timer;
		
		//constructor
		public function Command(delay:Number = 0) {
			if (delay <= 0) {
				return;
			}
			
			if (delay < 17) {
				delay = 17;
			}
			
			timer = new Timer(delay, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimer);
		}
		
		//public
		public function start():void {
			if (timer) {
				timer.start();
				return;
			}
			
			execute();
		}
		
		//private
		protected function execute():void {
			ON_COMPLETE.dispatch(this, null);
		}
		
		private function onTimer(e:TimerEvent):void {
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimer);
			execute();
		}
	}
}