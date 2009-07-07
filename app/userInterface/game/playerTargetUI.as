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
	import app.baseClasses.asteroid;
	import app.userInterface.game.actionButtonUI;
	
	
	public class playerTargetUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var iObjIndex:int;		// target's index in oGL.objectArray, used to avoid looping in onEnterFrame
		private var actionArray:Array = [{name:"go postal",imageURL:"attack.png"},{name:"defend",imageURL:"defend.png"},{name:"follow",imageURL:"follow.png"},{name:"harvest asteroids",imageURL:"harvest.png"},{name:"patrol",imageURL:"patrol.png"}];
				
		// Display Properties
		private var varText:Text = new Text();
		private var buttonWidth:int = 24;	// used to calculate button spacing
		private var actionBar:Canvas = new Canvas();	// display container for the action buttons
		
		//
		///-- Constructor --///
		//
		
		public function playerTargetUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.oGL.addEventListener('gameLoaded', gameLoadedHandler);
			
			this.actionBar.focusEnabled = false;	// prevents the gamescreen losing keyboard focus
			//this.actionBar.addEventListener(ListEvent.CHANGE, actionBarListener);
			
			//hack
			this.actionBar.graphics.lineStyle(1,0x404040);
			this.actionBar.graphics.beginFill(0x343434);
			this.actionBar.graphics.drawRect(0,0,150,26);
			this.actionBar.graphics.endFill();
			this.actionBar.cacheAsBitmap = true;
		}
		
		//
		///-- Private Methods --///
		//
		
		private function checkActionArray():void {
			
			// if target is same faction as player, show the action menu
			if (this.oGL.playerShip.oTarget.faction == this.oGL.playerShip.faction) {
			
				// only 'realMover' objects contain an AI
				if (this.oGL.playerShip.oTarget.hasOwnProperty('AI')) {
					// reset the actionBar
					if (this.contains(this.actionBar)) {
						this.removeChild(this.actionBar);
					}
					
					this.actionBar = null;
					this.actionBar = new Canvas();
					
					
					// set up the buttons/images that relate to the current target's actionArray
					for each (var action:String in this.oGL.playerShip.oTarget.actionArr) {
						for each (var image:Object in this.actionArray) {
							if (action == image.name) {
								var oActionButton:actionButtonUI = new actionButtonUI(this.oGL, action, image.imageURL);
								this.actionBar.addChild(oActionButton);
								oActionButton.y = 1;
								oActionButton.x = this.actionBar.getChildIndex(oActionButton) * this.buttonWidth + (1 * this.actionBar.getChildIndex(oActionButton));
							}
						}
					}
					
					// position the action bar beneath the target text info
					this.varText.validateNow();	// needed to get the correct height
					this.actionBar.y = this.varText.textHeight;
					
					
					this.addChild(this.actionBar);
					
					
				} else if (this.contains(this.actionBar)) {
					this.removeChild(this.actionBar);
				}
			} else {
				if (this.contains(this.actionBar)) {
					this.removeChild(this.actionBar);
				}
			}
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addChild(this.varText);
		}
		
		private function gameLoadedHandler(e:Event):void {
			this.oGL.removeEventListener('gameLoaded', gameLoadedHandler);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function actionBarListener(e:ListEvent):void {
			// dispatch the event for the selected action
			this.oGL.playerShip.oTarget.AI.doAction(e.target.text);
		}
		
		private function onEnterFrame(e:Event):void {
			this.varText.text = "*Target Info*";
			
			if (this.oGL.playerShip.oTarget != null) {
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
			}
		}
		
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.actionBar.removeEventListener(ListEvent.CHANGE, actionBarListener);
		}
	}
}
