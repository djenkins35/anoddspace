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
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.geom.*;
	
	import app.equipment.drone;
	import app.baseClasses.targeter;
	import app.loaders.gameloader;
	
	public class fighterHanger extends targeter {
		public var fighterCapacity:int;
		public var launchDelay:int;									// number of global heartbeat ticks to wait between launches
		public var fighterArray:Array = new Array();
		public var fighterCounter:uint = 0;								// counter for fighterArray
		public var xDroneSpec:XML;
		
		public function fighterHanger(xSpec:XML, oGL:gameloader):void {
			var pos:Array = xSpec.position.split(',');
			this.x = pos[0];
			this.y = pos[1];
			this.imageURL = xSpec.imageURL;
			this.faction = xSpec.faction;
			this.radarRange = xSpec.radarRange;
			this.fighterCapacity = xSpec.fighterCapacity;
			this.launchDelay = xSpec.launchDelay;
			this.shieldFull = this.shield = xSpec.shield;
			this.shieldRegen = xSpec.shieldRegen;
			this.hull = xSpec.hull;
			this.name = "Fighter Hanger";
			
			this.oGL = oGL;
			this.imageDir = this.oGL.imageDir;
			this.getDroneSpec(xSpec.droneSpec);
		}
		
		private function getDroneSpec(droneSpec:String):void {
			for each (var xSpec:XML in this.oGL.oEquipmentData.xmlData.*.*) {
				if (xSpec.baseClass.toString() == droneSpec) {
					this.xDroneSpec = xSpec;
					break;
				}
			}
		}
		
		private function launchFighters():void {
			if (this.fighterArray.length < this.fighterCapacity) {
				this.fighterArray[this.fighterCounter] = new drone(this.xDroneSpec, this.oGL);
				this.fighterArray[this.fighterCounter].x = this.x;
				this.fighterArray[this.fighterCounter].y = this.y;
				this.fighterArray[this.fighterCounter].oTarget = this.oTarget;
				this.fighterArray[this.fighterCounter].hanger = this;
				this.fighterArray[this.fighterCounter].isHostile = true;
				this.fighterArray[this.fighterCounter].faction = this.faction;
				this.oGL.objectArray.push(this.fighterArray[this.fighterCounter]);
				this.oGL.gamescreen.addChild(this.fighterArray[this.fighterCounter]);
				
				// testing
				this.fighterArray[this.fighterCounter].dispatchEvent(new Event('toggleModulesOn'));
				
				
				this.fighterCounter++;
			}
		}
		
		public override function destroy():void {
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.imageLoader = null;
			this.oGL.unloadObject(this);
		}
		
		///-- --///
		
		public function heartBeat():void {
			//try {
				if (this.isHostile) {
					this.getDistanceToTarget();
				
					if (this.targetDistance <= this.radarRange) {
						this.tick++;
						if (this.tick == this.launchDelay) {
							this.launchFighters();
							this.tick = 0;
						} else if (this.tick > this.launchDelay) {
							this.tick = 0;
						}
					} else {
						this.tick = 0;
					}
				}
			//} catch (e:Error) {}
		}
	}
}
