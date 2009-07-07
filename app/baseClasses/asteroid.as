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
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.geom.Rectangle;
	
	import app.loaders.gameloader;
	
	public class asteroid extends Sprite {
		public var imageURL:String = "";
		private var imageDir:String = "";
		private var imageLoader:Loader = new Loader();
		private var offsetSprite:Sprite = new Sprite();
		public var oGL:Object;
		public var dx:Number;						// distance to ship for radar/UI info
		public var dy:Number;
		public var distance:Number;
		public var indx:uint;
		
		// delayed destruct timing
		private var tick:int = 0;
		private var waitTime:int = 2;
		private var isDestruct:Boolean = false;
		
		public var isDockable:Boolean = false;
		public var oTarget:Object = null; // hack
		public var isHostile:Boolean = false; // hack
		public var hull:Number = 20; // hack
		public var shield:Number = 0;
		public var minerals:int;		// amount that can be mined
		public var faction:String = "asteroid";
		
		///-- Constructor --///
		
		public function asteroid(obj:XML, oGL:gameloader):void {
			this.oGL = oGL;
			this.imageDir = this.oGL.imageDir;
			var pos:Array = obj.position.split(',');
			this.x = pos[0];
			this.y = pos[1];
			this.imageURL = obj.imageURL;
			this.rotation = obj.rotation;
			this.minerals = obj.minerals;
			this.name = "Asteroid";
			
			this.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		private function loadImage():void {
			if (this.imageURL != "") {
				this.imageLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
				this.imageLoader.load(new URLRequest(this.imageDir + "/" + this.imageURL));
			}
		}
		
		private function delayedDestruct():void {	// needed because we have to return a value from the function that would other wise call this.destroy()
			if (this.isDestruct) {
				this.tick++;
				
				if (this.tick > this.waitTime) {
					this.tick = 0;
				}
				
				if (this.tick == this.waitTime) {
					this.destroy();
				}
			}
		}
		
		///-- Public Functions --//
		
		public function mine(amount:int):int {
			if (this.minerals - amount > 0) {
				this.minerals -= amount;
			} else {	// all mined out
				this.isDestruct = true;
				amount = this.minerals;
				this.minerals = 0;
			}
			
			return amount;
		}
		
		///-- Event Listners --///
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.loadImage();
		}
		
		private function mouseDownHandler(e:MouseEvent):void {
			this.oGL.playerShip.oTarget = this;
		}
		
		private function imageLoaded(e:Event):void {
			this.imageLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			var bmp:BitmapData = new BitmapData(this.imageLoader.width, this.imageLoader.height, true, 0);
			this.offsetSprite.x = -this.imageLoader.width / 2;
			this.offsetSprite.y = -this.imageLoader.height / 2;
			this.offsetSprite.addChild(this.imageLoader.content);
			this.addChild(this.offsetSprite);
		}
		
		///-- destructor --///
		
		public function destroy():void {
			this.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
			this.oGL.unloadObject(this);
		}
		
		///-- Main Loop --///
		
		public function heartBeat():void {
			if (this.isDestruct) {
				this.delayedDestruct();
			}
		}
	}
}
