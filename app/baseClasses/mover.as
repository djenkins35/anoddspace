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
	import flash.display.Loader;
	
	import app.loaders.gameloader;
	import app.baseClasses.targeter;
	
	public class mover extends targeter {
		public var velocity:Number = 0;
		public var isMoving:Boolean = false;
		public var acceleration:Number = 0;
		public var angularSpeed:Number = 0;
		public var maxSpeed:Number = 0;
		public var trajectory:Number = 0;
		
		public var thrustImageURL:String = "";
		public var thrustLoader:Loader = new Loader();
		public var thrustOffset:Sprite = new Sprite();
		public var thrustOffsetX:int = 0;
		public var thrustOffsetY:int = 0;
		
		public var zig:Number;
		public var isZig:Boolean = false;
		
		public function mover():void {
			// no idea what to use as a constructor for this, probably doesn't need one
		}
		
		public override function loadImages():void {
			if (this.imageURL !== "") {
				this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				this.imageLoader.load(new URLRequest(this.imageDir + "/" + this.imageURL));
			}
			
			if (this.thrustImageURL !== "") {
				this.thrustLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, thrustLoaded);
				this.thrustLoader.load(new URLRequest(this.imageDir + "/" + this.thrustImageURL));
			}
		}
		
		public function thrustLoaded(e:Event):void {
			this.thrustOffset.x = this.thrustOffsetX;
			this.thrustOffset.y = this.thrustOffsetY;
			this.thrustOffset.addChild(this.thrustLoader.content);
		}
		
		public function attack():void {
			if (this.targetDistance > this.attackRange) {
				this.chase();
				this.isZig = false;
			} else {
				if (!this.isZig) {
					this.getZig();
				}
				
				this.orbit();
			}
		}
		
		public function getZig():void {
			var x:Number = Math.random();
			if (x >= 0.5) {
				this.zig = this.ninety;
			} else {
				this.zig = -this.ninety;
			}
			
			this.isZig = true;
		}
		
		public function accelerate():void {
			if (this.velocity < this.maxSpeed) {
				this.velocity += this.acceleration;
			}
		}
		
		public function chase():void {
			super.getAngleToTarget();
			
			if (this.targetAngle >= 0 && this.targetAngle <= Math.PI) {
				if (this.targetAngle + this.acceleration < this.targetAngle) {
					this.trajectory += this.targetAngle;
				} else {
					this.trajectory = this.targetAngle;
				}
			} else if (this.targetAngle < 0 && this.targetAngle >= -Math.PI) {
				if (this.targetAngle - this.acceleration > this.targetAngle) {
					this.trajectory -= this.targetAngle;
				} else {
					this.trajectory = this.targetAngle;
				}
			}
			
			this.accelerate();
		}
		
		public function orbit():void {
			//
			// as targetDistance approaches attackRange2, targetAngle - 90 approaches 0
			// zed should be 0 at attackRange and approach 1 at attackRange2
			// zig is either 90 or -90 (in radians) for circling CW or CCW
			//
			var zed:Number = 1 - (this.targetDistance / this.attackRange);
			this.getAngleToTarget();
			
			if (this.zig > 0) {
				if (this.targetAngle + this.zig * zed < this.targetAngle + this.zig * zed - this.angularSpeed) {
					this.trajectory = this.targetAngle + this.zig * zed;
				} else {
					this.trajectory = this.targetAngle + this.zig * zed + this.angularSpeed;
				}
			} else {
				if (this.targetAngle + this.zig * zed < this.targetAngle + this.zig * zed - this.angularSpeed) {
					this.trajectory = this.targetAngle + this.zig * zed;
				} else {
					this.trajectory = this.targetAngle + this.zig * zed - this.angularSpeed;
				}
			}
			
			this.accelerate();
		}
		
		public function translatePoint(angle:Number, distance:Number):void {
			this.x = this.x + distance * Math.sin(angle);
			this.y = this.y - distance * Math.cos(angle);
		}
		
		///-- --///
		
		public override function destroy():void {
			this.removeEventListener(MouseEvent.MOUSE_DOWN, clickHandler);
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.imageLoader = null;
			this.thrustLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, thrustLoaded);
			this.thrustLoader = null;
			this.oGL.unloadObject(this);
		}
	}
}
