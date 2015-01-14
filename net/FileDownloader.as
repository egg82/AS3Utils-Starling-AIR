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
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class FileDownloader {
		//vars
		public const ON_OPEN:Signal = new Signal();
		public const ON_ERROR:Signal = new Signal(String);
		public const ON_PROGRESS:Signal = new Signal(Number, Number);
		public const ON_COMPLETE:Signal = new Signal(ByteArray);
		
		private var loader:URLLoader;
		
		//constructor
		public function FileDownloader() {
			
		}
		
		//public
		public function download(file:String):void {
			if (loader) {
				cancel();
			}
			
			loader = new URLLoader();
			loader.addEventListener(Event.OPEN, onOpen);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.addEventListener(Event.COMPLETE, onComplete);
			
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(new URLRequest(file));
		}
		public function cancel():void {
			if (!loader) {
				return;
			}
			
			loader.removeEventListener(Event.OPEN, onOpen);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.removeEventListener(Event.COMPLETE, onComplete);
			
			loader.close();
			loader = null;
		}
		
		//private
		private function onOpen(e:Event):void {
			ON_OPEN.dispatch();
		}
		
		private function onIOError(e:IOErrorEvent):void {
			cancel();
			ON_ERROR.dispatch(e.text);
		}
		private function onSecurityError(e:SecurityErrorEvent):void {
			cancel();
			ON_ERROR.dispatch(e.text);
		}
		
		private function onProgress(e:ProgressEvent):void {
			ON_PROGRESS.dispatch(e.bytesLoaded, e.bytesTotal);
		}
		
		private function onComplete(e:Event):void {
			var bytes:ByteArray = loader.data as ByteArray;
			
			cancel();
			ON_COMPLETE.dispatch(bytes);
		}
	}
}