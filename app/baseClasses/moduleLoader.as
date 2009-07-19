/******************************************************************************
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


package app.baseClasses {
	import flash.events.*;
	import flash.geom.Point;
	
	import app.baseClasses.realMover;
	import app.equipment.miningLaser;
	import app.equipment.laser;
	import app.loaders.gameloader;
	
	public class moduleLoader extends Object {
		private var oParent:realMover;
		private var oGL:gameloader;
		public var externalHardPoints:Array = new Array();
		public var externalModuleArray:Array = new Array();
		public var internalModuleArray:Array = new Array();
		public var maxExternalModules:int = 0;
		public var maxInternalModules:int = 0;
		
		///-- Constructor --///
		
		public function moduleLoader(xSpec:XML, oParent:realMover, xMapData:String = ''):void {
			this.oParent = oParent;
			this.oGL = this.oParent.oGL;
			this.maxExternalModules = xSpec.maxExternalModules;
			this.maxInternalModules = xSpec.maxInternalModules;
			
			this.loadModules(xSpec, xMapData);
		}
		
		private function loadModules(xSpec:XML, mapData:String = ''):void {
			for each (var hp:String in xSpec.externalHardPoints.hardPoint) {
				var arr:Array = hp.split(',');
				this.externalHardPoints.push(new Point(arr[0],arr[1]));
			}
			
			if (mapData != '') {
				for each (var xModule:XML in XML(mapData).modules.module) {
					this.addModule(xModule.@moduleType, xModule.@position, xModule);
				}
			} else {
				for each (var xModule2:XML in this.oGL.activeShip.modules.module) {
					this.addModule(xModule2.@moduleType, xModule2.@position, xModule2);
				}
			}
		}
		
		///-- Public Functions --///
		
		public function addModule(moduleType:String, position:int, sModule:String):void {
			if (moduleType == "external") {
				for each (var xModule:XML in this.oGL.xEquipmentData.modules.module) {
					if (xModule.name.toString() == sModule) {
						switch (xModule.baseClass.toString()) {
							case "miningLaser" :
								var oML:miningLaser = new miningLaser(this.oParent, xModule);
								oML.x = this.externalHardPoints[position].x;
								oML.y = this.externalHardPoints[position].y;
								this.oParent.offsetSprite.addChildAt(oML, this.oParent.offsetSprite.numChildren);
								this.externalModuleArray.push(oML);
								break;
								
							case "laser" :
								var oLaser:laser = new laser(this.oParent, xModule);
								oLaser.x = this.externalHardPoints[position].x;
								oLaser.y = this.externalHardPoints[position].y;
								this.oParent.offsetSprite.addChildAt(oLaser, this.oParent.offsetSprite.numChildren);
								this.externalModuleArray.push(oLaser);
								break;
						}
					}
				}
			} else if (moduleType == "internal") {
			
			}
		}
		
		public function removeModule():void {
		
		}
		
		///-- Event Listeners --///
		
		
		
		///-- Main Loop --///
		
		public function heartBeat():void {
			for each (var module:* in this.externalModuleArray) {
				module.heartBeat();
			}
		}
		
		///-- Destructor --///
		
		public function destroy():void {
			for each (var oModule:* in this.externalModuleArray) {
				oModule.destroy();
				oModule = null;
			}
		}
	}
}
