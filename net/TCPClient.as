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

package egg82.net {
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class TCPClient {
		//vars
		public const ON_CONNECTED:Signal = new Signal();
		public const ON_ERROR:Signal = new Signal(String);
		public const ON_DATA:Signal = new Signal(ByteArray);
		public const ON_DOWNLOAD_PROGRESS:Signal = new Signal(Number, Number);
		public const ON_UPLOAD_PROGRESS:Signal = new Signal(Number, Number);
		public const ON_COMPLETE:Signal = new Signal();
		public const ON_CLOSE:Signal = new Signal();
		
		private var socket:Socket;
		private var backlog:Vector.<ByteArray>;
		private var sending:Boolean;
		
		//constructor
		public function TCPClient() {
			
		}
		
		//public
		public function connect(host:String, port:uint):void {
			if (socket) {
				disconnect();
			}
			if (port > 65535) {
				return;
			}
			
			socket = new Socket();
			sending = true;
			try {
				socket.connect(host, port);
			}catch (e:Error) {
				ON_ERROR.dispatch(e.message);
				return;
			}
			
			backlog = new Vector.<ByteArray>();
			
			socket.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			socket.addEventListener(Event.CONNECT, onConnect);
			socket.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			socket.addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress);
			socket.addEventListener(Event.CLOSE, onClose);
		}
		public function disconnect():void {
			if (!socket) {
				return;
			}
			
			socket.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			socket.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			socket.removeEventListener(Event.CONNECT, onConnect);
			socket.removeEventListener(ProgressEvent.SOCKET_DATA, onSocketData);
			socket.removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onOutputProgress);
			socket.removeEventListener(Event.CLOSE, onClose);
			
			try {
				socket.close();
			} catch (e:Error) {
				
			}
			
			socket = null;
			backlog = null;
			
			ON_CLOSE.dispatch();
		}
		
		public function send(data:ByteArray):void {
			if (!socket || !data || data.length == 0) {
				return;
			}
			
			if (backlog.length > 0 || sending || !socket.connected) {
				backlog.push(data);
			} else {
				sending = true;
				
				try {
					socket.writeBytes(data);
					socket.flush();
				} catch (e:Error) {
					ON_ERROR.dispatch(e.message);
					return;
				}
			}
		}
		
		//private
		private function onIOError(e:IOErrorEvent):void {
			disconnect();
			ON_ERROR.dispatch(e.text);
		}
		private function onSecurityError(e:SecurityErrorEvent):void {
			disconnect();
			ON_ERROR.dispatch(e.text);
		}
		
		private function onConnect(e:Event):void {
			sending = false;
			
			ON_CONNECTED.dispatch();
			sendNext();
		}
		private function onSocketData(e:ProgressEvent):void {
			ON_DOWNLOAD_PROGRESS.dispatch(e.bytesLoaded, (e.target as Socket).bytesAvailable + (e.target as Socket).bytesPending);
			if (e.bytesLoaded < (e.target as Socket).bytesAvailable + (e.target as Socket).bytesPending) {
				return;
			}
			
			var temp:ByteArray = new ByteArray();
			(e.target as Socket).readBytes(temp);
			temp.position = 0;
			
			ON_DATA.dispatch(temp);
		}
		private function onOutputProgress(e:OutputProgressEvent):void {
			ON_UPLOAD_PROGRESS.dispatch(e.bytesTotal - e.bytesPending, e.bytesTotal);
			
			if (e.bytesPending == 0) {
				ON_COMPLETE.dispatch();
				
				sending = false;
				sendNext();
			}
		}
		private function onClose(e:Event):void {
			disconnect();
		}
		
		private function sendNext():void {
			if (!socket || backlog.length == 0) {
				return;
			}
			
			send(backlog.splice(0, 1)[0]);
		}
	}
}