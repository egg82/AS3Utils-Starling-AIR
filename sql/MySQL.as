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

package egg82.sql {
	import com.maclema.mysql.Connection;
	import com.maclema.mysql.events.MySqlErrorEvent;
	import com.maclema.mysql.events.MySqlEvent;
	import com.maclema.mysql.MySqlToken;
	import com.maclema.mysql.ResultSet;
	import com.maclema.mysql.Statement;
	import egg82.objects.Util;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class MySQL {
		//vars
		public const ON_ERROR:Signal = new Signal(String, Object);
		public const ON_CONNECT:Signal = new Signal();
		public const ON_DISCONNECT:Signal = new Signal();
		public const ON_RESULT:Signal = new Signal(MySqlEvent, Object);
		
		private var connection:Connection;
		private var backlog:Vector.<String>;
		private var backlogData:Vector.<Object>;
		
		//constructor
		public function MySQL() {
			
		}
		
		//public
		public function connect(host:String, user:String, pass:String, db:String, port:uint = 3306, policyPort:uint = 80):void {
			if (port > 65535) {
				return;
			}
			
			if (connection) {
				disconnect();
			}
			
			Util.loadPolicyFile(host, policyPort);
			connection = new Connection(host, port, user, pass, db);
			backlog = new Vector.<String>();
			backlogData = new Vector.<Object>();
			
			connection.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			connection.addEventListener(MySqlErrorEvent.SQL_ERROR, onSQLError);
			connection.addEventListener(Event.CONNECT, onConnect);
			connection.addEventListener(Event.CLOSE, onClose);
			connection.connect();
		}
		public function disconnect():void {
			if (!connection) {
				return;
			}
			
			connection.disconnect();
			connection = null;
			backlog = null;
			backlogData = null;
		}
		public function query(q:String, data:Object = null):void {
			if (!q || q == "") {
				return;
			}
			
			if (!connection.connected || connection.busy) {
				backlog.push(query);
				backlogData.push(data);
			} else {
				backlogData.unshift(data);
				
				var statement:Statement = connection.createStatement();
				var token:MySqlToken = statement.executeQuery(q);
				
				token.addEventListener(MySqlErrorEvent.SQL_ERROR, onSQLError);
				token.addEventListener(MySqlEvent.RESULT, onResult);
				token.addEventListener(MySqlEvent.RESPONSE, onResponse);
			}
		}
		
		public function get connected():Boolean {
			return (connection) ? connection.connected : false;
		}
		
		//private
		private function onIOError(e:IOErrorEvent):void {
			if (!connection) {
				return;
			}
			
			ON_ERROR.dispatch(e.text, (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
		}
		private function onSQLError(e:MySqlErrorEvent):void {
			if (!connection) {
				return;
			}
			
			ON_ERROR.dispatch(e.msg, (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
		}
		private function onConnect(e:Event):void {
			sendNext();
			ON_CONNECT.dispatch();
		}
		private function onClose(e:Event):void {
			disconnect();
			ON_DISCONNECT.dispatch();
		}
		
		private function onResponse(e:MySqlEvent):void {
			if (!connection) {
				return;
			}
			
			ON_RESULT.dispatch(e, (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
			sendNext();
		}
		private function onResult(e:MySqlEvent):void {
			if (!connection) {
				return;
			}
			
			ON_RESULT.dispatch(e, (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
			sendNext();
		}
		
		private function sendNext():void {
			if (!connection || backlog.length == 0) {
				return;
			}
			
			query(backlog.splice(0, 1)[0], backlogData.splice(0, 1)[0]);
		}
	}
}