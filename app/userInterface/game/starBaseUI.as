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
	import mx.containers.TitleWindow;
	import mx.containers.TabNavigator;
	import mx.containers.VBox;
	
	import app.baseClasses.realMover;
	import app.loaders.gameloader;
	import app.baseClasses.starBase;
	
	public class starBaseUI extends TitleWindow {
		
		// Data Properties
		private var oGL:gameloader;
		private var oStarBase:starBase;
		private var navContainer:TabNavigator = new TabNavigator();
		private var navTabs:Array = ['Trade', 'Ships', 'People'];
		
		// Display Properties
		private var sTitle:String;
		
		
		//
		///-- Constructor --///
		//
		
		public function starBaseUI(oGL:gameloader, oStarBase:starBase):void {
			this.oGL = oGL;
			this.oStarBase = oStarBase;
			this.sTitle = this.oStarBase.name;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		//
		///-- Private Methods --///
		//
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			this.title = this.sTitle;
			this.showCloseButton = true;
			
			// add the navigation container
			this.navContainer.width = 0.92 * this.width;
			this.navContainer.height = 0.8 * this.height;
			
			for each (var tab:String in this.navTabs) {
				var oTab:VBox = new VBox();
				oTab.label = tab;
				this.navContainer.addChild(oTab);
			}
			
			this.addChild(this.navContainer);
			
			/* fetch data for starBase, player, and ship */
			
			
			/*public var activeShip:XML;
			public var activeShipSpec:XML;
			public var xPlayerData:XML;
			public var xMapData:XML;
			public var xShipData:XML;
			public var xEquipmentData:XML;
			*/
			
			
			// add listener for close button
			this.addEventListener(CloseEvent.CLOSE, closeWindow);
		}
		
		
		//
		///-- Destructor --///
		//
		
		private function closeWindow(e:CloseEvent):void {
			this.removeEventListener(CloseEvent.CLOSE, closeWindow);
			
			// dispatch an event to the gameloader to turn keyboard control back on
			this.oGL.dispatchEvent(new Event('undockPlayerShip'));
			this.parent.removeChild(this);
		}
	}
}