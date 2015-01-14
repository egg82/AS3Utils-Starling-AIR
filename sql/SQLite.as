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
	import egg82.objects.CryptoUtil;
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class SQLite {
		//vars
		public const ON_ERROR:Signal = new Signal(String, Object);
		public const ON_CONNECT:Signal = new Signal();
		public const ON_DISCONNECT:Signal = new Signal();
		public const ON_RESULT:Signal = new Signal(SQLResult, Object);
		
		private var file:File;
		private var connection:SQLConnection;
		private var backlog:Vector.<String>;
		private var backlogData:Vector.<Object>;
		private var statement:SQLStatement;
		
		//constructor
		public function SQLite() {
			
		}
		
		//public
		public function connect(dbPath:String, compact:Boolean = true, pass:String = null, passEncryptionKey:String = null):void {
			if (connection) {
				disconnect();
			}
			
			file = new File(dbPath);
			
			if (file.exists && file.isDirectory) {
				file.deleteDirectory(true);
			}
			
			connection = new SQLConnection();
			backlog = new Vector.<String>();
			backlogData = new Vector.<Object>();
			
			var key:ByteArray = null;
			if (pass && pass != "") {
				if (passEncryptionKey) {
					key = CryptoUtil.encryptAes(CryptoUtil.toArray(pass), CryptoUtil.md5(passEncryptionKey));
				} else {
					key = CryptoUtil.toArray(pass);
				}
				
				if (key.length > 16) {
					var buffer:ByteArray = new ByteArray();
					
					buffer.writeBytes(key, 0, 16);
					key = buffer;
				}
			}
			
			connection.addEventListener(SQLErrorEvent.ERROR, onSQLError);
			connection.addEventListener(SQLEvent.OPEN, onOpen);
			connection.addEventListener(SQLEvent.CLOSE, onClose);
			connection.openAsync(file, SQLMode.CREATE, null, compact, 1024, key);
		}
		public function disconnect():void {
			if (!connection) {
				return;
			}
			
			if (statement) {
				statement.cancel();
			}
			
			connection.close();
			statement = null;
			connection = null;
			backlog = null;
			backlogData = null;
			file = null;
		}
		
		public function query(q:String, data:Object = null):void {
			if (!q || q == "") {
				return;
			}
			
			if (!connection.connected || connection.inTransaction) {
				backlog.push(query);
				backlogData.push(data);
			} else {
				backlogData.unshift(data);
				
				statement = new SQLStatement();
				statement.sqlConnection = connection;
				statement.text = q;
				
				statement.addEventListener(SQLErrorEvent.ERROR, onSQLError);
				statement.addEventListener(SQLEvent.RESULT, onResult);
				statement.execute();
			}
		}
		public function get connected():Boolean {
			return (connection) ? connection.connected : false;
		}
		
		//private
		private function onSQLError(e:SQLErrorEvent):void {
			if (!connection) {
				return;
			}
			
			ON_ERROR.dispatch(e.error.message + File.lineEnding + "\tDetails: " + e.error.details, (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
		}
		private function onOpen(e:SQLEvent):void {
			sendNext();
			ON_CONNECT.dispatch();
		}
		private function onClose(e:SQLEvent):void {
			disconnect();
			ON_DISCONNECT.dispatch();
		}
		private function onResult(e:SQLEvent):void {
			if (!connection) {
				return;
			}
			
			ON_RESULT.dispatch(statement.getResult(), (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null);
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