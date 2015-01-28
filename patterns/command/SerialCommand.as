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
	import egg82.events.CommandEvent;
	import egg82.patterns.Observer;
	
	/**
	 * ...
	 * @author ...
	 */
	
	public class SerialCommand extends Command {
		//vars
		private var startData:Object;
		private var commands:Array;
		private var completed:uint;
		private var total:uint;
		
		private var commandObserver:Observer = new Observer();
		
		//constructor
		public function SerialCommand(delay:Number = 0, startData:Object = null, ...serializableCommands) {
			super(delay);
			this.startData = startData;
			this.commands = serializableCommands;
			
			commandObserver.add(onCommandObserverNotify);
		}
		
		//public
		
		//private
		override protected function execute():void {
			if (!commands || commands.length == 0) {
				dispatch(CommandEvent.COMPLETE);
				return;
			}
			
			Observer.add(Command.OBSERVERS, commandObserver);
			
			total = 0;
			completed = 0;
			
			var started:Boolean = false;
			
			for each (var obj:Object in commands) {
				total++;
				
				if (!(obj is SerializableCommand)) {
					completed++;
					continue;
				}
				
				if (!started) {
					started = true;
					
					var command:SerializableCommand = obj as SerializableCommand;
					command.startSerialized(startData);
				}
			}
			
			if (completed == total) {
				Observer.remove(Command.OBSERVERS, commandObserver);
				dispatch(CommandEvent.COMPLETE);
			}
		}
		
		private function onCommandObserverNotify(sender:Object, event:String, data:Object):void {
			if (event == CommandEvent.COMPLETE) {
				handleData(sender as Command, data);
			} else if (event == CommandEvent.ERROR) {
				handleError(sender as Command, data);
			}
		}
		
		private function handleData(sender:Command, data:Object):void {
			var obj:Object;
			
			for each (obj in commands) {
				if (!(obj is SerializableCommand)) {
					continue;
				}
				
				if (obj === sender) {
					completed++;
					break;
				}
			}
			
			if (completed == total) {
				Observer.remove(Command.OBSERVERS, commandObserver);
				dispatch(CommandEvent.COMPLETE);
			}
			
			var i:uint = 0;
			
			for each (obj in commands) {
				if (i < completed) {
					i++;
					continue;
				}
				
				if (!(obj is SerializableCommand)) {
					completed++;
					i++;
					continue;
				}
				
				var command:SerializableCommand = obj as SerializableCommand;
				command.startSerialized(data);
				
				return;
			}
			
			if (completed == total) {
				Observer.remove(Command.OBSERVERS, commandObserver);
				dispatch(CommandEvent.COMPLETE);
			}
		}
		
		private function handleError(sender:Command, data:Object):void {
			var obj:Object;
			
			for each (obj in commands) {
				if (!(obj is SerializableCommand)) {
					continue;
				}
				
				if (obj === sender) {
					Observer.remove(Command.OBSERVERS, commandObserver);
					dispatch(CommandEvent.ERROR, data);
					return;
				}
			}
		}
	}
}