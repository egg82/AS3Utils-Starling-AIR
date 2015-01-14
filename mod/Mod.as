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

package egg82.mod {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.MessageChannel;
	import flash.system.Worker;
	import flash.system.WorkerDomain;
	import flash.system.WorkerState;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class Mod {
		//vars
		public const ON_ERROR:Signal = new Signal(String, Mod);
		public const ON_PROGRESS:Signal = new Signal(Mod, Number, Number);
		public const ON_LOADED:Signal = new Signal(Mod);
		public const ON_MESSAGE:Signal = new Signal(Object, String, Mod);
		
		private var loader:URLLoader;
		private var worker:Worker;
		private var incoming:Array;
		private var outgoing:Array;
		
		//constructor
		public function Mod() {
			
		}
		
		//public
		public function load(path:String):void {
			if (loader) {
				unload();
			}
			
			loader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.addEventListener(Event.COMPLETE, onComplete);
			loader.load(new URLRequest(path));
		}
		public function loadBytes(bytes:ByteArray):void {
			if (!bytes || bytes.length == 0) {
				return;
			}
			if (loader) {
				unload();
			}
			
			loader = new URLLoader();
			
			incoming = new Array();
			outgoing = new Array();
			
			worker = WorkerDomain.current.createWorker(bytes, true);
			worker.addEventListener(Event.WORKER_STATE, onWorkerState);
			worker.start();
		}
		public function unload():void {
			if (!loader) {
				return;
			}
			
			if (worker) {
				worker.terminate();
				worker = null;
				incoming = null;
				outgoing = null;
			}
			
			loader.close();
			loader = null;
		}
		
		public function createChannel(name:String):void {
			if (!name || name == "") {
				return;
			}
			if (!worker) {
				return;
			}
			if (incoming[name] || outgoing[name]) {
				return;
			}
			
			incoming[name] = worker.createMessageChannel(Worker.current);
			outgoing[name] = Worker.current.createMessageChannel(worker);
			
			(incoming[name] as MessageChannel).addEventListener(Event.CHANNEL_MESSAGE, onMessage);
			
			worker.setSharedProperty(name + "_incoming", outgoing);
			worker.setSharedProperty(name + "_outgoing", incoming);
		}
		public function removeChannel(name:String):void {
			if (!name || name == "") {
				return;
			}
			if (!worker) {
				return;
			}
			
			if (incoming[name]) {
				worker.setSharedProperty(name + "_outgoing", null);
				(incoming[name] as MessageChannel).removeEventListener(Event.CHANNEL_MESSAGE, onMessage);
				incoming[name] = null;
			}
			if (outgoing[name]) {
				worker.setSharedProperty(name + "_incoming", null);
				outgoing[name] = null;
			}
		}
		public function sendMessage(obj:Object, channel:String):void {
			if (!channel || channel == "") {
				return;
			}
			if (!worker) {
				return;
			}
			if (!outgoing[channel]) {
				return;
			}
			
			(outgoing[channel] as MessageChannel).send(obj);
		}
		
		//private
		private function onIOError(e:IOErrorEvent):void {
			removeListeners();
			ON_ERROR.dispatch(e.text, this);
		}
		private function onSecurityError(e:SecurityErrorEvent):void {
			removeListeners();
			ON_ERROR.dispatch(e.text, this);
		}
		
		private function onProgress(e:ProgressEvent):void {
			ON_PROGRESS.dispatch(e.bytesLoaded, e.bytesTotal, this);
		}
		
		private function onComplete(e:Event):void {
			removeListeners();
			
			incoming = new Array();
			outgoing = new Array();
			
			worker = WorkerDomain.current.createWorker(loader.data as ByteArray, true);
			worker.addEventListener(Event.WORKER_STATE, onWorkerState);
			worker.start();
		}
		
		private function removeListeners():void {
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.removeEventListener(Event.COMPLETE, onComplete);
		}
		
		private function onWorkerState(e:Event):void {
			if (worker.state == WorkerState.RUNNING) {
				ON_LOADED.dispatch(this);
			} else if (worker.state == WorkerState.TERMINATED) {
				worker = null;
				incoming = null;
				outgoing = null;
				
				ON_ERROR.dispatch("Worker terminated unexpectedly.", this);
			}
			
			worker.removeEventListener(Event.WORKER_STATE, onWorkerState);
		}
		
		private function onMessage(e:Event):void {
			for (var key:String in incoming) {
				if (incoming[key] === e.target) {
					ON_MESSAGE.dispatch((e.target as MessageChannel).receive() as Object, key, this);
					return;
				}
			}
		}
	}
}