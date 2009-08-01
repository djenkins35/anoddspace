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
	import flash.display.Shape;
	import flash.geom.Point;

	import app.loaders.gameloader;
	import app.loaders.dataEvent;
	import app.baseClasses.realMover;

	public class dragBoxUI extends Shape {

		// Data Properties
		private var oGL:gameloader;
		private var isBox:Boolean = false;			// whether or not to execute ENTER_FRAME code
		private var tempArray:Array = new Array();	// collects the objects inside the select box
		
		// Display Properties
		private var loStartPoint:Point = new Point();
		private var loEndPoint:Point = new Point();
		private var glStartPoint:Point = new Point();
		private var glEndPoint:Point = new Point();
		
		private var grLineStyle:Array = [1, 0xFFFFFF];
		private var grFillStyle:Array = [0xCCCCCC, 0.3];
		
		
		//
		///-- Constructor --///
		//
		
		public function dragBoxUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
		}
		
		//
		///-- Private Methods --///
		//
		
		private function getBoxDims(p1:Point, p2:Point):Array {
			var boxDims:Array = new Array();	// [w,h]
			
			if (p1.x <= 0 && p2.x <=0) {
				if (p1.x > p2.x) {
					boxDims[0] = p2.x - p1.x;
				} else {
					boxDims[0] = p1.x - p2.x;
				}
			} else {
				boxDims[0] = p2.x - p1.x;
			}
			
			if (p1.y <= 0 && p2.y <=0) {
				if (p1.y > p2.y) {
					boxDims[1] = p2.y - p1.y;
				} else {
					boxDims[1] = p1.y - p2.y;
				}
			} else {
				boxDims[1] = p2.y - p1.y;
			}
			
			return boxDims;
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.stage.addEventListener(MouseEvent.MOUSE_DOWN, startSelectBox);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function startSelectBox(e:MouseEvent):void {
			this.glStartPoint.x = e.stageX;
			this.glStartPoint.y = e.stageY;
			this.loStartPoint = this.oGL.gamescreen.globalToLocal(this.glStartPoint);
			
			this.stage.addEventListener(MouseEvent.MOUSE_MOVE, updateBox);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, cancelDrag);
		}
		
		private function updateBox(e:MouseEvent):void {
			this.isBox = true;
			this.glEndPoint.x = e.stageX;
			this.glEndPoint.y = e.stageY;
			this.loEndPoint = this.oGL.gamescreen.globalToLocal(this.glEndPoint);
			
			var boxDims:Array = this.getBoxDims(this.glStartPoint, this.glEndPoint);
			
			this.graphics.clear();
			this.graphics.lineStyle(this.grLineStyle[0], this.grLineStyle[1]);
			this.graphics.beginFill(this.grFillStyle[0], this.grFillStyle[1]);
			this.graphics.drawRect(this.glStartPoint.x, this.glStartPoint.y, boxDims[0], boxDims[1]);
			this.graphics.endFill();
			
			// replace the mouse up listener with the listener that updates the drag targets
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, cancelDrag);
			this.stage.addEventListener(MouseEvent.MOUSE_UP, stopSelect);
		}
		
		private function stopSelect(e:MouseEvent):void {
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateBox);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, stopSelect);
			
			this.graphics.clear();
			this.isBox = false;
			
			for each (var obj:Object in this.oGL.objectArray) {
				// remove temp indicators
				obj.dispatchEvent(new Event('toggleSelectOff'));
			}
			
			// send dataEvent to the gameloader with the selected group
			// this event also has a listener in playerTargetUI.as to update the action buttons, and target info
			this.oGL.dispatchEvent(new dataEvent(this.tempArray, 'updatePlayerTargetArray'));
		}
		
		private function cancelDrag(e:MouseEvent):void {
			this.stage.removeEventListener(MouseEvent.MOUSE_MOVE, updateBox);
			this.stage.removeEventListener(MouseEvent.MOUSE_UP, cancelDrag);
		}
		
		//
		///-- Main Loops --///
		//
		
		private function onEnterFrame(e:Event):void {
			if (this.isBox) {
				// update the startpoint local coords every frame to handle selecting while moving
				this.loStartPoint = this.oGL.gamescreen.globalToLocal(this.glStartPoint);
				
				var bInBox:Boolean;	// saves state through the loop of whether or not object is within the bounding box
				this.tempArray = null;
				this.tempArray = new Array();
					
				// determine which objects are within the drag box
				for each (var obj:Object in this.oGL.objectArray) {
					bInBox = false;
					obj.dispatchEvent(new Event('toggleSelectOff'));
					
					if (this.loStartPoint.x <= this.loEndPoint.x) {
						if (this.loStartPoint.y <= this.loEndPoint.y) {
							if (obj.x >= this.loStartPoint.x
								&& obj.x <= this.loEndPoint.x)
							{
								if (obj.y >= this.loStartPoint.y
									&& obj.y <= this.loEndPoint.y)
								{
									bInBox = true;
								}
							}
						} else {
							if (obj.x >= this.loStartPoint.x
								&& obj.x <= this.loEndPoint.x)
							{
								if (obj.y <= this.loStartPoint.y
									&& obj.y >= this.loEndPoint.y)
								{
									bInBox = true;
								}
							}
						}
					} else {
						if (this.loStartPoint.y <= this.loEndPoint.y) {
							if (obj.x <= this.loStartPoint.x
								&& obj.x >= this.loEndPoint.x)
							{
								if (obj.y >= this.loStartPoint.y
									&& obj.y <= this.loEndPoint.y)
								{
									bInBox = true;
								}
							}
						} else {
							if (obj.x <= this.loStartPoint.x
								&& obj.x >= this.loEndPoint.x)
							{
								if (obj.y <= this.loStartPoint.y
									&& obj.y >= this.loEndPoint.y)
								{
									bInBox = true;
								}
							}
						}
					}
					
					if (bInBox) {
						if (obj is realMover	// we only care about drag-selecting ships, other stuff is clickable
							&& obj.faction == this.oGL.playerFaction) {	// only need to drag-select our own ships
							this.tempArray.push(obj);
							obj.dispatchEvent(new Event('toggleSelectOn'));
						}
					}
				}
			}
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.stage.removeEventListener(MouseEvent.MOUSE_DOWN, startSelectBox);
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
	}
}
