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
	import egg82.events.SQLiteEvent;
	import egg82.objects.CryptoUtil;
	import egg82.patterns.Observer;
	import flash.data.SQLConnection;
	import flash.data.SQLMode;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.events.SQLErrorEvent;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class SQLite {
		//vars
		public static const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		private var file:File;
		private var connection:SQLConnection = new SQLConnection();
		private var backlog:Vector.<String>;
		private var backlogData:Vector.<Object>;
		private var statement:SQLStatement;
		private var sending:Boolean;
		
		//constructor
		public function SQLite() {
			connection.addEventListener(SQLErrorEvent.ERROR, onConnectionError);
			connection.addEventListener(SQLEvent.OPEN, onOpen);
			connection.addEventListener(SQLEvent.CLOSE, onClose);
		}
		
		//public
		public function connect(dbPath:String, compact:Boolean = true, pass:String = null, passEncryptionKey:String = null):void {
			if (!dbPath || dbPath == "" || connection.connected) {
				return;
			}
			
			sending = true;
			
			file = new File(dbPath);
			
			if (!file.exists || file.isDirectory) {
				return;
			}
			
			var key:ByteArray = null;
			if (pass && pass != "") {
				if (passEncryptionKey) {
					key = CryptoUtil.encryptAes(CryptoUtil.toArray(pass), CryptoUtil.hashMd5(passEncryptionKey));
				} else {
					key = CryptoUtil.toArray(pass);
				}
				
				if (key.length > 16) {
					var buffer:ByteArray = new ByteArray();
					
					buffer.writeBytes(key, 0, 16);
					key = buffer;
				}
			}
			
			connection.openAsync(file, SQLMode.CREATE, null, compact, 1024, key);
			
			backlog = new Vector.<String>();
			backlogData = new Vector.<Object>();
		}
		public function disconnect():void {
			if (!connection.connected) {
				return;
			}
			
			if (statement) {
				statement.cancel();
			}
			
			connection.close();
			statement = null;
			backlog = null;
			backlogData = null;
			file = null;
			
			dispatch(SQLiteEvent.DISCONNECTED);
		}
		
		public function query(q:String, data:Object = null):void {
			if (!connection.connected || !q || q == "") {
				return;
			}
			
			if (sending || backlog.length > 0) {
				backlog.push(query);
				backlogData.push(data);
			} else {
				sending = true;
				
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
			return connection.connected;
		}
		
		//private
		private function onConnectionError(e:SQLErrorEvent):void {
			dispatch(SQLiteEvent.ERROR, {
				"error": e.error.message + File.lineEnding + "\tDetails: " + e.error.details,
				"data": null
			});
			disconnect();
		}
		private function onSQLError(e:SQLErrorEvent):void {
			dispatch(SQLiteEvent.ERROR, {
				"error": e.error.message + File.lineEnding + "\tDetails: " + e.error.details,
				"data": (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null
			});
		}
		private function onOpen(e:SQLEvent):void {
			sending = false;
			
			dispatch(SQLiteEvent.CONNECTED);
			sendNext();
		}
		private function onClose(e:SQLEvent):void {
			if (statement) {
				statement.cancel();
			}
			
			statement = null;
			backlog = null;
			backlogData = null;
			file = null;
			
			dispatch(SQLiteEvent.DISCONNECTED);
		}
		private function onResult(e:SQLEvent):void {
			var result:SQLResult = statement.getResult();
			
			dispatch(SQLiteEvent.RESULT, {
				"result": new MySQLResult(result.data, result.lastInsertRowID, result.rowsAffected),
				"data": (backlogData.length > 0) ? backlogData.splice(0, 1)[0] : null
			});
			
			sending = false;
			sendNext();
		}
		
		private function sendNext():void {
			if (backlog.length == 0) {
				return;
			}
			
			query(backlog.splice(0, 1)[0], backlogData.splice(0, 1)[0]);
		}
		
		private function dispatch(event:String, data:Object = null):void {
			Observer.dispatch(OBSERVERS, this, event, data);
		}
	}
}