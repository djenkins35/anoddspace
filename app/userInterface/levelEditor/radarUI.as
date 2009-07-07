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


package app.userInterface.levelEditor {
	import flash.text.*;
	import flash.events.*;
	import flash.display.*
	import flash.geom.*
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class radarUI extends Sprite {
		private var txtColor:uint = 0xFFFFFF;
		private var lineStyle:Array = [1, 0xFFFFFF];
		private var fillStyle:Array = [0x555555, 0.3]
		private var radarDims:Array = [599, 399, 200, 200];		// x,y,width,height
		
		private var panOverlayDims:Array = [0, 0, 0, 0];		// set based on local coordinates
		private var panOverlay:Shape = new Shape();
		private var radar:Sprite = new Sprite();
		private var radarBG:Shape = new Shape();
		private var radarFG:Sprite = new Sprite();
		private var radarOverlay:Sprite = new Sprite();
		private var pGlOverlay:Point = new Point();				// used in panScreen() for coodinate mapping
		public var oGL:*;
		public var radarRange:Number = 40000;
		public var radarZoom:Number = 1;
		private var scale:Number;
		
		public function radarUI(oGL:*):void {
			this.oGL = oGL;
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.scale = this.radarDims[2] / (this.radarRange * this.radarZoom);
		}
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.drawRadar();
			
			// for moving the pan overlay when panning via arrowkeys
			this.oGL.gamescreen.addEventListener('radarPanChanged', handleZoomChange);
		}
		
		///-- --///
		
		private function drawRadar():void {		// need to add circular mask at some point
			this.radarBG.cacheAsBitmap = true;
			this.radarBG.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.radarBG.graphics.beginFill(this.fillStyle[0], this.fillStyle[1]);
			this.radarBG.graphics.drawRect(0, 0, this.radarDims[2], radarDims[3]);
			this.radarBG.graphics.endFill();
			this.radar.addChild(this.radarBG);
			this.radar.addChild(this.radarFG);
			this.radar.x = radarDims[0];
			this.radar.y = radarDims[1];
			
			this.drawRadarOverlay();
			this.addChild(this.radar);
		}
		
		private function drawRadarOverlay():void {
			this.radarOverlay.cacheAsBitmap = true;
			this.radarOverlay.graphics.clear();
			this.radarOverlay.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.radarOverlay.graphics.moveTo(98, 100);
			this.radarOverlay.graphics.lineTo(103, 100);
			this.radarOverlay.graphics.moveTo(100, 98);
			this.radarOverlay.graphics.lineTo(100, 103);
			this.radar.addChild(this.radarOverlay);
		}
		
		///-- Pan Overlay --///
		
		public function drawPanOverlay():void {		// used for the level editor pan / move
			if (this.radar.contains(this.radarOverlay)) {
				this.radar.removeChild(this.radarOverlay);
			}
			
			// get local coordinates of the viewscreen / stage
			var stageOrigin:Point = new Point();
			var gTopRight:Point = new Point();
			var gBotLeft:Point = new Point();
			var gBotRight:Point = new Point();
			
			stageOrigin.x = this.stage.x;
			stageOrigin.y = this.stage.y;
			gTopRight.x = this.stage.stageWidth;
			gTopRight.y = this.stage.y;
			gBotLeft.x = this.stage.x;
			gBotLeft.y = this.stage.stageHeight;
			gBotRight.x = this.stage.stageWidth;
			gBotRight.y = this.stage.stageHeight;
			
			var localOrigin:Point = this.oGL.gamescreen.globalToLocal(stageOrigin);
			var loTopRight:Point = this.oGL.gamescreen.globalToLocal(gTopRight);
			var loBotLeft:Point = this.oGL.gamescreen.globalToLocal(gBotLeft);
			var loBotRight:Point = this.oGL.gamescreen.globalToLocal(gBotRight);
			
			// draw an overlay on the radar
			var xOffset:Number = this.radarDims[2] / 2;
			var yOffset:Number = this.radarDims[3] / 2;
			var overlayW:Number = Math.abs(localOrigin.x - loTopRight.x) * scale;
			var overlayH:Number = Math.abs(localOrigin.y - loBotLeft.y) * scale;
			var overlayX:Number = localOrigin.x * this.scale - xOffset;
			var overlayY:Number = localOrigin.y * this.scale - yOffset;
			
			this.radarOverlay.cacheAsBitmap = true;
			this.radarOverlay.graphics.clear();
			this.radarOverlay.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.radarOverlay.graphics.beginFill(this.fillStyle[0], 0);	// transparent
			this.radarOverlay.graphics.drawRect(overlayX, overlayY, overlayW, overlayH);
			this.radarOverlay.graphics.endFill();
			
			this.radarOverlay.x = this.radarDims[2];
			this.radarOverlay.y = this.radarDims[3];
			this.radar.addChild(this.radarOverlay);
			
			if (!this.radarOverlay.hasEventListener(MouseEvent.MOUSE_DOWN)) {
				this.radarOverlay.addEventListener(MouseEvent.MOUSE_DOWN, onPanDrag);
			}
			
			if (!this.oGL.gamescreen.hasEventListener(MouseEvent.MOUSE_WHEEL)) {
				this.oGL.gamescreen.addEventListener(MouseEvent.MOUSE_WHEEL, handleZoomChange);
			}
		}
		
		public function calculateRadar():void {
			this.radarFG.graphics.clear();
			this.radarFG.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			
			// get distances for the radar
			for (var i:uint = 0, len:int = this.oGL.objectArray.length; i < len; i++) {
				// calculate distances for radar/UI info
				var coords:Array = this.oGL.objectArray[i].position.split(',');
				
				// scale to match radar
				var dx:Number = coords[0] * this.scale;
				var dy:Number = coords[1] * this.scale;
				
				// add offset
				dx += this.radarDims[2] / 2;
				dy += this.radarDims[3] / 2;
				
				// draw a blip
				this.radarFG.graphics.moveTo(dx, dy);
				this.radarFG.graphics.lineTo(dx + 1, dy);
			}
		}
		
		///-- Event Listeners --///
		
		private function handleZoomChange(e:Event):void {
			this.drawPanOverlay();
		}
		
		private function onPanDrag(e:MouseEvent):void {
			this.radarOverlay.startDrag();
			this.radarOverlay.addEventListener(MouseEvent.MOUSE_UP, stopPanDrag);
			this.radarOverlay.addEventListener(MouseEvent.MOUSE_MOVE, panScreen);
			this.drawPanOverlay();
		}
		
		private function panScreen(e:MouseEvent):void {
			this.pGlOverlay.x = e.stageX;
			this.pGlOverlay.y = e.stageY;
			
			// map stage coordinates to this.radar coordinate system
			var pLocal:Point = this.radarBG.globalToLocal(this.pGlOverlay);
			this.oGL.dragMap((pLocal.x - this.radarDims[2] / 2) / this.scale, (pLocal.y - this.radarDims[3] / 2) / this.scale);
		}
		
		private function stopPanDrag(e:MouseEvent):void {
			this.radarOverlay.removeEventListener(MouseEvent.MOUSE_UP, stopPanDrag);
			this.radarOverlay.removeEventListener(MouseEvent.MOUSE_MOVE, panScreen);
			this.radarOverlay.stopDrag();
			this.drawPanOverlay();
		}
		
		///-- --///
		
		public function destroy():void {
			this.oGL.gamescreen.removeEventListener('radarPanChanged', handleZoomChange);
			this.radarBG.graphics.clear();
			this.radarFG.graphics.clear();
			this.parent.removeChild(this);
		}
	}
}
