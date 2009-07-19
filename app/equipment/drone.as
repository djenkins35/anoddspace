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


package app.equipment {
	import flash.events.*;
	import flash.display.Stage;
	import flash.geom.*;
	
	import app.baseClasses.mover;
	import app.loaders.gameloader;
	import app.equipment.laser;
	import app.equipment.miningLaser;
	
	public class drone extends mover {
		public var hanger:Object;
		
		public var xModuleData:XML;
		public var oModule:*;
		
		///-- constructor --///
		
		public function drone(xData:XML, oGL:gameloader):void {
			this.oGL = oGL;
			this.imageDir = this.oGL.imageDir;
			this.acceleration = xData.acceleration;
			this.angularSpeed = xData.angularSpeed;
			this.maxSpeed = xData.maxSpeed;
			this.radarRange = xData.radarRange;
			this.attackRange = xData.attackRange;
			this.attackRange2 = xData.attackRange2;
			this.hull = xData.hull;
			this.shield = this.shieldFull = xData.shield;
			this.shieldRegen = xData.shieldRegen;
			
			this.imageURL = xData.imageURL;
			this.name = xData.name;
			this.loadModule(xData.module);
			this.addEventListener(Event.ENTER_FRAME, main);
		}
		
		private function loadModule(module:String):void {
			for each (var xModule:XML in this.oGL.xEquipmentData.modules.module) {
				if (xModule.name == module) {
					this.xModuleData = xModule;
					break;
				}
			}
			
			switch (this.xModuleData.baseClass.toString()) {
				case "laser" :
					this.oModule = new laser(this, xModuleData);
					this.addChild(this.oModule);
					break;
					
				case "miningLaser" :
				
					break;
			}
		}
		
		///-- public functions --///
		
		public function returnToHanger():void {
			try { this.oTarget = this.hanger; } catch (e:Error) {trace('no hanger');}
			this.isHostile = false;
			this.isMoving = true;
		}
		
		//
		///-- main loops --///
		//
		
		public function heartBeat():void {
			if (this.oGL.objectArray.indexOf(this.oTarget) != -1) {		// target not destroyed
				this.targetDistance = this.getDistance(this.oTarget, this);
				
				if (this.targetDistance <= this.radarRange) {
					this.isMoving = true;
					this.attack();
				}
			} else {
				if (this.targetClosestEnemy()) {
					this.dispatchEvent(new Event('toggleModulesOn'));
				} else {
					this.dispatchEvent(new Event('toggleModulesOff'));
					this.returnToHanger();
				}
			}
			
			this.rotation = this.trajectory * 180 / Math.PI;
			this.oModule.heartBeat();
		}
		
		public function main(e:Event):void {
			if (this.isMoving) {
				this.translatePoint(this.trajectory, this.velocity);
			}
		}
		
		//
		///-- destructor --///
		//
		
		public override function destroy():void {
			try {
				if (this.hanger.fighterArray != null) {
					this.hanger.fighterArray.splice(this.hanger.fighterArray.indexOf(this), 1);
					this.hanger.fighterCounter--;
				}
			} catch (e:Error) {
				trace(this.name + " was not launched from a fighterHanger");
			}
			
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.graphics.clear();
			this.oModule.destroy();
			this.oGL.unloadObject(this);
		}
	}
}
