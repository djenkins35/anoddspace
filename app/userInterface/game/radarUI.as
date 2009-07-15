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


package app.userInterface.game {

	import flash.events.*;
	import flash.display.Sprite;
	import flash.display.Shape;

	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Text;
	import mx.events.*;
	
	import app.loaders.gameloader;
	
	public class radarUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		
		// Display Properties
		private var radar:Sprite = new Sprite();			// container for graphics
		private var radarBG:Shape = new Shape();			// background
		private var radarFG:Sprite = new Sprite();			// blips go here
		private var radarOverlay:Sprite = new Sprite();		// container for the crosshair
		private var coordText:Text = new Text();			// TextBox for playership's coordinates
		private var grLineStyle:Array = [1,0xFFFFFF];
		private var bgAlpha:Number = 0.3;
		private var bgFillColor:uint = 0x555555;
		private var radarDims:Array = [0,0,200,200];		// x,y,w,h
		
		//
		///-- Constructor --///
		//
		
		public function radarUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
		}
		
		//
		///-- Private Methods --///
		//
		
		private function drawRadar():void {
			this.radarBG.cacheAsBitmap = true;
			this.radarBG.alpha = this.bgAlpha;
			this.radarBG.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			this.radarBG.graphics.beginFill(this.bgFillColor);
			this.radarBG.graphics.drawRect(this.radarDims[0],this.radarDims[1],this.radarDims[2],this.radarDims[3]);
			this.radarBG.graphics.endFill();
			this.radar.addChild(this.radarBG);
			this.radar.addChild(this.radarFG);
			
			this.radarOverlay.cacheAsBitmap = true;
			this.radarOverlay.graphics.clear();
			this.radarOverlay.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			this.radarOverlay.graphics.moveTo(98, 100);
			this.radarOverlay.graphics.lineTo(103, 100);
			this.radarOverlay.graphics.moveTo(100, 98);
			this.radarOverlay.graphics.lineTo(100, 103);
			this.radar.addChild(this.radarOverlay);
			
			this.rawChildren.addChild(this.radar);
			this.addChild(this.coordText);
			this.coordText.selectable = false;
		}
		
		private function getTargetDistance(dx:Number, dy:Number):Number {	// used in heartbeat loop
			var maxRange:Number = this.oGL.playerShip.radarRange;						// throw out anything that is definitely out of range
			
			if (dx <= maxRange && dy <= maxRange) { 						// maybe in range
				var dist:Number = Math.sqrt(dx * dx + dy * dy);
				
				if (dist <= maxRange) {
					return dist;
				} else {
					return -1;
				}
			} else {
				return -1;
			}
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			// draw radar
			this.drawRadar();
			
			// add event listener for heartbeat timer
			this.oGL.heartBeatTimer.addEventListener(TimerEvent.TIMER, heartBeat);
		}
		
		//
		///-- Main Loop --///
		//
		
		private function heartBeat(e:TimerEvent):void {
			var dx:Number;
			var dy:Number;
			var scaledX:Number;
			var scaledY:Number;
			
			this.radarFG.graphics.clear();
			this.radarFG.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			
			for (var i:uint = 0, arrLength:uint = this.oGL.objectArray.length; i < arrLength; i++) {
				dx = this.oGL.objectArray[i].x - this.oGL.playerShip.x;
				dy = this.oGL.objectArray[i].y - this.oGL.playerShip.y;
				this.oGL.objectArray[i].dx = dx;
				this.oGL.objectArray[i].dy = dy;
				this.oGL.objectArray[i].distance = this.getTargetDistance(dx, dy);
				
				if (this.oGL.objectArray[i].distance != -1) {	// within range
					scaledX = this.oGL.objectArray[i].dx  * 100 / this.oGL.playerShip.radarRange;
					scaledY = this.oGL.objectArray[i].dy * 100 / this.oGL.playerShip.radarRange;
					this.radarFG.graphics.moveTo(scaledX + 100, scaledY + 100);
					this.radarFG.graphics.lineTo(scaledX + 101, scaledY + 101);
				}
			}
			
			this.coordText.text = '(' + Math.round(this.oGL.playerShip.x) + ',' + Math.round(this.oGL.playerShip.y) + ')';
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.oGL.heartBeatTimer.removeEventListener(TimerEvent.TIMER, heartBeat);
			this.parent.removeChild(this);
		}
	}
}
