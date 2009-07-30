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


package app.loaders {
	import flash.events.*;
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.geom.*;
	import flash.display.Loader;
	import flash.display.BitmapData;
	import flash.net.URLRequest;
	
	import app.loaders.gameloader;
	
	public class parallax extends Sprite {
		private var imageDir:String = '';
		//public var imageURL:String = "/parallax.01.1024.png";	// hack
		public var imageURL:String = "/parallax.01.1024.jpg";	// hack
		private var loader:Loader = new Loader();
		private var parallax1:Sprite = new Sprite();
		public var zoomLevel:Number = 0.5;
		private var maxZoom:Number = 2;
		private var minZoom:Number = 0.2;
		private var zoomInterval:Number = 1.1;
		public var oGL:* = null;
		public var isParallax:Boolean = false;
		
		public var focalPoint:*;								// 'realMover' if called from gameloader.as or Point if called from levelEditor.as
		public var stageCenter:Point = new Point();
		private var stageOrigin:Point = new Point();
		
		public function parallax(oGL:*) {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.imageURL = oGL.imageDir + this.imageURL;
			this.oGL.addEventListener('BackgroundOn', toggleParallax);
			this.oGL.addEventListener('BackgroundOff', toggleParallax);
		}
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.stageOrigin.x = this.stage.x;
			this.stageOrigin.y = this.stage.y;
			//this.stageCenter.x = this.stage.stageWidth / 2;
			//this.stageCenter.y = this.stage.stageHeight / 2;
			this.stageCenter.x = 400;
			this.stageCenter.y = 300;
			
			this.loadImages();
			this.toggleParallax(new Event('foo'));
			this.addEventListener(Event.ENTER_FRAME, main);
		}
		
		private function loadImages():void {
			var request:URLRequest = new URLRequest(this.imageURL);
			this.loader.load(request);
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, drawImages);
		}

		private function drawImages(event:Event):void {
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, drawImages);
			
			//this.parallax1.scaleX = this.parallax1.scaleY = 5;
			this.parallax1.scaleX = this.parallax1.scaleY = 11.71875;
			
			var myBitmap:BitmapData = new BitmapData(this.loader.width, this.loader.height, true, 0);
			
			myBitmap.draw(loader);
			
			this.parallax1.graphics.beginBitmapFill(myBitmap);
            this.parallax1.graphics.drawRect(0, 0, 2400, 1800);
            this.parallax1.graphics.endFill();
			//this.parallax1.addChild(this.loader.content);
			this.parallax1.x = -6000;
			this.parallax1.y = -4500
			if (this.isParallax) {this.oGL.gamescreen.addChildAt(this.parallax1, 0)};
		}

		private function centerOnFocus():void {
			var localStageCenter:Point = this.oGL.gamescreen.globalToLocal(this.stageCenter);
			var localStageOrigin:Point = this.oGL.gamescreen.globalToLocal(this.stageOrigin);
			
			this.oGL.gamescreen.x = this.oGL.gamescreen.scaleX * (localStageCenter.x - localStageOrigin.x - this.focalPoint.x);
			this.oGL.gamescreen.y = this.oGL.gamescreen.scaleY * (localStageCenter.y - localStageOrigin.y - this.focalPoint.y);
			
			if (this.isParallax) {
				if (localStageOrigin.x <= this.parallax1.x) {
					this.parallax1.x -= 8000;
				} else if (localStageOrigin.x >= this.parallax1.x + 8000) {
					this.parallax1.x += 8000;
				}
				
				if (localStageOrigin.y <= this.parallax1.y) {
					this.parallax1.y -= 6000;
				} else if (localStageOrigin.y >= this.parallax1.y + 6000) {
					this.parallax1.y += 6000;
				}
			}
			
		}
		
		private function zoom():void {
			this.oGL.gamescreen.scaleX = this.zoomLevel;
			this.oGL.gamescreen.scaleY = this.zoomLevel;
			
			//this.parallax1.scaleX = this.zoomLevel;
			//this.parallax1.scaleY = this.zoomLevel;
		}
		
		public function zoomIn():void {
			var newZoom:Number = this.zoomLevel * this.zoomInterval;
			
			if (newZoom >= this.maxZoom) {
				this.zoomLevel = this.maxZoom;
				this.zoom();
			} else if (newZoom < this.maxZoom) {
				this.zoomLevel = newZoom;
				this.zoom();
			}
		}
		
		public function zoomOut():void {
			var newZoom:Number = this.zoomLevel / this.zoomInterval;
			
			if (newZoom <= this.minZoom) {
				this.zoomLevel = this.minZoom;
				this.zoom();
			} else if (newZoom > this.minZoom) {
				this.zoomLevel = newZoom;
				this.zoom();
			}
		}
		
		public function toggleParallax(e:Event):void {
			if (this.isParallax) {
				this.isParallax = false;
				this.oGL.gamescreen.removeChild(this.parallax1);
			} else {
				this.isParallax = true;
				this.oGL.gamescreen.addChildAt(this.parallax1, 0);
			}
		}
		
		///-- destructor --///
		
		public function destroy():void {
			
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.oGL.removeEventListener('BackgroundOn', toggleParallax);
			this.oGL.removeEventListener('BackgroundOff', toggleParallax);
			
			try {
				this.oGL.gamescreen.removeChild(this.parallax1);
			} catch(e:Error) {
				trace("child doesn't exist in parallax destructor");
			}
			
			this.parent.removeChild(this);
		}
		
		///-- main loop --///
		
		private function main(e:Event):void {
			this.centerOnFocus();
		}
	}
}
