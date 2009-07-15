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
	
	import mx.containers.Canvas;
	import mx.containers.TitleWindow;
	import mx.controls.Button;
	import mx.controls.ButtonBar;
	import mx.controls.Alert;
	import mx.events.*;
	
	import app.loaders.gameloader;
	import app.userInterface.game.gameOptionsUI;
	import app.userInterface.game.debugUI;
	import app.userInterface.game.playerShipUI;
	import app.userInterface.game.playerTargetUI;
	import app.userInterface.game.radarUI;
	import app.userInterface.game.dragBoxUI;
	import app.userInterface.game.fleetUI;

	public class gameUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		public var isDebug:Boolean = false;
		public var isRadar:Boolean = true;
		
		// Display Properties
		private var bottomMenu:ButtonBar = new ButtonBar();
		private var bottomMenuItems:Array = ['Exit Game', 'Options'];
		private var bottomMenuPos:Array = [0,565];	// x,y
		
		private var oDebug:debugUI;
		private var debugPos:Array = [0,0];			// x,y
		
		private var oPlayerUI:playerShipUI;
		private var playerUIPos:Array = [200,550];		// x,y
		
		private var oPlayerTargetUI:playerTargetUI;
		private var playerTargetUIPos:Array = [600,0];	// x,y
		
		private var oGameOptions:gameOptionsUI;
		private var gameOptionsDims:Array = [200,150,400,300];	// x,y,w,h
		
		private var oRadar:radarUI;
		private var radarUIDims:Array = [599,399];	// x,y
		
		private var oFleetUI:fleetUI;
		private var fleetUICoords:Array = [0, 200];	// x,y
		
		private var dragBox:dragBoxUI;
		
		
		//
		///-- Constructor --///
		//
		
		public function gameUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
		}
		
		//
		///-- Private Methods --///
		//
		
		private function showOptionWindow():void {
			// avoid adding multiple windows
			if (this.oGameOptions == null) {
				this.oGameOptions = new gameOptionsUI(this.oGL, this);
				
				this.oGameOptions.x = this.gameOptionsDims[0];
				this.oGameOptions.y = this.gameOptionsDims[1];
				this.oGameOptions.width = this.gameOptionsDims[2];
				this.oGameOptions.height = this.gameOptionsDims[3];
				
				this.oGameOptions.addEventListener(CloseEvent.CLOSE, closeOptionWindow);
				this.oGameOptions.addEventListener('DebugOn', toggleDebug);
				this.oGameOptions.addEventListener('DebugOff', toggleDebug);
				this.oGameOptions.addEventListener('RadarOn', toggleRadar);
				this.oGameOptions.addEventListener('RadarOff', toggleRadar);
				
				this.addChild(this.oGameOptions);
			}
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			// draw bottom menu
			this.bottomMenu.dataProvider = this.bottomMenuItems;
			this.bottomMenu.focusEnabled = false;		// prevent oGL from losing keyboard focus
			this.bottomMenu.x = this.bottomMenuPos[0];
			this.bottomMenu.y = this.bottomMenuPos[1];
			this.bottomMenu.addEventListener(ItemClickEvent.ITEM_CLICK, bottomMenuHandler);
			this.addChild(this.bottomMenu);
			
			// draw playership display
			this.oPlayerUI = new playerShipUI(this.oGL);
			this.oPlayerUI.x = this.playerUIPos[0];
			this.oPlayerUI.y = this.playerUIPos[1];
			this.addChild(this.oPlayerUI);
			
			// draw playerTarget display
			this.oPlayerTargetUI = new playerTargetUI(this.oGL);
			this.oPlayerTargetUI.x = this.playerTargetUIPos[0];
			this.oPlayerTargetUI.y = this.playerTargetUIPos[1];
			this.addChild(this.oPlayerTargetUI);
			
			// draw radar
			this.toggleRadar(new Event('RadarOn'));
			
			// fleetUI box
			this.oFleetUI = new fleetUI(this.oGL);
			this.oFleetUI.x = this.fleetUICoords[0];
			this.oFleetUI.y = this.fleetUICoords[1];
			this.addChild(this.oFleetUI);
			
			// drag and select Box for mouse selecting multiple targets
			this.dragBox = new dragBoxUI(this.oGL);
			this.stage.addChild(this.dragBox);
		}
		
		private function bottomMenuHandler(e:ItemClickEvent):void {
			switch (e.item) {
				case 'Exit Game':
					Alert.show('Exit Game?', 'Exit Confirmation', Alert.YES | Alert.NO, this, exitDialogHandler);
					break;
					
				case 'Options':
					this.showOptionWindow();
					break;
			}
		}
		
		private function exitDialogHandler(e:CloseEvent):void {
			if (e.detail == Alert.YES) {	// exit game
				this.destroy();
				this.oGL.closeGame();
			} else {	// return to game
				//--
			}
		}
		
		private function toggleRadar(e:Event):void {
			if (e.type == "RadarOn") {
				this.isRadar = true;
				this.oRadar = new radarUI(this.oGL);
				this.oRadar.x = this.radarUIDims[0];
				this.oRadar.y = this.radarUIDims[1];
				this.addChild(this.oRadar);
			} else {
				this.isRadar = false;
				this.oRadar.destroy();
				this.oRadar = null;
			}
		}
		
		private function toggleDebug(e:Event):void {
			if (e.type == "DebugOn") {
				this.isDebug = true;
				this.oDebug = new debugUI(this.oGL);
				this.oDebug.focusEnabled = false;
				this.oDebug.x = this.debugPos[0];
				this.oDebug.y = this.debugPos[1];
				this.addChild(this.oDebug);
			} else {
				this.isDebug = false;
				this.oDebug.destroy();
				this.oDebug = null;
			}
		}
		
		private function closeOptionWindow(e:CloseEvent):void {
			e.target.removeEventListener('DebugOn', toggleDebug);
			e.target.removeEventListener('DebugOff', toggleDebug);
			e.target.removeEventListener('RadarOn', toggleRadar);
			e.target.removeEventListener('RadarOff', toggleRadar);
			this.oGameOptions = null;
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.bottomMenu.removeEventListener(ItemClickEvent.ITEM_CLICK, bottomMenuHandler);
			if (this.isDebug) {this.oDebug.destroy()};
			this.oPlayerUI.destroy();
			this.removeChild(this.oPlayerTargetUI);
			this.dragBox.destroy();
		}
	}
}
