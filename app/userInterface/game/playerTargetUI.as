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
	import mx.controls.Text;
	import mx.containers.VBox;
	
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.baseClasses.asteroid;
	import app.baseClasses.realMover;
	import app.userInterface.game.actionButtonUI;
	
	
	public class playerTargetUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var actionArray:Array = [{name:"go postal",imageURL:"attack.png"},{name:"defend",imageURL:"defend.png"},{name:"follow",imageURL:"follow.png"},{name:"harvest asteroids",imageURL:"harvest.png"},{name:"patrol",imageURL:"patrol.png"}];
		private var buttonArray:Array = new Array(); // holds the created buttons to save from redrawing them every time the targets change
		
		// Display Properties
		private var varText:Text = new Text();
		private var buttonWidth:int = 24;	// used to calculate button spacing
		private var actionBar:Canvas;	// display container for the action buttons
		
		//
		///-- Constructor --///
		//
		
		public function playerTargetUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.oGL.addEventListener('gameLoaded', gameLoadedHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		
		//
		///-- Private Methods --///
		//
		
		private function createButtons():void {
			for each (var action:Object in this.actionArray) {
				var oActionButton:actionButtonUI = new actionButtonUI(this.oGL, action.name, action.imageURL);
				oActionButton.addEventListener(MouseEvent.CLICK, onActionButtonClick)
				this.buttonArray.push(oActionButton);
			}
		}
		
		private function checkHighlighting():void {
			var actionsToHighlight:Array = new Array();
			var isUnique:Boolean;
		
			for each (var ship:realMover in this.oGL.playerTargetArray) {
				isUnique = true;
				
				for each (var sAction:String in actionsToHighlight) {
					if (ship.AI.curAction == sAction) {
						isUnique = false;
					}
				}
				
				if (isUnique) {
					actionsToHighlight.push(ship.AI.curAction);
				}
			}
			
			for each (var oButton:actionButtonUI in this.buttonArray) {
				oButton.dispatchEvent(new Event('deSelected'));
				
				for each (var sAction2:String in actionsToHighlight) {
					if (oButton.actionText == sAction2) {
						oButton.dispatchEvent(new Event('selected'));
					}
				}
			}
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addChild(this.varText);
			this.varText.selectable = false;
			this.createButtons();
		}
		
		private function gameLoadedHandler(e:Event):void {
			this.oGL.removeEventListener('gameLoaded', gameLoadedHandler);
			this.oGL.addEventListener('updatePlayerTargetArray', updateTargets);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onActionButtonClick(e:MouseEvent):void {
			// dispatch the action event to all the ships in the current group
			for each (var ship:realMover in this.oGL.playerTargetArray) {
				ship.dispatchEvent(new dataEvent(e.target.parent.actionText, 'doAction'));
			}
			
			// reset the highlighting on the buttons to the new action
			for each (var oButton:actionButtonUI in this.buttonArray) {
				oButton.dispatchEvent(new Event('deSelected'));
				
				if (oButton.actionText == e.target.parent.actionText) {
					oButton.dispatchEvent(new Event('selected'));
				}
			}
		}
		
		private function updateTargets(e:dataEvent):void {
			var availableActions:Array = new Array();
			
			// update the target text info
			this.varText.text = "*Target Info*";
			
			for each (var ship:realMover in e.dataObj) {
				this.varText.text += "\n" + ship.name;
				
				// get the available actions from each ship
				for each (var action:String in ship.defaultActions) {
					// sort unique actions
					var isUnique:Boolean = true;
					
					for each (var sorted:String in availableActions) {
						if (sorted == action) {
							isUnique = false;
						}
					}
					
					if (isUnique) {
						availableActions.push(action);
					}
				}
			}
			
			// draw the actionBar
			availableActions.sort(Array.CASEINSENSITIVE);
			this.actionBar = new Canvas();
			this.actionBar.focusEnabled = false;	// prevents the gamescreen losing keyboard focus
			
			for (var i:uint = 0, len:uint = availableActions.length; i < len; i++) {
				for each (var oActionButton:actionButtonUI in this.buttonArray) {
					if (availableActions[i] == oActionButton.actionText) {
						oActionButton.x = this.buttonWidth * i;
						this.actionBar.addChild(oActionButton);
					}
				}
			}
			
			// update the button's highlighting
			this.checkHighlighting();
			
			// need to wait until the Text control finishes rendering before setting the actionBar's y value
			this.varText.addEventListener(FlexEvent.UPDATE_COMPLETE, offsetActionBar);
			
			if (!this.contains(this.actionBar)) {
				this.addChild(this.actionBar);
			}
		}
		
		private function offsetActionBar(e:FlexEvent):void {
			this.varText.removeEventListener(FlexEvent.UPDATE_COMPLETE, offsetActionBar);
			this.actionBar.y = this.varText.height;
		}
		
		private function onEnterFrame(e:Event):void {
			//this.varText.text = "*Target Info*";
			
			
			
			/*if (this.oGL.playerShip.oTarget != null) {
				this.varText.text += "\nName: " + this.oGL.playerShip.oTarget.name;
				
				if (this.oGL.playerShip.oTarget is asteroid) {
					this.varText.text += "\nMinerals: " + this.oGL.playerShip.oTarget.minerals;
				} else {
					this.varText.text += "\nShield: " + this.oGL.playerShip.oTarget.shield;
					this.varText.text += "\nHull: " + this.oGL.playerShip.oTarget.hull;
				}
				
				this.varText.text += "\nDistance: " + Math.round(this.oGL.playerShip.targetDistance);
				this.varText.text += "\nFaction: " + this.oGL.playerShip.oTarget.faction;
				
				// only loop through these if target has changed
				if (this.iObjIndex != this.oGL.playerShip.oTarget.indx) {
					this.iObjIndex = this.oGL.playerShip.oTarget.indx;
					
					// display the action array for this object (if applicable)
					this.checkActionArray();
				}
			}*/
		}
		
		
		//
		///-- Destructor --///
		//
		
		public function destroy(e:Event):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			this.oGL.removeEventListener('updatePlayerTargetArray', updateTargets);
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			for each (var button:actionButtonUI in this.buttonArray) { button.destroy(); }
		}
	}
}
