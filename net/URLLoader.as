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
	import egg82.events.URLLoaderEvent;
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import egg82.patterns.Observer;
	
	/**
	 * ...
	 * @author ...
	 */
	
	public class URLLoader {
		//vars
		public static const OBSERVERS:Vector.<Observer> = new Vector.<Observer>();
		
		private var loader:flash.net.URLLoader = new flash.net.URLLoader();
		private var _loading:Boolean = false;
		
		//constructor
		public function URLLoader() {
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			
			loader.addEventListener(HTTPStatusEvent.HTTP_RESPONSE_STATUS, onResponseStatus);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.addEventListener(Event.COMPLETE, onComplete);
		}
		
		//public
		public function load(url:String):void {
			if (_loading) {
				return;
			}
			
			_loading = true;
			loader.load(new URLRequest(url));
		}
		public function loadRequest(request:URLRequest):void {
			if (_loading) {
				return;
			}
			
			_loading = true;
			loader.load(request);
		}
		
		public function cancel():void {
			if (!_loading) {
				return;
			}
			
			loader.close();
			
			_loading = false;
		}
		
		public function get loading():Boolean {
			return _loading;
		}
		
		//private
		private function onResponseStatus(e:HTTPStatusEvent):void {
			dispatch(URLLoaderEvent.RESPONSE_STATUS, e.status);
		}
		private function onIoError(e:IOErrorEvent):void {
			dispatch(URLLoaderEvent.ERROR, e.text);
		}
		private function onSecurityError(e:SecurityErrorEvent):void {
			dispatch(URLLoaderEvent.ERROR, e.text);
		}
		private function onProgress(e:ProgressEvent):void {
			dispatch(URLLoaderEvent.PROGRESS, {
				"loaded": e.bytesLoaded,
				"total": e.bytesTotal
			});
		}
		private function onComplete(e:Event):void {
			dispatch(URLLoaderEvent.COMPLETE, loader.data);
		}
		
		private function dispatch(event:String, data:Object = null):void {
			Observer.dispatch(OBSERVERS, this, event, data);
		}
	}
}