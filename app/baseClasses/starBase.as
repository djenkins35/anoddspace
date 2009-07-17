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


package app.baseClasses {
	import flash.events.*;
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	
	import app.loaders.gameloader;
	
	public class starBase extends targeter {
		public var isTargetDocked:Boolean = false;
		public var baseName:String; 
		
		public var defaultActions:Array = ["Dock"];
		
		public function starBase(xSpec:XML, oGL:gameloader):void {
			this.oGL = oGL;
			this.imageDir = this.oGL.imageDir;
			this.imageURL = xSpec.imageURL;
			var sbPos:Array = xSpec.position.split(',');
			this.x = sbPos[0];
			this.y = sbPos[1];
			this.offsetSprite.doubleClickEnabled = true;
			this.actionArr = new Array("Dock");
			this.baseName = xSpec.name;
			this.name = xSpec.name;
			this.faction = xSpec.faction;
			
			this.hull = xSpec.hull;
			this.shield = this.shieldFull = xSpec.shield;
			this.shieldRegen = xSpec.shieldRegen;
			this.isDockable = true; // hack
		}
		
		private function dock():void {
			this.isTargetDocked = true;
			this.actionArr = new Array("Undock", "Change Ships", "Trade", "Hack the Gibson");
			this.oGL.dockShip(this);
			this.removeEventListener(MouseEvent.CLICK, clickHandler);
		}
		
		private function undock():void {
			this.isTargetDocked = false;
			this.actionArr = new Array("Dock");
			this.oGL.usrInpt.toggleUserInput();
			this.addEventListener(MouseEvent.CLICK, clickHandler);
		}
		
		/*public override function doAction(s:String):void {
			switch (s) {
				case "Dock" :
					this.dock();
					//this.oGL.ui.openStarBaseUI(this);
					break;
					
				case "Undock" :
					this.undock();
					break;
					
				case "Change Ships" :
					//this.oGL.ui.listShips(this.baseName);
					break;
			
				case "Hack the Gibson" :
					
					break;
			}
		}*/
		
		///-- --///
		
		public function heartBeat():void {
		
		}
	}
}
