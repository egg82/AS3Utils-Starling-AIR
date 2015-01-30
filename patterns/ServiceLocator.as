/**
 * Copyright (C) egg82 (Alexander Mason) - All Rights Reserved
 * Unauthorized copying of this file, via any medium is strictly prohibited
 * Proprietary and confidential
 * Written by egg82 (Alexander Mason), January 2015
 */

package egg82.patterns {
	import egg82.engines.InputEngine;
	import egg82.engines.SoundEngine;
	import egg82.engines.StateEngine;
	
	/**
	 * ...
	 * @author egg82
	 */
	
	public class ServiceLocator {
		//vars
		private static var services:Array = new Array();
		
		//constructor
		public function ServiceLocator() {
			
		}
		
		//public
		public static function initializeBaseServices():void {
			provideService("input", new InputEngine());
			provideService("sound", new SoundEngine());
			provideService("state", new StateEngine());
		}
		
		public static function getService(type:String):Object {
			return services[type];
		}
		public static function provideService(type:String, obj:Object):void {
			if (services[type]) {
				return;
			}
			
			services[type] = obj;
		}
		
		//private
		
	}
}