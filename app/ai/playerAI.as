﻿/******************************************************************************
Copyright (c) 2009 Doug Jenkins

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*******************************************************************************/


package app.ai {
	import flash.events.*;
	
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.baseClasses.realMover;
	import app.baseClasses.fighterHanger;
	
	public class playerAI extends Object {
	
		private var oGL:gameloader;
		private var faction:String;
		private var assetArray:Array = new Array();
		
		
		//
		///-- Constructor --///
		//
		
		public function playerAI(oGL:gameloader, sFaction:String):void {
			this.oGL = oGL;
			this.faction = sFaction;
			
			this.oGL.addEventListener('gameLoaded', onGameLoaded);
		}
		
		//
		///-- Private Methods --///
		//
		
		//
		///-- Event Listeners --///
		//
		
		private function onGameLoaded(e:Event):void {
			// collect our faction's objects
			for each (var obj:Object in this.oGL.objectArray) {
				if ((obj is realMover || obj is fighterHanger) 
					&& obj.faction == this.faction)
				{
					this.assetArray.push(obj);
					
					// hack
					var bIsMiner:Boolean = false;
					var bIsAggressive:Boolean = false;
					
					if (obj.hasOwnProperty('mods')) {
						for each (var module:Object in obj.mods.externalModuleArray) {
							if (module.name == 'miningLaserSM') { bIsMiner = true; }
							if (module.name == 'laserSM') { bIsAggressive = true; }
						}
					}
					
					if (bIsMiner) { obj.dispatchEvent(new dataEvent('harvest asteroids', 'doAction')); }
					if (bIsAggressive) { obj.dispatchEvent(new dataEvent('go postal', 'doAction')); }
				}
			}
		}
		
		//
		///-- Main Loop --///
		//
		
		public function heartBeat():void {
			//trace(this.faction);
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.oGL.removeEventListener('gameLoaded', onGameLoaded);
		}
	}
}		
