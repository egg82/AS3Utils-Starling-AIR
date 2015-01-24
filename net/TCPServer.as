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
	import egg82.events.TCPServerEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.OutputProgressEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.ServerSocketConnectEvent;
	import flash.events.TimerEvent;
	import flash.net.ServerSocket;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import egg82.patterns.Observer;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class TCPServer {
		//vars
		public const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		private var server:ServerSocket;
		private var clients:Vector.<Socket> = new Vector.<Socket>();
		
		private var openTimer:Timer = new Timer(17);
		
		//constructor
		public function TCPServer() {
			openTimer.addEventListener(TimerEvent.TIMER, onOpenTimer);
		}
		
		//public
		public function open(port:uint):void {
			if (port > 65535) {
				return;
			}
			
			if (server) {
				close();
			}
			
			server = new ServerSocket();
			try {
				server.bind(port);
				server.listen();
			} catch (ex:Error) {
				dispatch(TCPServerEvent.ERROR, ex.message);
				return;
			}
			
			server.addEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			server.addEventListener(Event.CLOSE, onClose);
			
			openTimer.start();
		}
		public function close():void {
			if (!server) {
				return;
			}
			
			for (var i:uint = 0; i < clients.length; i++) {
				removeListeners(i);
				try {
					clients[i].close();
				} catch (ex:Error) {
					dispatch(TCPServerEvent.ERROR, ex.message);
				}
			}
			
			clients = new Vector.<Socket>();
			
			server.removeEventListener(ServerSocketConnectEvent.CONNECT, onConnect);
			server.removeEventListener(Event.CLOSE, onClose);
			
			try {
				server.close();
			} catch (ex:Error) {
				dispatch(TCPServerEvent.ERROR, ex.message);
			}
			
			openTimer.reset();
			server = null;
			
			dispatch(TCPServerEvent.CLOSED);
		}
		
		public function send(client:uint, data:ByteArray):void {
			if (!data || data.length == 0) {
				return;
			}
			if (client >= clients.length) {
				return;
			}
			
			clients[client].writeBytes(data);
			clients[client].flush();
		}
		public function sendAll(data:ByteArray):void {
			for (var i:uint = 0; i < clients.length; i++) {
				send(i, data);
			}
		}
		
		//private
		private function onConnect(e:ServerSocketConnectEvent):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.socket.localPort && clients[i].localAddress == e.socket.localAddress) {
					clients[i] = e.socket;
					return;
				}
			}
			
			clients[clients.length] = e.socket;
			addListeners(clients.length - 1);
			dispatch(TCPServerEvent.CONNECTION, clients.length - 1);
		}
		private function onClose(e:Event):void {
			close();
		}
		
		private function addListeners(arrayPos:uint):void {
			clients[arrayPos].addEventListener(IOErrorEvent.IO_ERROR, onClientIOError);
			clients[arrayPos].addEventListener(SecurityErrorEvent.SECURITY_ERROR, onClientSecurityError);
			clients[arrayPos].addEventListener(Event.CLOSE, onClientClose);
			clients[arrayPos].addEventListener(Event.CONNECT, onClientConnect);
			clients[arrayPos].addEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onClientOutputProgress);
			clients[arrayPos].addEventListener(ProgressEvent.SOCKET_DATA, onClientData);
		}
		private function removeListeners(arrayPos:uint):void {
			clients[arrayPos].removeEventListener(IOErrorEvent.IO_ERROR, onClientIOError);
			clients[arrayPos].removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onClientSecurityError);
			clients[arrayPos].removeEventListener(Event.CLOSE, onClientClose);
			clients[arrayPos].removeEventListener(Event.CONNECT, onClientConnect);
			clients[arrayPos].removeEventListener(OutputProgressEvent.OUTPUT_PROGRESS, onClientOutputProgress);
			clients[arrayPos].removeEventListener(ProgressEvent.SOCKET_DATA, onClientData);
		}
		
		private function onClientIOError(e:IOErrorEvent):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					removeListeners(i);
					try {
						clients[i].close();
					} catch (ex:Error) {
						dispatch(TCPServerEvent.ERROR, ex.message);
					}
					clients.splice(i, 1);
					
					dispatch(TCPServerEvent.CLIENT_ERROR, {
						"client": i,
						"error": e.text
					});
					
					return;
				}
			}
		}
		private function onClientSecurityError(e:SecurityErrorEvent):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					removeListeners(i);
					try {
						clients[i].close();
					} catch (ex:Error) {
						dispatch(TCPServerEvent.ERROR, ex.message);
					}
					clients.splice(i, 1);
					
					dispatch(TCPServerEvent.CLIENT_ERROR, {
						"client": i,
						"error": e.text
					});
					
					return;
				}
			}
		}
		private function onClientClose(e:Event):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					removeListeners(i);
					clients.splice(i, 1);
					
					dispatch(TCPServerEvent.CLIENT_CLOSED, i);
					
					return;
				}
			}
		}
		private function onClientConnect(e:Event):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					dispatch(TCPServerEvent.CLIENT_CONNECTED, i);
					
					return;
				}
			}
		}
		private function onClientOutputProgress(e:OutputProgressEvent):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					dispatch(TCPServerEvent.CLIENT_UPLOAD_PROGRESS, {
						"client": i,
						"loaded": e.bytesTotal - e.bytesPending,
						"total": e.bytesTotal
					});
					
					return;
				}
			}
		}
		private function onClientData(e:ProgressEvent):void {
			for (var i:uint = 0; i < clients.length; i++) {
				if (clients[i].localPort == e.target.localPort && clients[i].localAddress == e.target.localAddress) {
					if (e.bytesLoaded < e.bytesTotal) {
						dispatch(TCPServerEvent.CLIENT_DOWNLOAD_PROGRESS, {
							"client": i,
							"loaded": e.bytesLoaded,
							"total": e.bytesTotal
						});
						
						return;
					}
					
					var bytes:ByteArray = new ByteArray();
					e.target.readBytes(bytes);
					bytes.position = 0;
					
					checkData(i, bytes);
					
					return;
				}
			}
		}
		
		private function onOpenTimer(e:TimerEvent):void {
			if (!server) {
				openTimer.reset();
				return;
			}
			
			if (server.bound && server.listening) {
				openTimer.reset();
				dispatch(TCPServerEvent.OPENED);
			}
		}
		
		private function checkData(client:uint, data:ByteArray):void {
			var stringData:String;
			var writeString:String;
			var writeData:ByteArray;
			
			stringData = data.readUTFBytes(data.length);
			if (stringData.search("policy-request") > -1) {
				writeData = new ByteArray();
				writeString = "<?xml version=\"1.0\"?>"
				+ "<!DOCTYPE cross-domain-policy SYSTEM \"/xml/dtds/cross-domain-policy.dtd\">"
				+ "<cross-domain-policy>"
					+ "<site-control permitted-cross-domain-policies=\"master-only\"/>"
					+ "<allow-access-from domain=\"*\" to-ports=\"" + server.localPort + "\"/>"
				+ "</cross-domain-policy>\x00";
				
				writeData.writeUTFBytes("Content-Type: application/xml \r\n" + "Content-Length: " + writeString.length + " \r\n" + writeString);
				
				send(client, writeData);
				
				removeListeners(client);
				try {
					clients[client].close();
				} catch (ex:Error) {
					dispatch(TCPServerEvent.ERROR, ex.message);
				}
				clients.splice(client, 1);
			} else {
				data.position = 0;
				dispatch(TCPServerEvent.CLIENT_DATA, {
					"client": client,
					"data": data
				});
			}
		}
		
		private function dispatch(event:String, data:Object = null):void {
			Observer.dispatch(OBSERVERS, this, event, data);
		}
	}
}