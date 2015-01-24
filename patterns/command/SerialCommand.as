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
	
	/**
	 * ...
	 * @author ...
	 */
	
	public class SerialCommand extends Command {
		//vars
		private var commands:Array;
		private var completed:uint;
		private var total:uint;
		
		//constructor
		public function SerialCommand(delay:Number = 0, ...commands) {
			super(delay);
			this.commands = commands;
		}
		
		//public
		
		//private
		override protected function execute():void {
			if (!commands || commands.length == 0) {
				ON_COMPLETE.dispatch(this, null);
				return;
			}
			
			total = 0;
			completed = 0;
			
			var started:Boolean = false;
			
			for each (var obj:Object in commands) {
				total++;
				
				if (!(obj is Command)) {
					completed++;
					continue;
				}
				
				if (!started) {
					var command:Command = obj as Command;
					
					started = true;
					
					command.ON_COMPLETE.addOnce(onComplete);
					command.start();
				}
			}
			
			if (completed == total) {
				ON_COMPLETE.dispatch(this, null);
			}
		}
		
		private function onComplete(sender:Object, data:Object):void {
			completed++;
			
			if (completed == total) {
				ON_COMPLETE.dispatch(this, null);
			}
			
			var i:uint = 0;
			
			for each (var obj:Object in commands) {
				if (i < completed) {
					i++;
					continue;
				}
				
				if (!(obj is Command)) {
					completed++;
					i++;
					continue;
				}
				
				var command:Command = obj as Command;
				
				started = true;
				
				command.ON_COMPLETE.addOnce(onComplete);
				command.start();
				
				return;
			}
			
			if (completed == total) {
				ON_COMPLETE.dispatch(this, null);
			}
		}
	}
}