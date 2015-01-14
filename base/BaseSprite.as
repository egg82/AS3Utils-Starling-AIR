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

package egg82.base {
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Graphics;
	import starling.display.Sprite;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class BaseSprite extends Sprite {
		//vars
		private const GRAPHICS:Graphics = new Graphics(this as DisplayObjectContainer);
		
		//constructor
		public function BaseSprite() {
			
		}
		
		//public
		public function create():void {
			
		}
		public function update():void {
			for (var i:uint = 0; i < numChildren; i++) {
				var child:DisplayObject = getChildAt(i);
				
				if ("update" in child && child["update"] is Function) {
					(child["update"] as Function).call();
				}
			}
		}
		public function draw():void {
			for (var i:uint = 0; i < numChildren; i++) {
				var child:DisplayObject = getChildAt(i);
				
				if ("draw" in child && child["draw"] is Function) {
					(child["draw"] as Function).call();
				}
			}
		}
		public function runOnce():void {
			
		}
		public function destroy():void {
			removeEventListeners();
			
			for (var i:uint = 0; i < numChildren; i++) {
				var child:DisplayObject = getChildAt(i);
				
				if ("destroy" in child && child["destroy"] is Function) {
					(child["destroy"] as Function).call();
				} else if ("dispose" in child && child["dispose"] is Function) {
					child.dispose();
				}
			}
			
			removeChildren(0, -1, true);
		}
		
		public function get graphics():Graphics {
			return GRAPHICS;
		}
		
		//private
		
	}
}