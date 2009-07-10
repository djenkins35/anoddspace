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
	import flash.geom.*;
	import flash.net.URLRequest;
	import flash.display.Sprite;
	import flash.display.Shape;
	import flash.display.Loader;
	
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	
	public class targeter extends Sprite {
		public var oTarget:Object;
		public var targetDistance:Number = 0;
		public var targetAngle:Number = 0;
		public var oGL:gameloader;
		public var isHostile:Boolean = false;
		public var hull:Number = 100;
		public var hullFull:Number = 100;
		public var shield:Number = 0;
		public var shieldFull:Number = 0;
		public var shieldRegen:Number = 0;
		public var tick:int = 0;
		public var radarRange:int = 0;				
		public var minRange:int = 0;
		public var attackRange:int = 0;
		public var attackRange2:int = 0;
		public var dx:Number;						// distance to ship for radar/UI info
		public var dy:Number;
		public var distance:Number;
		
		///-- Work in Progress --///
		public var isDockable:Boolean = false;
		public var faction:String = "";				// testing
		public var indx:int = -1;					// index in oGL.objectArray
		public var isGodMode:Boolean = false;
		
		public var tempOverlay:Shape = new Shape();	// overlay when drag-selecting
		public var mainOverlay:Shape = new Shape();	// overlay when selected
		public var grLineStyle:Array = [1, 0xFFFF00];
		public var grLineStyle2:Array = [1, 0x00FFFF];
		///-- --///
		
		public var imageURL:String = "";
		public var imageDir:String = "";
		public var imageLoader:Loader = new Loader();
		public var offsetSprite:Sprite = new Sprite();
		
		public var actionArr:Array;
		
		public const ninety:Number = Math.PI / 2;
		
		//
		///-- Constructor --///
		//
		
		public function targeter():void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(MouseEvent.CLICK, clickHandler);
			this.addEventListener('boxSelected', handleBoxSelect);
			this.addEventListener('boxDeSelected', handleBoxSelect);
			this.addEventListener('toggleSelectOn', handleTempSelect);
			this.addEventListener('toggleSelectOff', handleTempSelect);
			this.addEventListener('cycleTargets', cycleTargets);
			this.addEventListener('InvulnerabilityOn', toggleInvulnerability);
			this.addEventListener('InvulnerabilityOff', toggleInvulnerability);
			this.addEventListener('applyDamage', applyDamage);
		}
		
		public function loadImages():void {
			if (this.imageURL !== "") {
				this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				this.imageLoader.load(new URLRequest(this.imageDir + "/" + this.imageURL));
			}
		}
		
		public function targetClosestEnemy():Boolean {
			var closest:Object = null;
			var objDistance:Number;
			var tempDistance:Number = this.radarRange;	// overwritten by each distance that is closer
			
			// find something to shoot
			for (var i:uint = 0, len:uint = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].faction != this.faction 
					&& this.oGL.objectArray[i].faction != "asteroid") 
				{
					// get what's closest
					objDistance = this.getDistance(this.oGL.objectArray[i], this);
					
					if (objDistance < tempDistance) {
						closest = this.oGL.objectArray[i];
						tempDistance = objDistance;
					}
				}
			}
			
			if (closest != null) {
				this.oTarget = closest;
				this.targetDistance = tempDistance;
				return true;
			} else {
				trace(this.name + " says, no targets in range");
				return false;
			}
		}
		
		public function getDistance(obj1:Object, obj2:Object):Number {
			var dx:Number = Math.abs(obj1.x - obj2.x);
			var dy:Number = Math.abs(obj1.y - obj2.y);
			return Math.sqrt(dx * dx + dy * dy);
		}
		
		public function getAngleToTarget():void {
			var dx:Number = Math.abs(this.x - this.oTarget.x);
			var dy:Number = Math.abs(this.y - this.oTarget.y);
			
			if (this.x == this.oTarget.x) {				// 0 or 180
				if (this.y == this.oTarget.y) {			// same spot
					this.targetAngle = 0; 			// got milk?
				} else if (this.y < this.oTarget.y) {	// 0
					this.targetAngle = 0;
				} else {								// 180
					this.targetAngle = Math.PI;
				}
			} else if (this.x < this.oTarget.x) { 		// right 2 quadrants
				if (this.y == this.oTarget.y) {			// 90
					this.targetAngle = ninety;
				} else if (this.y > this.oTarget.y) {	// top right quad
					this.targetAngle = Math.atan(dx / dy);
				} else {								// bottom right quad
					this.targetAngle = ninety + Math.atan(dy / dx);
				}
			} else {									// left 2 quadrants
				if (this.y == this.oTarget.y) {			// -90
					this.targetAngle = -ninety;
				} else if (this.y > this.oTarget.y) {	// top left quad
					this.targetAngle = -Math.atan(dx / dy);
				} else {								// bottom left quad
					this.targetAngle = -ninety + -Math.atan(dy / dx);
				}
			}
		}
		
		//
		///-- Event Listeners --///
		//
		
		public function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.loadImages();
		}
		
		public function imageLoaded(e:Event):void {
			// draw and cache the select boxes
			this.tempOverlay.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			this.tempOverlay.graphics.drawRect(-10, -10, this.imageLoader.width + 20, this.imageLoader.height + 20);
			this.tempOverlay.cacheAsBitmap = true;
			
			
			// little triangle
			this.mainOverlay.graphics.lineStyle(this.grLineStyle2[0], this.grLineStyle2[1]);
			this.mainOverlay.graphics.moveTo(this.imageLoader.width / 2 - 10, -10);
			this.mainOverlay.graphics.lineTo(this.imageLoader.width / 2 + 10, -10);
			this.mainOverlay.graphics.lineTo(this.imageLoader.width / 2, -20);
			this.mainOverlay.graphics.lineTo(this.imageLoader.width / 2 - 10, -10);
			this.mainOverlay.cacheAsBitmap = true;
			
			this.offsetSprite.x = -this.imageLoader.width / 2;
			this.offsetSprite.y = -this.imageLoader.height / 2;
			this.offsetSprite.addChildAt(this.imageLoader.content, 0);
			this.addChild(this.offsetSprite);
		}
		
		public function clickHandler(e:MouseEvent):void {
			this.oGL.playerShip.oTarget = this;
			this.dispatchEvent(new Event('boxSelected'));
		}
		
		private function handleBoxSelect(e:Event):void {	// show or hide the main overlay
			if (e.type == 'boxSelected') {
				// add mainOverlay
				if (!this.offsetSprite.contains(this.mainOverlay)) {
					this.offsetSprite.addChild(this.mainOverlay);
				}
			} else {
				if (this.offsetSprite.contains(this.mainOverlay)) {
					this.offsetSprite.removeChild(this.mainOverlay);
				}
			}
		}
		
		private function handleTempSelect(e:Event):void {	// show or hide the temporary overlay
			if (e.type == 'toggleSelectOn') {
				this.offsetSprite.addChild(this.tempOverlay);
			} else {
				if (this.offsetSprite.contains(this.tempOverlay)) {
					this.offsetSprite.removeChild(this.tempOverlay);
				}
			}
		}
		
		private function applyDamage(e:dataEvent):void {
			// if not already attacking, aquire closest enemy
			if (!this.isHostile) {
				this.isHostile = true;
				this.targetClosestEnemy();
			}
			
			if (this.shield > 0) {
				if (this.shield - e.dataObj.shield < 0) {	// damage can't all be absorbed by shield
					this.shield = 0;
					
					if (!this.isGodMode) {
						this.hull -= e.dataObj.hull;
					}
				} else {
					this.shield -= e.dataObj.shield;
				}
			} else {
				if (!this.isGodMode) {
					this.hull -= e.dataObj.hull;
				}
			} 
			
			if (this.hull <= 0) {
				this.destroy();
			}
		}
		
		private function toggleInvulnerability(e:Event):void {
			e.type == 'InvulnerabilityOn' ? this.isGodMode = true : this.isGodMode = false;
		}
		
		private function cycleTargets(e:Event):void {		// this is pretty ugly
			if (this.oTarget != null) {
				var targetIndex:int = this.oTarget.indx;
				
				if (targetIndex + 1 != this.indx) {								// make sure not to target self
					if (targetIndex + 1 < this.oGL.objectArray.length) {
						this.oTarget = this.oGL.objectArray[targetIndex + 1];
					} else {													// loop around
						if (this.indx != 0) {									// make sure not to target self
							this.oTarget = this.oGL.objectArray[0];
						} else {
							try {
								this.oTarget = this.oGL.objectArray[1];
							} catch (e:Error) {
								trace("no more objects in this.oGL.objectArray to cycle through");
							}
						}
					}
				} else {														// go to next index
					if (targetIndex + 2 < this.oGL.objectArray.length) {
						this.oTarget = this.oGL.objectArray[targetIndex + 2];
					} else {													// loop around
						if (this.indx != 0) {									// make sure not to target self
							this.oTarget = this.oGL.objectArray[0];
						} else {
							try {
								this.oTarget = this.oGL.objectArray[1];
							} catch (e:Error) {
								trace("no more objects in this.oGL.objectArray to cycle through");
							}
						}
					}
				}
			} else {
				if (this.indx != 0) {											// make sure not to target self
					this.oTarget = this.oGL.objectArray[0];
				} else {
					try {
						this.oTarget = this.oGL.objectArray[1];
					} catch (e:Error) {
						trace("no more objects in this.oGL.objectArray to cycle through");
					}
				}
			}
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {	// overridden by most subclasses
			this.removeEventListener('boxSelected', handleBoxSelect);
			this.removeEventListener('boxDeSelected', handleBoxSelect);
			this.removeEventListener('toggleSelectOn', handleTempSelect);
			this.removeEventListener('toggleSelectOff', handleTempSelect);
			this.removeEventListener('cycleTargets', cycleTargets);
			this.removeEventListener('InvulnerabilityOn', toggleInvulnerability);
			this.removeEventListener('InvulnerabilityOff', toggleInvulnerability);
			this.removeEventListener('applyDamage', applyDamage);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.imageLoader = null;
			this.oGL.unloadObject(this);
		}
	}
}
