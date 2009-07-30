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
	import flash.geom.Point;

	import mx.containers.Canvas;
	import mx.events.*;
	import mx.controls.ProgressBar;
	import mx.controls.Text;
	import mx.containers.VBox;
	
	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.baseClasses.asteroid;
	import app.baseClasses.realMover;
	import app.baseClasses.starBase;
	import app.userInterface.game.actionButtonUI;
	
	
	public class playerTargetUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var actionArray:Array = [{name:"go postal",imageURL:"attack.png"},
										{name:"defend",imageURL:"defend.png"},
										{name:"follow",imageURL:"follow.png"},
										{name:"harvest asteroids",imageURL:"harvest.png"},
										{name:"patrol",imageURL:"patrol.png"},
										{name:"Dock",imageURL:"patrol.png"}];	// should eventually load this from an external file
		private var buttonArray:Array = new Array(); // holds the created buttons to save from redrawing them every time the targets change
		
		// Display Properties
		private var actionBar:Canvas = new Canvas();	// display container for the action buttons
		private var varText:Text = new Text();
		private var oToolTip:Text = new Text();	
		
		private var buttonWidth:int = 24;	// used to calculate button spacing
		private var ttLineStyle:Array = [1, 0xFFFFFF];	// tooltip styles
		private var ttFillStyle:Array = [0xCCCCCC, 0.3];
		
		
		//
		///-- Constructor --///
		//
		
		public function playerTargetUI(oGL:gameloader):void {
			this.oGL = oGL;
			
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL.addEventListener('gameLoaded', gameLoadedHandler);
			this.addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		
		//
		///-- Private Methods --///
		//
		
		private function createButtons():void {
			for each (var action:Object in this.actionArray) {
				var oActionButton:actionButtonUI = new actionButtonUI(this.oGL, action.name, action.imageURL);
				oActionButton.addEventListener(MouseEvent.CLICK, onActionButtonClick);
				oActionButton.addEventListener(MouseEvent.MOUSE_OVER, actionButtonMouseOver);
				oActionButton.addEventListener(MouseEvent.MOUSE_OUT, actionButtonMouseOut);
				this.buttonArray.push(oActionButton);
			}
		}
		
		private function checkHighlighting():void {
			var actionsToHighlight:Array = new Array();
			var isUnique:Boolean;
		
			for each (var obj:Object in this.oGL.playerTargetArray) {
				isUnique = true;
				
				for each (var sAction:String in actionsToHighlight) {
					if (obj is realMover) {
						if (obj.AI.curAction == sAction) {
							isUnique = false;
						}
					} else if (obj is starBase) {
						
					}
				}
				
				if (isUnique) {
					if (obj is realMover) {
						actionsToHighlight.push(obj.AI.curAction);
					}
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
		}
		
		private function onActionButtonClick(e:MouseEvent):void {
			// dispatch the action event to all the ships in the current group
			for each (var obj:Object in this.oGL.playerTargetArray) {
				if (obj is starBase) {	// dispatch the event on the player's ship
					this.oGL.playerShip.dispatchEvent(new dataEvent(e.currentTarget.actionText, 'doAction'));
				} else {	// dispatch the event on the object
					obj.dispatchEvent(new dataEvent(e.currentTarget.actionText, 'doAction'));
				}
			}
			
			// reset the highlighting on the buttons to the new action
			for each (var oButton:actionButtonUI in this.buttonArray) {
				oButton.dispatchEvent(new Event('deSelected'));
				
				if (oButton.actionText == e.currentTarget.actionText) {
					oButton.dispatchEvent(new Event('selected'));
				}
			}
		}
		
		private function updateTargets(e:dataEvent):void {
			var availableActions:Array = new Array();
			var isSameFaction:Boolean = true;
			
			// update the target text info
			this.varText.text = "*Target Info*";
			
			for each (var obj:Object in e.dataObj) {
				// check faction
				if (obj.faction != this.oGL.playerFaction) { isSameFaction = false; }
			
				this.varText.text += "\n" + obj.name;
				
				if (obj is realMover || obj is starBase) {	// other objects don't have actions
					// get the available actions from each obj
					for each (var action:String in obj.defaultActions) {
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
			}
			
			if (isSameFaction) {	// draw the actionBar
				availableActions.sort(Array.CASEINSENSITIVE);
				if (this.contains(this.actionBar)) { this.removeChild(this.actionBar); }
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
				
				if (!this.contains(this.actionBar)) { this.addChild(this.actionBar); }
			} else { // remove the action bar if present
				if (this.contains(this.actionBar)) { this.removeChild(this.actionBar); }
			}
		}
		
		private function offsetActionBar(e:FlexEvent):void {
			this.varText.removeEventListener(FlexEvent.UPDATE_COMPLETE, offsetActionBar);
			this.actionBar.y = this.varText.height;
		}
		
		private function actionButtonMouseOver(e:MouseEvent):void {
			this.oToolTip.addEventListener(FlexEvent.UPDATE_COMPLETE, resizeToolTip);
			this.oToolTip.text = e.currentTarget.actionText;
			
			// position the tooltip below the cursor
			var gloPoint:Point = new Point();
			gloPoint.x = e.stageX;
			gloPoint.y = e.stageY;
			var loPoint:Point = this.globalToLocal(gloPoint);
			
			this.oToolTip.y = loPoint.y + 20;
			this.oToolTip.x = loPoint.x;
			this.addChild(this.oToolTip);
		}
		
		private function resizeToolTip(e:FlexEvent):void {
			this.oToolTip.removeEventListener(FlexEvent.UPDATE_COMPLETE, resizeToolTip);
			
			this.oToolTip.graphics.clear();
			this.oToolTip.selectable = false;
			this.oToolTip.graphics.lineStyle(this.ttLineStyle[0], this.ttLineStyle[1]);
			this.oToolTip.graphics.beginFill(this.ttFillStyle[0], this.ttFillStyle[1]);
			this.oToolTip.graphics.drawRect(0,0,e.currentTarget.width,e.currentTarget.height);
			this.oToolTip.graphics.endFill();
			this.oToolTip.cacheAsBitmap = true;
		}
		
		private function actionButtonMouseOut(e:MouseEvent):void {
			this.removeChild(this.oToolTip);
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy(e:Event):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			this.oGL.removeEventListener('updatePlayerTargetArray', updateTargets);
			
			for each (var button:actionButtonUI in this.buttonArray) { 
				button.removeEventListener(MouseEvent.MOUSE_OVER, actionButtonMouseOver);
				button.removeEventListener(MouseEvent.MOUSE_OUT, actionButtonMouseOut);
				button.destroy();
			}
		}
	}
}
