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

	import mx.containers.Canvas;
	import mx.events.*;
	import mx.controls.ProgressBar;
	import mx.containers.VBox;
	
	import app.loaders.gameloader;
	
	public class playerShipUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var hullFullRef:int = 0;
		private var shieldFullRef:int = 0;
		
		// Display Properties
		private var shipHealthBar:ProgressBar = new ProgressBar();
		private var shipShieldBar:ProgressBar = new ProgressBar();
		
		//
		///-- Constructor --///
		//
		
		public function playerShipUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.oGL.addEventListener('gameLoaded', gameLoadedHandler);
		}
		
		///-- Private Methods --///
		
		///-- Event Listeners --///
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			var oContainer:VBox = new VBox();
			
			// ship shield bar
			this.shipShieldBar.label = "Shield";
			this.shipShieldBar.labelPlacement = "left";
			this.shipShieldBar.mode = "manual";
			oContainer.addChild(this.shipShieldBar);
			
			// ship health bar
			this.shipHealthBar.label = "Hull";
			this.shipHealthBar.labelPlacement = "left";
			this.shipHealthBar.mode = "manual";
			oContainer.addChild(this.shipHealthBar);
			
			oContainer.setStyle("horizontalAlign", "right");
			this.addChild(oContainer);
		}
		
		private function gameLoadedHandler(e:Event):void {
			this.hullFullRef = this.oGL.playerShip.hullFull;
			this.shieldFullRef = this.oGL.playerShip.shieldFull;
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onEnterFrame(e:Event):void {
			this.shipShieldBar.setProgress(this.oGL.playerShip.shield, this.shieldFullRef);
			this.shipHealthBar.setProgress(this.oGL.playerShip.hull, this.hullFullRef);
		}
		
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.oGL.removeEventListener('gameLoaded', gameLoadedHandler);
		}
	}
}
