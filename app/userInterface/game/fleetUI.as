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
	import mx.containers.Canvas
	import mx.controls.Text;
	import mx.controls.Label;

	import app.loaders.gameloader;
	import app.loaders.imageLoader;
	import app.baseClasses.realMover;

	public class fleetUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var infoText:Text = new Text();
		private var fleetArray:Array = new Array();	// 1 dimensional array containing all ships of player's faction
		private var fleetArrayGrouped:Array = new Array();	// 2 dimensional array for display of 'grouped' ships
		private var displayType:String = 'grouped';
		private var imageDir:String = 'UI';	// directory relative to oGL.imageDir
		private var iconArray:Array = new Array();	// useful for removing event listeners
		
		// Display Properties
		private var containerDims:Array = [150, 300];	// x,y
		private var grLineStyle1:Array = [1, 0x666666];
		private var iconHeight:uint = 24 + 4;	// height of the little icon pictures plus spacing
		
		//
		///-- Constructor --///
		//
		
		public function fleetUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.oGL.addEventListener('gameLoaded', gameLoadedHandler);
			this.imageDir = this.oGL.imageDir + '/' + this.imageDir;
			this.infoText.selectable = false;
			
			this.graphics.lineStyle(this.grLineStyle1[0], this.grLineStyle1[1]);
			this.graphics.drawRect(0, 0, this.containerDims[0], this.containerDims[1]);
			this.cacheAsBitmap = true;
		}
		
		//
		///-- Private Methods --///
		//
		
		private function sortByGroup():void {	// group same named ships
			var isGrouped:Boolean;	// if still false after looping through the grouped array, add a new group
			
			for (var i:uint = 0, len:uint = this.fleetArray.length; i < len; i++) {
				isGrouped = false;
				
				for (var j:uint = 0, len2:uint = this.fleetArrayGrouped.length; j < len2; j++) {
					if (this.fleetArray[i].name == this.fleetArrayGrouped[j][0].name) {	// if group already exists, add this object to that group
						isGrouped = true;
						this.fleetArrayGrouped[j].push(this.fleetArray[i]);
					}
				}
				
				if (isGrouped == false) {	// add a new group
					this.fleetArrayGrouped.push(new Array(this.fleetArray[i]));
				}
			}
			
			// now loop through the groups and add the icons and count numbers
			for (var k:uint = 0, len3:uint = this.fleetArrayGrouped.length; k < len3; k++) {
				var shipIcon:imageLoader = new imageLoader(this.imageDir + '/' + this.fleetArrayGrouped[k][0].xSpec.UIiconURL);
				shipIcon.oData = this.fleetArrayGrouped[k];	// identifier for the mouse events
				shipIcon.y = k * this.iconHeight + 22;	// add a bit of an offset
				shipIcon.x = 5;	// add another little offset
				this.rawChildren.addChild(shipIcon);
				
				// add a counter label for each group
				var counter:Label = new Label();
				counter.text = 'x' + this.fleetArrayGrouped[k].length;
				counter.x = 50; // ?
				counter.y = shipIcon.y;
				this.addChild(counter);
				
				// add event listeners to each icon for displaying info on mouseover, and selecting on mouseclick
				this.iconArray.push(shipIcon);
				shipIcon.addEventListener(MouseEvent.MOUSE_OVER, iconMouseOver);
				shipIcon.addEventListener(MouseEvent.CLICK, iconClick);
			}
		}
		
		private function sortByDetails():void {	// display individual ships
		
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			
			this.addChild(this.infoText);
			
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.oGL.heartBeatTimer.addEventListener(TimerEvent.TIMER, heartBeat);
			this.addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		
		private function gameLoadedHandler(e:Event):void {
			// collect initial fleet object (same faction as player)
			for each (var obj:* in this.oGL.objectArray) {
				if (obj.faction == this.oGL.oMapData.xmlData.playerStart.faction
					&& obj is realMover)	// can only give commands to realmovers
				{
					this.fleetArray.push(obj);
				}
			}
			
			// sort array into the default display type
			if (this.displayType == 'grouped') {
				this.sortByGroup();
			} else {
				this.sortByDetails();
			}
		}
		
		private function iconMouseOver(e:MouseEvent):void {
			// 'e.target.oData[0]' is a reference to the actual 'realMover' object
			trace(e.target.oData[0].shield);
		}
		
		private function iconClick(e:MouseEvent):void {
		
		}
		
		//
		///-- Main Loops --///
		//
		
		private function heartBeat(e:TimerEvent):void {
			this.infoText.text = "*Fleet Info*";
			
			/*for each (var obj:* in this.fleetArray) {
				this.infoText.text += "\n" + obj.name;
			}*/
		}
		
		private function onEnterFrame(e:Event):void {
			
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy(e:Event):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			this.oGL.heartBeatTimer.removeEventListener(TimerEvent.TIMER, heartBeat);
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			// remove mouse event listeners from each ship icon
			for each (var icon:imageLoader in this.iconArray) {
				icon.removeEventListener(MouseEvent.MOUSE_OVER, iconMouseOver);
				icon.removeEventListener(MouseEvent.CLICK, iconClick);
			}
		}
	}
}
