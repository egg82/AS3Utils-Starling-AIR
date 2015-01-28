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

package egg82.events {
	
	/**
	 * ...
	 * @author ...
	 */
	
	public class TCPServerEvent {
		//vars
		public static const ERROR:String = "error";
		public static const DEBUG:String = "debug";
		public static const OPENED:String = "opened";
		public static const CLOSED:String = "closed";
		public static const CONNECTION:String = "connection";
		public static const CLIENT_ERROR:String = "clientError";
		public static const CLIENT_DISCONNECTED:String = "clientDisconnected";
		public static const CLIENT_CONNECTED:String = "clientConnected";
		public static const CLIENT_UPLOAD_PROGRESS:String = "clientUploadProgress";
		public static const CLIENT_DOWNLOAD_PROGRESS:String = "clientDownloadProgress";
		public static const CLIENT_DATA:String = "clientData";
		
		//constructor
		public function TCPServerEvent() {
			
		}
		
		//public
		
		//private
		
	}
}