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
	
	import mx.events.*;
	import mx.containers.Canvas;
	import mx.containers.TitleWindow;
	import mx.containers.VBox;
	import mx.controls.CheckBox;
	
	import app.loaders.gameloader;
	import app.userInterface.game.gameUI;
	
	public class gameOptionsUI extends TitleWindow {
		
		// Data Properties
		private var oGL:gameloader;
		private var UI:gameUI;
		private var sTitle:String = "Game Options";
		
		// Display Properties
		private var invulnBox:CheckBox = new CheckBox();
		private var soundBox:CheckBox = new CheckBox();
		private var debugBox:CheckBox = new CheckBox();
		private var bgBox:CheckBox = new CheckBox();
		private var radarBox:CheckBox = new CheckBox();
		
		//
		///-- Constructor --///
		//
		
		public function gameOptionsUI(oGL:gameloader, UI:gameUI):void {
			this.oGL = oGL;
			this.UI = UI;
			
			// get enabled options
			if (this.oGL.playerShip.isGodMode) {
				this.invulnBox.selected = true;
			}

			if (this.oGL.oGS.isSound) {
				this.soundBox.selected = true;
			}
			
			if (this.UI.isDebug) {
				this.debugBox.selected = true;
			}
			
			if (this.oGL.pllx.isParallax) {
				this.bgBox.selected = true;
			}
			
			if (this.UI.isRadar) {
				this.radarBox.selected = true;
			}
			
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		private function drawWindow():void {
			var oBox:VBox = new VBox();
			
			this.invulnBox.label = "Invulnerability";
			this.invulnBox.addEventListener(MouseEvent.CLICK, checkOptions);
			oBox.addChild(this.invulnBox);
			
			this.soundBox.label = "Sound";
			this.soundBox.addEventListener(MouseEvent.CLICK, checkOptions);
			oBox.addChild(this.soundBox);
			
			this.debugBox.label = "Debug Window";
			this.debugBox.addEventListener(MouseEvent.CLICK, checkOptions);
			oBox.addChild(this.debugBox);
			
			this.bgBox.label = "Background Image";
			this.bgBox.addEventListener(MouseEvent.CLICK, checkOptions);
			oBox.addChild(this.bgBox);
			
			this.radarBox.label = "Radar";
			this.radarBox.addEventListener(MouseEvent.CLICK, checkOptions);
			oBox.addChild(this.radarBox);
			
			this.addChild(oBox);
		}
		
		///-- Event Listeners --///
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			this.title = this.sTitle;
			this.showCloseButton = true;
			this.drawWindow();
			
			// add listener for close button
			this.addEventListener(CloseEvent.CLOSE, closeWindow);
		}
		
		private function checkOptions(e:MouseEvent):void {
			switch (e.target.label) {
				case "Invulnerability":
					e.target.selected ? this.oGL.playerShip.dispatchEvent(new Event('InvulnerabilityOn')) : this.oGL.playerShip.dispatchEvent(new Event('InvulnerabilityOff'));
					break;
					
				case "Debug Window":
					e.target.selected ? this.dispatchEvent(new Event('DebugOn')) : this.dispatchEvent(new Event('DebugOff'));
					break;
					
				case "Sound":
					e.target.selected ? this.oGL.dispatchEvent(new Event('SoundOn')) : this.oGL.dispatchEvent(new Event('SoundOff'));
					break;
					
				case "Background Image":
					e.target.selected ? this.oGL.dispatchEvent(new Event('BackgroundOn')) : this.oGL.dispatchEvent(new Event('BackgroundOff'));
					break;
					
				case "Radar":
					e.target.selected ? this.dispatchEvent(new Event('RadarOn')) : this.dispatchEvent(new Event('RadarOff'));
					break;
			}
		}
		
		//
		///-- Destructor --///
		//
		
		private function closeWindow(e:CloseEvent):void {
			this.invulnBox.removeEventListener(MouseEvent.CLICK, checkOptions);
			this.soundBox.removeEventListener(MouseEvent.CLICK, checkOptions);
			this.debugBox.removeEventListener(MouseEvent.CLICK, checkOptions);
			this.bgBox.removeEventListener(MouseEvent.CLICK, checkOptions);
			this.radarBox.removeEventListener(MouseEvent.CLICK, checkOptions);
			this.removeEventListener(CloseEvent.CLOSE, closeWindow);
			this.parent.removeChild(this);
		}
	}
}


