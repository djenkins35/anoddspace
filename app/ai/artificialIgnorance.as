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


package app.ai {
	import flash.events.*;
	import flash.geom.Point;
	
	import app.baseClasses.asteroid;
	import app.baseClasses.starBase;
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.baseClasses.realMover;
	
	
	public class artificialIgnorance extends Object {
	
		private var oGL:gameloader;
		
		// tbr
		public var orbitRange:uint = 500;
		private var mineralValue:int = 20; // hack
		private var minCargoDelta:int = 99;	// hack for forcing 'cargoFull' on frieghters
		private var closeEnough:int = 25; 	// fudge factor for docking (in pixels)
		
		// movement booleans used in parent's main loop
		public var isMoving:Boolean = false;
		public var isStopping:Boolean = false;
		public var isChasing:Boolean = false;
		
		public var moveCoords:Point = new Point();
		public const ninety:Number = Math.PI / 2;
		public var curAction:String = "";				// only overwritten when given a new 'doAction()'
		private var oParent:realMover;
		private var dockTarget:*;						// used in the dumpCargo() event listener
		
		///-- Constructor --///
		
		public function artificialIgnorance(oGL:gameloader, oParent:realMover) {
			this.oGL = oGL;
			this.oParent = oParent;
			this.oParent.addEventListener('cargoFull', onCargoFull);
			this.oParent.addEventListener('doAction', onDoActionEvent);
		}
		
		///-- Actions --///
		
		public function harvest():void {
			this.oParent.dispatchEvent(new Event('toggleModulesOff'));
			
			if (this.oParent.usedCargoSpace < this.oParent.cargoCapacity - this.minCargoDelta) {	// hack
				// get closest asteroid
				var dist:Number;
				var closestYet:Number = this.oParent.radarRange;	// compare dist to max radar range
				var closest:asteroid = null;
				var dx:Number;
				var dy:Number;
				
				for each (var ast:* in this.oGL.objectArray) {
					if (ast is asteroid) {
						dx = this.oParent.x - ast.x;
						dy = this.oParent.y - ast.y;
						dist = Math.sqrt(dx * dx + dy * dy);
						
						if (dist < closestYet) {
							closest = ast;
							closestYet = dist;
						}
					}
				}
				
				if (closest != null) {
					this.oParent.oTarget = closest;
					this.oParent.targetDistance = this.oParent.getDistance(this.oParent.oTarget, this.oParent);
                    
					// move to within mining range ~100 pixels
					var offsetPoint:Point = this.getOffsetPoint(100);
					this.moveCoords.x = offsetPoint.x;
					this.moveCoords.y = offsetPoint.y;
					
					this.isStopping = true;
					this.isMoving = true;
					
					// trigger modules
					this.oParent.dispatchEvent(new Event('toggleModulesOn'));
				} else {
					trace(this.oParent.name + ' says, no asteroids in range');
					// move back to starbase
					this.oParent.dispatchEvent(new Event('cargoFull'));	// hack
				}
			} else {
				this.oParent.dispatchEvent(new Event('cargoFull'));	// hack
			}
		}
		
		public function goPostal():void {
			this.oParent.dispatchEvent(new Event("toggleModulesOff"));
			
			if (this.oParent.targetClosestEnemy()) {
				this.isChasing = true;
				
				// move closer
				if (this.oParent.targetDistance > this.orbitRange) {
					// get a point that is within range
					var offsetPoint:Point = this.getOffsetPoint(this.orbitRange - 100);
					this.moveCoords.x = offsetPoint.x;
					this.moveCoords.y = offsetPoint.y;
					
					this.isStopping = true;
					this.isMoving = true;
				}
				
				this.oParent.dispatchEvent(new Event("toggleModulesOn"));
			}
		}
		
		///-- common functions --///
		
		// targeting
		
		public function findCargoDump():void {	// called in realMover.as::main() when mining and cargo is full
			var dist:int = this.oParent.radarRange;
			var tmpDist:Number;
			var cargoDump:*;		// only set if something is in radar range
			var dx:Number;
			var dy:Number;
			
			// find something to dock with
			for (var i:uint = 0, len:uint = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].faction == this.oParent.faction		// test faction
					&& this.oGL.objectArray[i].isDockable						// check if dockable
					&& this.oGL.objectArray.indexOf(this.oParent) != i)			// make sure not to target self
				
				{
                    tmpDist = this.oParent.getDistance(this.oGL.objectArray[i], this.oParent);
                    
					if (this.oGL.objectArray[i] is starBase) {
						if (tmpDist <= dist) {
							dist = tmpDist;
							cargoDump = this.oGL.objectArray[i];
						}
					} else {	// if not a starBase, check for cargo capacity
						var freeSpace:int = this.oGL.objectArray[i].cargoCapacity - this.oGL.objectArray[i].usedCargoSpace;
						
						// if cargo won't fit, don't get distance
						if (freeSpace - this.oParent.usedCargoSpace >= 0) {
							if (tmpDist <= dist) {
								dist = tmpDist;
								cargoDump = this.oGL.objectArray[i];
							}
						}
					}
				}
			}
			
			if (cargoDump != null) {	// need to update with dockPoint coords once implemented
				//trace(this.oGL.objectArray.indexOf(this.oParent) + ' found ' + cargoDump);
				this.moveCoords.x = cargoDump.x;
				this.moveCoords.y = cargoDump.y;
				this.isMoving = true;
				this.oParent.oTarget = cargoDump;
				this.dockTarget = cargoDump;
				this.oParent.addEventListener("stoppedMoving", dumpCargo);
			} else {
				// find something to do while waiting for a cargo dump to come in range...
				// need to start a heartbeat counter for re-checking for a cargo dump,
				// or load the last known station coords...
				trace(this.oGL.objectArray.indexOf(this.oParent) + ' no dockable targets in range');
			}
		}
		
		// movement
		
		public function faceVector(vect:Number):void {	// in radians
			//var as:Number = this.angularSpeed;
			var r1:Number = this.oParent.rotation;
			var r2:Number = vect * 180 / Math.PI;
			//var dir:String = "" // cw or ccw
			
			if (r1 >= 0 && r2 >= 0) {
				if (r1 > r2) {
					//dir = "ccw";
					if (r1 - this.oParent.angularSpeed > r2) {
						this.oParent.rotation -= this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				} else {
					//dir = "cw";
					if (r1 + this.oParent.angularSpeed < r2) {
						this.oParent.rotation += this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				}
			} else if (r1 >= 0 && r2 < 0) {
				if (r1 - 180 <= r2) {
					//dir = "ccw";
					if (r1 - this.oParent.angularSpeed > r2) {
						this.oParent.rotation -= this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				} else {
					//dir = "cw";
					if (r1 + this.oParent.angularSpeed < 180) {
						this.oParent.rotation += this.oParent.angularSpeed;
					} else {	// went through the coordinate line
						var diff:Number = r1 + this.oParent.angularSpeed - 180;
						
						if (-180 + diff < r2) {
							this.oParent.rotation = -180 + diff;
						} else {
							this.oParent.rotation = r2;
						}
					}
				}
			} else if (r1 < 0 && r2 >= 0) {
				if (r1 + 180 >= r2) {
					//dir = "cw";
					if (r1 + this.oParent.angularSpeed < r2) {
						this.oParent.rotation += this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				} else {
					//dir = "ccw";
					if (r1 - this.oParent.angularSpeed > -180) {
						this.oParent.rotation -= this.oParent.angularSpeed;
					} else {	// went through the coordinate line
						var diff2:Number = Math.abs(r1 - this.oParent.angularSpeed + 180);
						
						if (180 - diff2 > r2) {
							this.oParent.rotation = 180 - diff2;
						} else {
							this.oParent.rotation = r2;
						}
					}
				}
			} else {	// r1 < 0 && r2 < 0
				if (r1 > r2) {
					//dir = "ccw";
					if (r1 - this.oParent.angularSpeed > r2) {
						this.oParent.rotation -= this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				} else {
					//dir = "cw";
					if (r1 + this.oParent.angularSpeed < r2) {
						this.oParent.rotation += this.oParent.angularSpeed;
					} else {
						this.oParent.rotation = r2;
					}
				}
			}
		}
		
		public function getOffsetPoint(dist:Number):Point {		// returns a point on the line between oParent.oTarget and oParent that is 'dist' distance from oParent.oTarget
			var offsetPoint:Point = new Point();
			
			var angle:Number = this.getVector(this.oParent.oTarget.x - this.oParent.x, this.oParent.oTarget.y - this.oParent.y);
			offsetPoint.x = this.oParent.x + Math.sin(angle) * (this.oParent.targetDistance - dist);
			offsetPoint.y = this.oParent.y - Math.cos(angle) * (this.oParent.targetDistance - dist);
			
			return offsetPoint;
		}
		
		public function getVector(dx:Number, dy:Number):Number {
			var vector:Number = 0;
			
			if (dx == 0) {
				if (dy <= 0) {
					vector = 0;
				} else {
					vector = Math.PI;
				}
			} else {
				if (dy == 0) {
					if (dx > 0) {
						vector = ninety;
					} else {
						vector = -ninety;
					}
				} else {
					if (dx > 0) {
						if (dy > 0) {
							vector = ninety + Math.atan(dy / dx);
						} else {
							vector = -Math.atan(dx / dy);
						}
					} else {
						if (dy > 0) {
							vector = -ninety + Math.atan(dy / dx);
						} else {
							vector = -Math.atan(dx / dy);
						}
					}
				}
			}
			
			return vector;
		}
		
		public function getMinStoppingDistance():Number {	// called in moveToCoords()
			var test:Number = Math.ceil(this.oParent.velocity / this.oParent.acceleration);	// how many frames till velocity == 0
			var curSpeed:Number = this.oParent.velocity;
			var dist:Number = 0;
			for (var i:int = 0; i < test; i++) {
				curSpeed -= this.oParent.acceleration;
				dist += curSpeed;
			}
			
			// distance travelled while turning around
			var spinTime:Number = Math.ceil(180 / this.oParent.angularSpeed) * this.oParent.velocity;
			
			return Math.ceil(spinTime + dist); // add in the time to turn completely around
		}
		
		public function comeToStop():void {		// sometimes buggy, probably need a better test for 'close enough'
			var vect:Number = this.oParent.trajectoryAngle;
			if (vect > 0) {
				vect -= Math.PI;
			} else {
				vect += Math.PI;
			}
			
			this.faceVector(vect);
			if (vect * 180 / Math.PI == this.oParent.rotation) {
				this.oParent.setThrustVectors();
				
				if (Math.abs(this.oParent.newXv) < Math.abs(this.oParent.tXv) && Math.abs(this.oParent.newYv) < Math.abs(this.oParent.tYv)) {
					this.oParent.newXv = 0;
					this.oParent.newYv = 0;
					this.isStopping = false;
					this.oParent.killThrust();
					this.oParent.dispatchEvent(new Event("stoppedMoving"));
				} else {
					this.oParent.applyThrust();
				}
			}
			
			if (this.oParent.newXv == 0 && this.oParent.newYv == 0) {
				this.isStopping = false;
				this.oParent.killThrust();
			}
		}
		
		public function moveToCoords():void {	// set public var moveCoords:Point before using
			this.oParent.killThrust();
			// get vector Angle to moveCoords
			var dx:Number = this.moveCoords.x - this.oParent.x;
			var dy:Number = this.moveCoords.y - this.oParent.y;
			var vect:Number = this.getVector(dx,dy);
			
			// get distance to moveCoords
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			var stopDist:Number = this.getMinStoppingDistance();
			
			if (dist <= stopDist) {		// turn around and slow down
				this.isStopping = true;
				
				if (Math.abs(dx) < 2 && Math.abs(dy) < 2 
					&& Math.abs(this.oParent.newXv) < this.oParent.acceleration 
					&& Math.abs(this.oParent.newYv) < this.oParent.acceleration) // close as we can get
				{
					this.oParent.newXv = this.oParent.newYv = 0;
					this.isStopping = false;
					this.isMoving = false;
					this.oParent.dispatchEvent(new Event("stoppedMoving"));
				}
			} else {
				this.faceVector(vect);
				
				if (this.oParent.rotation == vect * 180 / Math.PI
					&& this.oParent.velocity < this.oParent.maxSpeed)
				{
					this.oParent.applyThrust();
				} else {
					this.oParent.killThrust();
				}
			}
		}
		
		public function chase():void {	// need to fix for out of orbit range... ie) set trajectory to intercept target if possible
			if (this.oParent.oTarget is realMover) {
				var dx:Number;
				var dy:Number;
				
				if (this.oParent.targetDistance >= this.orbitRange) {							// intercept target
					dx = (this.oParent.oTarget.x - this.oParent.x) / this.oParent.maxSpeed - this.oParent.newXv;
					dy = (this.oParent.oTarget.y - this.oParent.y) / this.oParent.maxSpeed - this.oParent.newYv;
					var vect:Number = this.getVector(dx,dy);
					this.faceVector(vect);
					
					if (this.oParent.rotation == vect * 180 / Math.PI) {
						this.oParent.applyThrust();
					}
				} else {															// within orbit / formation range
					dx = this.oParent.oTarget.newXv - this.oParent.newXv;
					dy = this.oParent.oTarget.newYv - this.oParent.newYv;
					
					if (dx == 0 && dy == 0) {
						this.oParent.killThrust();
					} else {
						var vect2:Number = this.getVector(dx,dy);
						this.faceVector(vect2);
						
						if (this.oParent.rotation == vect2 * 180 / Math.PI) {
							this.oParent.setThrustVectors();
							
							if (Math.abs(dx) <= Math.abs(this.oParent.tXv) && Math.abs(dy) <= Math.abs(this.oParent.tYv)) {
								this.oParent.flameOn();
								this.oParent.newXv = this.oParent.oTarget.newXv;
								this.oParent.newYv = this.oParent.oTarget.newYv;
							} else {
								this.oParent.applyThrust();
							}
						} else {
							this.oParent.killThrust();
						}
					}
				}
			}
		}
		
		///-- event listeners --///
		
		public function dumpCargo(e:Event):void {	// sell if docked at station, transfer if docked with ship
			// check if in range of cargodump
			var dx:Number = this.oParent.x - this.dockTarget.x;
			var dy:Number = this.oParent.y - this.dockTarget.y;
			var dist:Number = Math.sqrt(dx * dx + dy * dy);
			
			if (dist <= this.closeEnough) { // sell cargo if docked at station, transfer cargo if docked with transport / frieghter
				this.oParent.removeEventListener("stoppedMoving", dumpCargo);
				var i:int;
				var len:int = this.oParent.cargoArray.length;
				
				//trace(this.oGL.objectArray.indexOf(this.oParent) + ' attempting to dump');
				
				if (this.dockTarget is starBase) {
					var sellValue:int = 0;
					
					for (i = 0; i < len; i++) {
						if (this.oParent.cargoArray[i].item == "minerals") {
							sellValue = this.mineralValue * this.oParent.cargoArray[i].volume;
							this.oParent.usedCargoSpace -= this.oParent.cargoArray[i].volume;
							this.oParent.cargoArray.splice(this.oParent.cargoArray[i], 1);
						}
					}
					
					var curMoney:int = new int(this.oGL.xPlayerData.money);
					this.oGL.xPlayerData.money = XML(sellValue + curMoney);
					
					//trace(this.oGL.objectArray.indexOf(this.oParent) + ' sold to starbase');
					
					// go back to whatever you were doing
					this.oParent.dispatchEvent(new dataEvent(this.curAction, 'doAction'));
				} else {
					// transfer cargo
					for (i = 0; i < len; i++) {
						if (this.oParent.cargoArray[i].item == "minerals") {
							
							if (this.dockTarget.addCargo(this.oParent.cargoArray[i])) {
								//trace(this.oGL.objectArray.indexOf(this.oParent) + ' successfully transferred cargo');
								this.oParent.usedCargoSpace -= this.oParent.cargoArray[i].volume;
								this.oParent.cargoArray.splice(this.oParent.cargoArray[i], 1);
								
								// go back to whatever you were doing
								this.oParent.dispatchEvent(new dataEvent(this.curAction, 'doAction'));
							} else {	// not enough room on dockTarget
								// ?
								//trace(this.oGL.objectArray.indexOf(this.oParent) + ' not enough space on dockTarget ' + this.dockTarget.name);
								this.findCargoDump();
							}
						}
					}
					
				}
			} else {
				// move closer
				//trace(this.oGL.objectArray.indexOf(this.oParent) + ' not close enough');
				this.findCargoDump();
			}
		}
		
		public function onCargoFull(e:Event):void {
			//trace(this.oGL.objectArray.indexOf(this.oParent) + ' cargoFull triggered');
			this.findCargoDump();
			trace(this.oParent.name + "'s cargo full");
		}
		
		public function handleTargetDied(e:dataEvent):void {
			if (e.dataObj == this.oParent.oTarget) {
				this.oParent.dispatchEvent(new dataEvent(this.curAction, 'doAction'));
				trace(this.oParent.name + "'s target died");
			}
		}
		
		private function onStarBaseDock(e:Event):void {
			this.oParent.removeEventListener("stoppedMoving", onStarBaseDock);
			
			// trigger the docking function in gameloader.as
			this.oGL.dispatchEvent(new dataEvent(this.dockTarget, 'playerShipDocked'));
		}
		
		private function onDoActionEvent(e:dataEvent):void {
           this.oParent.addEventListener("targetDied", handleTargetDied);
			
			switch (e.dataObj) {
				case "follow" :
					this.oParent.oTarget = this.oGL.playerShip;
					this.isMoving = false;
					this.isChasing = true;
					this.isStopping = false;
					this.curAction = "follow";
					break;
				
				case "harvest asteroids" :
					this.isChasing = false;
					this.isStopping = false;
					this.isMoving = false;
					this.harvest();
					this.curAction = "harvest asteroids";
					break;
				
				case "defend" :
					this.isChasing = false;
					this.isMoving = false;
					this.isStopping = true;
					this.moveCoords.x = this.oParent.x;
					this.moveCoords.y = this.oParent.y;
					this.moveToCoords();
					this.curAction = "defend";
					break;
					
				case "go postal" :
					this.isChasing = false;
					this.isMoving = false;
					this.isStopping = true;
					this.goPostal();
					this.curAction = "go postal";
					break;
					
				case "Dock" :	// used to dock the player's ship with a starbase
					this.isChasing = false;
					this.isMoving = true;
					this.isStopping = false;
					
					// find out which target is the starBase
					for each (var obj:Object in this.oGL.playerTargetArray) {
						if (obj is starBase) {
							this.dockTarget = obj;	// set the dockTarget to send in the dataEvent (in case player changes targets while docking)
							this.moveCoords.x = obj.x;
							this.moveCoords.y = obj.y;
						}
					}
					
					this.oParent.addEventListener("stoppedMoving", onStarBaseDock);
					this.moveToCoords();
					break;
			}
		}
		
		///-- destructor --///
		
		public function destroy():void {
			try { this.oParent.removeEventListener("stoppedMoving", dumpCargo); } catch (e:Error) { /* no stopped moving listener registered */ }
			this.oParent.removeEventListener('cargoFull', onCargoFull);
			this.oParent.removeEventListener('doAction', onDoActionEvent);
			this.oParent.removeEventListener("targetDied", handleTargetDied);
		}
	}
}		
