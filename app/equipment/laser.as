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
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.net.URLRequest;
	import flash.geom.*;
	
	import app.loaders.dataEvent;
	
	public class laser extends Sprite {
		public var imageURL:String = "";
		public var imageDir:String = "images/";
		public var imageLoader:Loader = new Loader();
		private var offsetSprite:Sprite = new Sprite();
		private const ninety:Number = Math.PI / 2;
		private var tick:uint = 0;
		
		public var damageShield:Number;
		public var damageHull:Number;
		public var delay:int;
		public var duration:int;
		public var attackRange:uint;
		public var grLineStyle:Array;
		public var oParent:* = null;
		public var isActive:Boolean = false;
		private var isLaser:Boolean = false;
		private var localIt:Point = new Point();
		private var globalIt:Point = new Point();
		private var oTarget:* = null;
		
		//
		///-- Constructor --///
		//
		
		public function laser(oParent:*, xSpec:XML):void {
			this.name = xSpec.name;
			this.imageURL = xSpec.imageURL;
			this.damageShield = xSpec.damageShield;
			this.damageHull = xSpec.damageHull;
			this.delay = xSpec.delay;
			this.duration = xSpec.duration;
			this.attackRange = xSpec.attackRange;
			this.grLineStyle = xSpec.grLineStyle.split(',');
		
			this.oParent = oParent;
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		//
		///-- Private Methods --///
		//
		
		public function loadImages():void {
			if (this.imageURL !== "") {
				this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				this.imageLoader.load(new URLRequest(this.imageDir + this.imageURL));
			}
		}
		
		public function imageLoaded(e:Event):void {
			this.offsetSprite.x = -this.imageLoader.width / 2;
			this.offsetSprite.y = -this.imageLoader.height / 2;
			this.offsetSprite.addChild(this.imageLoader.content);
			this.addChild(this.offsetSprite);
		}
		
		private function laserBeans():void {
			if (this.oTarget.hasOwnProperty('hull')) {	// don't shoot asteroids
				this.oParent.isHostile = true;
				
				var dist:Number = this.oParent.getDistance(this.oTarget.x - this.oParent.x, this.oTarget.y - this.oParent.y);
				
				// make sure our target isn't gone or out of range
				if (this.oParent.oGL.objectArray.indexOf(this.oTarget) != -1) {
					if (dist <= this.attackRange) {
						var stopTime:int = this.delay + this.duration;
						
						if (this.tick >= this.delay && this.tick < stopTime) {
							this.isLaser = true;
							this.oParent.oGL.oGS.playSound("laserSound", "play");
						} else if (this.tick >= stopTime) {
							this.isLaser = false;
							this.oParent.oGL.oGS.playSound("laserSound", "stop");
							
							// apply damage
							this.oTarget.dispatchEvent(new dataEvent({ shield: this.damageShield, hull: this.damageHull}, 'applyDamage'));
							this.tick = 0;
						}
					} else {
						this.isLaser = false;
						this.oParent.oGL.oGS.playSound("laserSound", "stop");
					}
				} else {
					this.isLaser = false;
					this.isActive = false;
					this.oParent.oGL.oGS.playSound("laserSound", "stop");
				}
			}
		}
		
		//
		///-- Event listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.ENTER_FRAME, main);
			
			/*this.offsetSprite.graphics.lineStyle(1, 0x000000);
			this.offsetSprite.graphics.beginFill(0xFFFFFF);
			this.offsetSprite.graphics.drawEllipse(0, 0, 10, 10);
			this.offsetSprite.graphics.endFill();
			this.addChild(this.offsetSprite);*/
			
			this.oParent.addEventListener('toggleModules', toggleModules);
			this.oParent.addEventListener('toggleModulesOn', toggleModulesOn);
			this.oParent.addEventListener('toggleModulesOff', toggleModulesOff);
		}
		
		public function toggleModules(e:Event):void {
			this.oTarget = this.oParent.oTarget;
			
			if (this.isActive == false) {
				this.isActive = true;
			} else {
				this.isActive = false;
			}
		}
		
		public function toggleModulesOn(e:Event):void {
			this.oTarget = this.oParent.oTarget;
			this.isActive = true;
		}
		
		public function toggleModulesOff(e:Event):void {
			this.isActive = false;
		}
		
		//
		///-- Main Loops --///
		//
		
		public function heartBeat():void {
			this.tick++;
			//this.graphics.clear();
			
			if (this.oTarget != null && this.isActive) {
				this.laserBeans();
			} else {
				this.isLaser = false;
			}
		}
		
		public function main(e:Event):void {
			this.graphics.clear();
			
			if (this.isLaser == true) {
				this.localIt.x = this.oTarget.x;
				this.localIt.y = this.oTarget.y;
				this.globalIt = this.globalToLocal(this.oParent.oGL.gamescreen.localToGlobal(localIt));
				this.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1], this.grLineStyle[2]);
				this.graphics.moveTo(5,5);
				this.graphics.lineTo(this.globalIt.x, this.globalIt.y);
			}
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.oParent.removeEventListener('toggleModules', toggleModules);
			this.oParent.removeEventListener('toggleModulesOn', toggleModulesOn);
			this.oParent.removeEventListener('toggleModulesOff', toggleModulesOff);
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.graphics.clear();
			this.parent.removeChild(this);
		}
	}
}
