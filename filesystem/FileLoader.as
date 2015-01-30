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

package egg82.filesystem {
	import egg82.events.FileLoaderEvent;
	import egg82.patterns.Observer;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.utils.ByteArray;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class FileLoader {
		//vars
		public static const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		private var stream:FileStream;
		private var _path:String;
		private var _data:ByteArray;
		
		//constructor
		public function FileLoader() {
			
		}
		
		//public
		public function load(path:String):void {
			var file:File = new File(path);
			
			if (!file.exists || file.isDirectory) {
				return;
			}
			
			stream = new FileStream();
			_path = path;
			_data = null;
			
			stream.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			stream.addEventListener(ProgressEvent.PROGRESS, onProgress);
			stream.addEventListener(Event.COMPLETE, onComplete);
			
			stream.openAsync(file, FileMode.READ);
		}
		
		public function get path():String {
			return _path;
		}
		public function get data():ByteArray {
			return _data;
		}
		
		//private
		private function onIOError(e:IOErrorEvent):void {
			stream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			stream.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			stream.removeEventListener(Event.COMPLETE, onComplete);
			stream.close();
			
			dispatch(FileLoaderEvent.ERROR, e.text);
		}
		private function onProgress(e:ProgressEvent):void {
			dispatch(FileLoaderEvent.PROGRESS, {
				"loaded": e.bytesLoaded,
				"total": e.bytesTotal
			});
		}
		private function onComplete(e:Event):void {
			var bytes:ByteArray = new ByteArray();
			
			stream.readBytes(bytes);
			bytes.position = 0;
			
			stream.removeEventListener(IOErrorEvent.IO_ERROR, onIOError);
			stream.removeEventListener(ProgressEvent.PROGRESS, onProgress);
			stream.removeEventListener(Event.COMPLETE, onComplete);
			stream.close();
			
			_data = bytes;
			dispatch(FileLoaderEvent.COMPLETE, bytes);
		}
		
		private function dispatch(event:String, data:Object = null):void {
			Observer.dispatch(OBSERVERS, this, event, data);
		}
	}
}