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

/*
	This whole class only exists because you can't set a flex button's icon property from
	an external source. They have to be compiled images as named objects.
	
	An alternative is this: http://blog.benstucki.net/?p=42
*/


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
		public var actionText:String;	// String to display when moused-over
		
		// Display Properties
		private var imageDir:String = "UI";	// path where button icons are located relative to 'oGL.imageDir'
		private var buttonBackgroundURL:String = 'button.purple.png';	// this should probably be loaded from a config file
		private var backgroundLoader:imageLoader;
		private var selectedBackgroundURL:String = 'button.yellow.png';	// this one is to highlight the current target's 'curAction'
		private var selBgLoader:imageLoader;
		private var iconLoader:imageLoader;
		
		private var fillStyle:uint = 0x000000;
		private var curLineStyle:Array;	// holder for whichever linestyle is active
		private var grLineStyle1:Array = [1, 0x404040];	// default style
		private var grLineStyle2:Array = [1, 0xCC4400];	// style when moused-over
		private var buttonDims:Array = [24, 24]; // w, h
		
		//
		///-- Constructor --///
		//
		
		public function actionButtonUI(oGL:gameloader, action:String, iconURL:String):void {
			this.oGL = oGL;
			this.actionText = action;
			this.imageDir = this.oGL.imageDir + '/' + this.imageDir;
			
			// load images
			this.selBgLoader = new imageLoader(this.imageDir + '/' + this.selectedBackgroundURL);
			this.selBgLoader.x = this.selBgLoader.y = 1;	// add offset for button border
			this.backgroundLoader = new imageLoader(this.imageDir + '/' + this.buttonBackgroundURL);
			this.backgroundLoader.x = this.backgroundLoader.y = 1;	// add offset for button border
			this.iconLoader = new imageLoader(this.imageDir + '/' + iconURL);
			this.iconLoader.x = this.iconLoader.y = 1;	// add offset for button border
			
			this.rawChildren.addChild(this.backgroundLoader);
			this.rawChildren.addChild(this.iconLoader);
			
			// draw fake button
			this.curLineStyle = this.grLineStyle1;
			this.updateGraphics();
			
			this.addEventListener('selected', onSelected);
			this.addEventListener('deSelected', onDeselected);
			this.addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
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
		
		private function onMouseOver(e:MouseEvent):void {
			this.curLineStyle = this.grLineStyle2;
			this.updateGraphics();
		}
		
		private function onMouseOut(e:MouseEvent):void {
			this.curLineStyle = this.grLineStyle1;
			this.updateGraphics();
		}
		
		private function onSelected(e:Event):void {
			if (this.rawChildren.contains(this.backgroundLoader)) {
				this.rawChildren.removeChild(this.backgroundLoader);
			}
			
			if (!this.rawChildren.contains(this.selBgLoader)) {
				this.rawChildren.addChild(this.selBgLoader);
			}
		}
		
		private function onDeselected(e:Event):void {
			if (this.rawChildren.contains(this.selBgLoader)) {
				this.rawChildren.removeChild(this.selBgLoader);
			}
			
			if (!this.rawChildren.contains(this.backgroundLoader)) {
				this.rawChildren.addChild(this.backgroundLoader);
			}
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.removeEventListener('selected', onSelected);
			this.removeEventListener('deSelected', onDeselected);
			this.removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}
	}
}
