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


package app.baseClasses {
	import flash.events.*;
	import flash.display.Stage;
	import flash.net.URLRequest;
	import flash.geom.*;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	
	import app.baseClasses.moduleLoader;
	import app.baseClasses.droneLoader;
	import app.equipment.miningLaser;
	import app.equipment.laser;
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.ai.artificialIgnorance;
	
	
	public class realMover extends mover {
		public var notDead:Boolean = true;			// hack for heartbeat errors
		public var trajectoryAngle:Number = 0;			// in radians
		public var cargoCapacity:int;
		public var usedCargoSpace:int = 0;
		public var cargoArray:Array = new Array();
		public var AI:artificialIgnorance;
		public var mods:moduleLoader;
		public var droneBay:droneLoader;
		public var xSpec:XML;
		
		// custom events for gamesound
		private var eFlameOn:Event = new Event('flameOn');
		private var eFlameOff:Event = new Event('flameOff');
		
		// used if creating a ship from mapData in gameloader.as
		public var defaultActions:Array = ["follow", "harvest asteroids", "defend", "patrol", "go postal"];
		
		// variables for vector component addition
		public var maxXv:Number = 0;
		public var maxYv:Number = 0;
		public var tXv:Number = 0; 		// thrust
		public var tYv:Number = 0;
		public var newXv:Number = 0; 	// new resultant components
		public var newYv:Number = 0;
		
		//
		///-- Constructor --///
		//
	
		public function realMover(oGL:gameloader, xSpec:XML, xMapData:String = '') {	// under construction
			this.oGL = oGL;
			this.xSpec = xSpec;
			this.imageDir = this.oGL.imageDir;
			this.hullFull = this.hull = xSpec.hull;
			this.shieldFull = this.shield = xSpec.shield;
			this.shieldRegen = xSpec.shieldRegen;
			this.acceleration = xSpec.acceleration;
			this.angularSpeed = xSpec.angularSpeed;
			this.maxSpeed = xSpec.maxSpeed;
			this.radarRange = xSpec.radarRange;
			this.cargoCapacity = xSpec.cargoCapacity;
			
			// dock point
			if (xSpec.hasOwnProperty("dockPoint")) {	// needs work
				//trace(xSpec.dockPoint);
				this.isDockable = true;
			}
			
			// images
			this.imageURL = xSpec.imageURL;
			this.thrustImageURL = xSpec.thrustImageURL;
			var thrustImageOffset:Array = xSpec.thrustImageOffset.split(',');
			this.thrustOffsetX = thrustImageOffset[0];
			this.thrustOffsetY = thrustImageOffset[1];
			
			// modules / cargo / drone initialization
			if (xMapData != '') {											// ship loaded from mapData
				var position:Array = XML(xMapData).position.split(',');
				this.x = position[0];
				this.y = position[1];
				this.mods = new moduleLoader(xSpec, this, xMapData);
				this.droneBay = new droneLoader(this, xSpec);
				
				var xName:* = XML(xMapData).name;	// boo, coercion error when casting to String 
				this.faction = XML(xMapData).faction;
				this.name = xName.toString();
			} else {														// active player ship
				this.mods = new moduleLoader(xSpec, this);
				this.loadCargo();
				this.droneBay = new droneLoader(this, xSpec);
				this.name = xSpec.name;
			}
			
			this.AI = new artificialIgnorance(this.oGL, this);
			this.addEventListener(Event.ENTER_FRAME, main);
		}
		
		public function toggleModules():void {	// called in gameloader.as::main() on 'space' key event
			this.dispatchEvent(new Event('toggleModules'));
		}
		
		///-- cargo --///
		
		private function loadCargo():void {
			for each (var xItem:XML in this.oGL.activeShip.cargo.item) {
				var oCargo:Object = {item:new String(xItem), volume:new int(xItem.@volume)};
				this.addCargo(oCargo);
			}
		}
		
		public function addCargo(obj:Object):Boolean {
			var item:String = obj.item.toString();
			var volume:int = new int(obj.volume);
			
			if (this.cargoCapacity >= this.usedCargoSpace + volume) {
				this.usedCargoSpace += volume;
				var indx:int = -1;
				
				for each (var oCargo:Object in this.cargoArray) {
					if (oCargo.item == item) {
						indx = this.cargoArray.indexOf(oCargo);
					}
				}
				
				if (indx != -1 ) {
					this.cargoArray[indx].volume += volume;
				} else {
					this.cargoArray.push(obj);
				}
				
				if (this.usedCargoSpace == this.cargoCapacity) {
					this.dispatchEvent(new Event('cargoFull'));
				}
				
				return true;
			} else {
				this.dispatchEvent(new Event('cargoFull'));
				//trace(this.usedCargoSpace + volume);
				//trace("cargoCapacity = " + this.cargoCapacity + " :: usedCargoSpace = " + usedCargoSpace);
				//trace("not enough cargo space available for " + item + " " + volume);
				return false;
			}
		}
		
		public function removeCargo(xItem:XML):void {
			for each (var oCargo:Object in this.cargoArray) {
				if (oCargo.item == xItem) {
					var indx:int = this.cargoArray.indexOf(oCargo);
					this.usedCargoSpace -= xItem.@volume
					this.cargoArray.splice(indx, 1);
					this.oGL.updateCargo();
				}
			}
		}
		
		///-- movement --///
		
		public function setThrustVectors():void {
			var radRotAngle:Number = this.rotation * Math.PI / 180;
			
			this.tXv = this.acceleration * Math.sin(radRotAngle);
			this.tYv = this.acceleration * Math.cos(radRotAngle);
		}
		
		public function getTrajectoryAngle():void {
			if (this.newXv == 0) {
				if (this.newYv <= 0) {
					this.trajectoryAngle = 0;
				} else {
					this.trajectoryAngle = Math.PI;
				}
			} else if (this.newYv == 0) {
				if (this.newXv > 0) {
					this.trajectoryAngle = ninety;
				} else {
					this.trajectoryAngle = -ninety;
				}
			} else {
				if (this.newXv > 0) {
					if (this.newYv < 0 ) {
						this.trajectoryAngle = -Math.atan(this.newXv / this.newYv);
					} else {
						this.trajectoryAngle = ninety + Math.atan(this.newYv / this.newXv);
					}
				} else {
					if (this.newYv < 0) {
						this.trajectoryAngle = -Math.atan(this.newXv / this.newYv);
					} else {
						this.trajectoryAngle = -ninety + Math.atan(this.newYv / this.newXv);
					}
				}
			}
		}
		
		private function getMaxVectors():void {
			this.maxXv = this.maxSpeed * Math.sin(this.trajectoryAngle);
			this.maxYv = -this.maxSpeed * Math.cos(this.trajectoryAngle);
		}
		
		public function applyThrust():void {
			this.setThrustVectors();
			this.newXv += this.tXv;
			this.newYv -= this.tYv;
			this.getTrajectoryAngle();
			this.getMaxVectors();
			
			if (this.newXv > this.maxXv && this.newXv > 0) {
				this.newXv = this.maxXv;
				this.getTrajectoryAngle();
			} else if (this.newXv < this.maxXv && this.newXv < 0) {
				this.newXv = this.maxXv;
				this.getTrajectoryAngle();
			}
			
			if (this.newYv > this.maxYv && this.newYv > 0) {
				this.newYv = this.maxYv;
				this.getTrajectoryAngle();
			} else if (this.newYv < this.maxYv && this.newYv < 0) {
				this.newYv = this.maxYv;
				this.getTrajectoryAngle();
			}
			
			this.velocity = Math.sqrt(this.newXv * this.newXv + this.newYv * this.newYv);
			
			// add the thrust image
			if (!this.offsetSprite.contains(this.thrustOffset)) { this.offsetSprite.addChild(this.thrustOffset); }
			
			// dispatch Event for gamesound
			this.dispatchEvent(this.eFlameOn);
		}
		
		public function killThrust():void {
			// remove the thrust image
			if (this.offsetSprite.contains(this.thrustOffset)) { this.offsetSprite.removeChild(this.thrustOffset); }
					
			// dispatch Event for gamesound
			this.dispatchEvent(this.eFlameOff);
		}
		
		public function rotateCCW():void {	// these will be useful for the lateral booster images once implemented
			this.rotation -= this.angularSpeed;
		}
		
		public function rotateCW():void {
			this.rotation += this.angularSpeed;
		}
		
		//
		///-- Main Loops --///
		//
		
		public function heartBeat():void {
			if (this.notDead) {
				this.mods.heartBeat();
				this.droneBay.heartBeat();
				
				if (this.oTarget != null) {
					this.targetDistance = this.getDistance(this.oTarget, this);
					
					if (this.AI.isChasing) {
						this.getAngleToTarget();
					}
				}
				
				if (this.shield < this.shieldFull) {
					this.shield += this.shieldRegen;
				}
			}
		}
		
		public function main(e:Event):void {
			if (this.AI.isChasing) {
				this.AI.chase();
			}
			
			if (this.AI.isStopping) {
				this.AI.comeToStop();
			}
			
			if (this.AI.isMoving) {
				if (!this.AI.isStopping) {
					this.AI.moveToCoords();
				}
			}
			
			this.x += this.newXv;
			this.y += this.newYv;
		}
		
		//
		///-- Destructor --///
		//
		
		public override function destroy():void {
			if (this.notDead) {
				this.notDead = false;
				this.AI.destroy();
				this.removeEventListener(Event.ENTER_FRAME, main);
				this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
				this.thrustLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, thrustLoaded);
				this.graphics.clear();
				this.mods.destroy();
				this.droneBay.destroy();
				this.oGL.unloadObject(this);
			}
		}
	}
}
