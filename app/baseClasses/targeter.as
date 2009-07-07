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
		
		public var selectBox:Shape = new Shape();
		public var indicator:Shape = new Shape();
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
		}
		
		public function loadImages():void {
			if (this.imageURL !== "") {
				this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				this.imageLoader.load(new URLRequest(this.imageDir + "/" + this.imageURL));
			}
		}
		
		//public function doAction(s:String):void {}	// overridden by most subclasses
		
		public function attack():void {}			// overridden by most subclasses
		
		public function targetClosestEnemy():Boolean {
			var closest:* = null;
			var dist:Number = this.radarRange;
			
			// find something to shoot
			for (var i:uint = 0, len:uint = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].faction != this.faction 
					&& this.oGL.objectArray[i].faction != "asteroid") 
				{
					// get what's closest
					var targetDist:Number = this.getDistance(this.oGL.objectArray[i].x - this.x, this.oGL.objectArray[i].y - this.y);
					
					if (targetDist < dist) {
						closest = this.oGL.objectArray[i];
						dist = targetDist;
					}
				}
			}
			
			if (closest != null) {
				this.oTarget = closest;
				this.targetDistance = dist;
				return true;
			} else {
				trace(this.name + " says, no targets in range");
				return false;
			}
		}
		
		public function cycleTargets():void {		// this is pretty ugly
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
				
		public function applyDamage(damageShield:Number, damageHull:Number):void {	// needs work
			if (!this.isHostile) {						// if not already attacking, aquire closest enemy
				this.isHostile = true;
				this.targetClosestEnemy();
			}
			
			if (this.shield > 0) {
				if (this.shield - damageShield < 0) {	// carry over damage to hull
					this.shield = 0;
					
					if (!this.isGodMode) {
						this.hull -= damageHull;
					}
				} else {
					this.shield -= damageShield;
				}
			} else {
				if (!this.isGodMode) {
					this.hull -= damageHull;
				}
			} 
			
			if (this.hull <= 0) {
				this.destroy();
			}
		}
		
		public function toggleGodMode():void {
			if (this.isGodMode) {
				this.isGodMode = false;
			} else {
				this.isGodMode = true;
			}
		}
		
		// need to fix these at some point, first one is less useful
		
		public function getDistanceToTarget():void {
			var dx:Number = Math.abs(this.x - this.oTarget.x);
			var dy:Number = Math.abs(this.y - this.oTarget.y);
			this.targetDistance = Math.sqrt(dx * dx + dy * dy);
		}
		
		public function getDistance(dx:Number, dy:Number):Number {
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
			this.addEventListener(MouseEvent.CLICK, clickHandler);
			this.addEventListener(Event.ENTER_FRAME, main);
			this.loadImages();
			
			this.addEventListener('boxSelected', handleBoxSelect);
			this.addEventListener('boxDeSelected', handleBoxSelect);
			this.addEventListener('toggleSelectOn', handleTempSelect);
			this.addEventListener('toggleSelectOff', handleTempSelect);
		}
		
		public function clickHandler(e:MouseEvent):void {
			this.oGL.playerShip.oTarget = this;
			this.dispatchEvent(new Event('boxSelected'));
		}
		
		public function imageLoaded(e:Event):void {
			// draw and cache the select boxes
			this.selectBox.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			this.selectBox.graphics.drawRect(-10, -10, this.imageLoader.width + 20, this.imageLoader.height + 20);
			this.selectBox.cacheAsBitmap = true;
			
			// little triangle
			this.indicator.graphics.lineStyle(this.grLineStyle2[0], this.grLineStyle2[1]);
			this.indicator.graphics.moveTo(this.imageLoader.width / 2 - 10, -10);
			this.indicator.graphics.lineTo(this.imageLoader.width / 2 + 10, -10);
			this.indicator.graphics.lineTo(this.imageLoader.width / 2, -20);
			this.indicator.graphics.lineTo(this.imageLoader.width / 2 - 10, -10);
			this.indicator.cacheAsBitmap = true;
			
			this.offsetSprite.x = -this.imageLoader.width / 2;
			this.offsetSprite.y = -this.imageLoader.height / 2;
			this.offsetSprite.addChildAt(this.imageLoader.content, 0);
			this.addChild(this.offsetSprite);
		}
		
		private function handleBoxSelect(e:Event):void {
			if (e.type == 'boxSelected') {
				// add indicator
				if (!this.offsetSprite.contains(this.indicator)) {
					this.offsetSprite.addChild(this.indicator);
				}
			} else {
				if (this.offsetSprite.contains(this.indicator)) {
					this.offsetSprite.removeChild(this.indicator);
				}
			}
		}
		
		private function handleTempSelect(e:Event):void {
			if (e.type == 'toggleSelectOn') {
				this.offsetSprite.addChild(this.selectBox);
			} else {
				if (this.offsetSprite.contains(this.selectBox)) {
					this.offsetSprite.removeChild(this.selectBox);
				}
			}
		}
		
		//
		///-- destructor --///
		//
		
		public function destroy():void {	// overridden by most subclasses
			this.removeEventListener('boxSelected', handleBoxSelect);
			this.removeEventListener('boxDeSelected', handleBoxSelect);
			this.removeEventListener('toggleSelectOn', handleTempSelect);
			this.removeEventListener('toggleSelectOff', handleTempSelect);
			this.removeEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.imageLoader = null;
			this.oGL.unloadObject(this);
		}
		
		///-- main loop --///
		
		public function main(e:Event):void {	// overridden by most subclasses
		
		}
	}
}
