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
	
	import app.loaders.gameloader;
	import app.loaders.imageLoader;
	import app.loaders.dataEvent;
	
	
	public class actionButtonUI extends Canvas {
		
		// Data Properties
		private var oGL:gameloader;
		private var imageDir:String = "UI";	// path where button icons are located relative to 'oGL.imageDir'
		private var buttonBackgroundURL:String = 'button.purple.png';	// this should probably be loaded from a config file
		private var backgroundLoader:imageLoader;
		private var iconLoader:imageLoader;
				
		// Display Properties
		private var fillStyle:uint = 0x000000;
		private var curLineStyle:Array;	// holder for whichever linestyle is active
		private var grLineStyle1:Array = [1, 0x404040];	// default style
		private var grLineStyle2:Array = [1, 0xCC4400];	// style when moused-over
		private var buttonDims:Array = [24, 24]; // w, h
		private var actionText:String;	// String to display when moused-over
		
		//
		///-- Constructor --///
		//
		
		public function actionButtonUI(oGL:gameloader, action:String, imageURL:String):void {
			// load images
			this.oGL = oGL;
			this.imageDir = this.oGL.imageDir + '/' + this.imageDir;
			this.backgroundLoader = new imageLoader(this.imageDir + '/' + this.buttonBackgroundURL);
			this.iconLoader = new imageLoader(this.imageDir + '/' + imageURL);
			this.backgroundLoader.x = this.backgroundLoader.y = 1;	// add offset for button border
			this.iconLoader.x = this.iconLoader.y = 1;	// add offset for button border
			this.rawChildren.addChild(this.backgroundLoader);
			this.rawChildren.addChild(this.iconLoader);
			
			this.actionText = action;
			
			// draw fake button
			this.curLineStyle = this.grLineStyle1;
			this.updateGraphics();
			
			this.addEventListener(MouseEvent.CLICK, onClick);
			this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.REMOVED_FROM_STAGE, destroy);
		}
		
		//
		///-- Private Methods --///
		//
		
		private function updateGraphics():void {
			this.graphics.clear();
			this.graphics.lineStyle(this.curLineStyle[0], this.curLineStyle[1]);
			this.graphics.beginFill(this.fillStyle);
			this.graphics.drawRect(0, 0, this.buttonDims[0], this.buttonDims[1]);
			this.graphics.endFill();
			this.cacheAsBitmap = true;
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		private function onMouseOver(e:MouseEvent):void {
			this.curLineStyle = this.grLineStyle2;
			this.updateGraphics();
		}
		
		private function onMouseOut(e:MouseEvent):void {
			this.curLineStyle = this.grLineStyle1;
			this.updateGraphics();
		}
		
		private function onClick(e:MouseEvent):void {
			this.oGL.playerShip.oTarget.dispatchEvent(new dataEvent(this.actionText, 'doAction'));
		}
		
		//
		///-- Destructor --///
		//
		
		private function destroy(e:Event):void {
			this.removeEventListener(Event.REMOVED_FROM_STAGE, destroy);
			this.removeEventListener(MouseEvent.CLICK, onClick);
			this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
	}
}
