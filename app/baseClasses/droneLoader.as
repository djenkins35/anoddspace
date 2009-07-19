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
	
	import app.baseClasses.realMover;
	import app.equipment.drone;
	import app.loaders.gameloader;
	
	public class droneLoader extends Object {
		private var oParent:realMover;
		private var oGL:gameloader;
		private var xDroneSpec:XML;
		private var droneArray:Array = new Array();
		private var droneCapacity:int;
		private var launchDelay:int = 10;				// in heartbeats
		
		public var tick:int = 0;
		public var isActivated:Boolean = false;
		public var isLaunching:Boolean = false;
		public var isRecalling:Boolean = false;
		
		
		///-- Constructor --///
		
		public function droneLoader(oParent:realMover, xSpec:XML):void {
			this.oParent = oParent;
			this.oGL = this.oParent.oGL;
			this.droneCapacity = xSpec.droneCapacity;
			
			this.getDroneSpec('lightFighter');	// hack
		}
		
		private function getDroneSpec(droneSpec:String):void {
			for each (var xSpec:XML in this.oGL.xEquipmentData.*.*) {
				if (xSpec.baseClass.toString() == droneSpec) {
					this.xDroneSpec = xSpec;
					break;
				}
			}
		}
		
		private function launchDrones():void {
			if (this.droneArray.length < 4) {		// hack
				var oDrone:drone = new drone(this.xDroneSpec, this.oGL);
				oDrone.x = this.oParent.x;
				oDrone.y = this.oParent.y;
				oDrone.oTarget = this.oParent.oTarget;
				oDrone.hanger = this.oParent;
				oDrone.isHostile = true;
				oDrone.faction = this.oParent.faction;
				
				
				this.droneArray.push(oDrone);
				this.oGL.objectArray.push(oDrone);
				this.oGL.gamescreen.addChild(oDrone);
				
				oDrone.dispatchEvent(new Event('toggleModulesOn'));
			} else {
				this.isLaunching = false;
				this.isActivated = false;
			}
		}
		
		private function recallDrones():void {
			//trace(this.oParent.name + ' recalling drones');
			
			for each (var oDrone:drone in this.droneArray) {
				oDrone.returnToHanger();
			}
		}
		
		///-- Public Functions --///
		
		public function toggleDrones():void {		// toggles the launch or recall state
			this.isActivated = true;
		
			if (this.isLaunching) {
				this.isLaunching = false;
				this.isRecalling = true;
			} else if (this.isRecalling) {
				this.isRecalling = false;
				this.isLaunching = true;
			} else {								// neither state is set
				if (this.droneArray.length > 0) {
					this.isRecalling = true;
				} else {
					this.isLaunching = true;
				}
			}
		}
			
		///-- Event Listeners --///
		
		
		
		///-- Main Loop --///
		
		public function heartBeat():void {
			if (this.isActivated) {
				if (this.isLaunching) {											// launch drones
					if (this.tick == this.launchDelay) {
						this.launchDrones();
						this.tick = 0;
					} else if (this.tick > this.launchDelay) {
						this.tick = 0;
					} else {
						this.tick++;
					}
				} else if (this.isRecalling && this.droneArray.length > 0) {	// recall drones
					this.recallDrones();
					this.tick = 0;
				}
			}											
		}
		
		///-- Destructor --///
		
		public function destroy():void {
		}
	}
}
