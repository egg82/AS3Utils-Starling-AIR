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

package egg82.objects {
	import egg82.custom.CustomURLLoader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import org.osflash.signals.Signal;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class SoundLoader {
		//vars
		public static const ON_ERROR:Signal = new Signal(String, String);
		public static const ON_PROGRESS:Signal = new Signal(Number, Number);
		public static const ON_COMPLETE:Signal = new Signal(String);
		
		public static var sounds:Array = new Array();
		
		private static var loaders:Vector.<CustomURLLoader> = new Vector.<CustomURLLoader>();
		
		//constructor
		public function SoundLoader() {
			
		}
		
		//public
		public static function downloadSound(name:String, url:String):void {
			if (!name || !url) {
				return;
			}
			
			loaders.push(new CustomURLLoader(loaders.length, name));
			loaders[loaders.length - 1].addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loaders[loaders.length - 1].addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loaders[loaders.length - 1].addEventListener(ProgressEvent.PROGRESS, onProgress);
			loaders[loaders.length - 1].addEventListener(Event.COMPLETE, onComplete);
			loaders[loaders.length - 1].dataFormat = URLLoaderDataFormat.BINARY;
			loaders[loaders.length - 1].load(new URLRequest(url));
		}
		public static function streamSound(name:String, url:String):void {
			
		}
		public static function loadSound(name:String, bytes:ByteArray):void {
			if (!name || !bytes) {
				return;
			}
			
			sounds[name] = bytes;
		}
		
		//private
		private static function onIOError(e:IOErrorEvent):void {
			var target:CustomURLLoader = e.target as CustomURLLoader;
			
			ON_ERROR.dispatch(target.name, e.text);
			
			sounds[target.name] = null;
			loaders[target.id].close();
			loaders[target.id] = null;
			
			getOverallProgress();
		}
		private static function onSecurityError(e:SecurityErrorEvent):void {
			var target:CustomURLLoader = e.target as CustomURLLoader;
			
			ON_ERROR.dispatch(target.name, e.text);
			
			sounds[target.name] = null;
			loaders[target.id].close();
			loaders[target.id] = null;
			
			getOverallProgress();
		}
		private static function onProgress(e:ProgressEvent):void {
			getOverallProgress();
		}
		private static function onComplete(e:Event):void {
			var target:CustomURLLoader = e.target as CustomURLLoader;
			
			ON_COMPLETE.dispatch(target.name);
			
			sounds[target.name] = target.data;
			loaders[target.id].close();
			loaders[target.id] = null;
			
			getOverallProgress();
		}
		 
		private static function getOverallProgress():void {
			var totalLoaded:Number = 0;
			var totalTotal:Number = 0;
			var foundLoader:Boolean = false;
			
			for (var i:uint = 0; i < loaders.length; i++) {
				if (loaders[i]) {
					totalLoaded += loaders[i].bytesLoaded;
					totalTotal += loaders[i].bytesTotal;
					foundLoader = true;
				}
			}
			
			if (totalTotal != 0) {
				ON_PROGRESS.dispatch(totalLoaded, totalTotal);
			}
			
			if (!foundLoader) {
				ON_COMPLETE.dispatch(null);
			}
		}
	}
}