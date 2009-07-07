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
	import flash.text.*;
	import flash.events.*;
	import flash.display.*
	import flash.utils.Timer;
	import flash.geom.*
	
	import app.baseClasses.realMover;
	import app.loaders.gameloader;
	import app.baseClasses.starBase;
	
	public class starBaseUI extends Sprite {
		private var txtColor:uint = 0xFFFFFF;
		private var lineStyle:Array = new Array(1,0xFFFFFF);
		private var fillStyle:Array = new Array(0xFF0000, 0.25);
		private var fillStyle2:Array = new Array(0x00FF00, 0.25);
		private var lineHeight:uint = 20;
		private var lineCounter:uint = 0;
		private var iWidth:int = 400;
		private var iHeight:int = 400;
		private var xOffset:int = 200;
		private var yOffset:int = 100;
		private var subWin:Sprite;
		private var subWindowXOffset:int = 100;
		private var subWindowYOffset:int = 10;
		private var subWindowWidth:int = 290;
		private var subWindowHeight:int = 380;
		private var shipInfoWinHeight:int = 200;
		
		private var oGL:gameloader;
		private var sb:starBase;
		private var shipArray:Array;
		private var shipInfo:Sprite;						// needs to be removed from the UI on mouse events
		private var selectedShipName:String;				// ship name that goes to the callback to switch
		private var makeActive:Sprite;						// button that calls to starBase.as
		private var buttonArr:Array = new Array();			// main window buttons
		
		public function starBaseUI(obj:starBase, oGL:gameloader):void {
			this.x = this.xOffset;
			this.y = this.yOffset;
			this.oGL = oGL;
			this.sb = obj;
			this.getShips();
			this.openUI();
		}
		
		///-- common functions --///
		
		private function getShips():void {					// only ships docked at this station
			this.shipArray = new Array();
		
			for each (var ship:XML in this.oGL.oPlayerData.xmlData.ships.ship) {
				if (ship.@active == "yes") {					// current ship
					this.shipArray.push(ship);
				}
			
				if (ship.location == this.sb.baseName) {		// ships docked at this base
					this.shipArray.push(ship);
				}
			}
		}
		
		private function isArray(obj:*):Boolean {
			try {
				typeof obj[0];
				return true;
			} catch (e:Error) {
				return false;
			}
			
			return false;
		}
		
		private function drawSubWindow():void {
			try {
				for (var i:int = 0, len:int = this.subWin.numChildren; i < len; i++) {
					this.subWin.removeChildAt(i);
				}
				this.subWin.graphics.clear();
				this.removeChild(this.subWin);
				this.subWin = null;
			} catch (e:Error) {
				//trace("subWindow not present");
			}
			
			this.subWin = new Sprite();
			subWin.x = this.subWindowXOffset;
			subWin.y = this.subWindowYOffset
			subWin.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			subWin.graphics.beginFill(this.fillStyle2[0], this.fillStyle2[1]);
			subWin.graphics.drawRect(0, 0, this.subWindowWidth, this.subWindowHeight);
			subWin.graphics.endFill();
			this.addChild(subWin);
		}
		
		private function drawButton(s:String, txtWidth:int = 100, xOffset:int = 0, yOffset:int = 0):Sprite {
			var line:Sprite = new Sprite();
			var txt:TextField = this.drawText(s, txtWidth);
			line.addChild(txt);
			line.x = xOffset;
			line.y = yOffset;
			return line;
		}
		
		private function drawText(s:String, txtWidth:int = 100, xOffset:int = 0, yOffset:int = 0):TextField {
			var txt:TextField = new TextField();
			txt.width = txtWidth;
			txt.textColor = this.txtColor;
			txt.text = s;
			txt.x = xOffset;
			txt.y = yOffset;
			return txt;
		}
		
		private function drawTable(a:Array, tblWidth:int, rowHeight:int):Sprite {		// a needs to be a 2-dimensional array :: [[col1, col2][row2]]
			var table:Sprite = new Sprite();
			var lineArray:Array = new Array();
			var columnLength:int = 0;
			
			// loop once to get the longest row
			for (var i:int = 0, len:int = a.length; i < len; i++) {
				if (a[i].length > columnLength) {
					columnLength = a[i].length;
				}
			}
			
			var columnWidth:int = Math.floor(tblWidth / columnLength);
			
			// now loop to draw the textFields
			for (var row:int = 0, rowLen:int = a.length; row < rowLen; row++) {
				for (var col:int = 0, colLen:int = a[row].length; col < colLen; col++) {
					var t:TextField = this.drawText(a[row][col], columnWidth, columnWidth * col);
					t.y = row * rowHeight;
					table.addChild(t);
				}
			}
			
			return table;
		}
		
		///-- main menu --///
		
		private function openUI():void {
			this.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.graphics.beginFill(this.fillStyle[0], this.fillStyle[1]);
			this.graphics.drawRect(0,0,this.iWidth,this.iHeight);
			this.graphics.endFill();
			
			for each (var action:String in this.sb.actionArr) {
				var line:Sprite = this.drawButton(action);
				line.addEventListener(MouseEvent.CLICK, UIClick);
				line.y = this.lineCounter * this.lineHeight;
				this.buttonArr.push(line);
				this.addChild(line);
				this.lineCounter++;
			}
		}
		
		private function UIClick(e:MouseEvent):void {
			switch (e.target.text) {
				case "Undock" :
					this.unDock();
					break;
					
				case "Change Ships" :
					this.showShipWindow();
					break;
					
				case "Trade" :
					this.trade();
					break;
			
				case "Hack the Gibson" :
					this.hackTheGibson();
					break;
			}
		}
		
		///
		///-- submenus --//
		///
		
		///-- change ships --///
		
		private function showShipWindow():void {
			this.drawSubWindow();
			this.subWin.graphics.moveTo(0, this.shipInfoWinHeight);
			this.subWin.graphics.lineTo(this.subWindowWidth, this.shipInfoWinHeight);
			var lineArray:Array = new Array();
			var heading:TextField = this.drawText("Ships docked at this station:", this.subWindowWidth);
			lineArray.push(heading);
			
			for (var i:int = 0, len:int = this.shipArray.length; i < len; i++) {
				var newLine:Sprite = this.drawButton(this.shipArray[i].shipType);
				newLine.addEventListener(MouseEvent.CLICK, showShipInfo);
				lineArray.push(newLine);
			}
			
			for (var i2:int = 0, len2:int = lineArray.length; i2 < len2; i2++) {
				lineArray[i2].y = this.lineHeight * i2;
				this.subWin.addChild(lineArray[i2]);
			}
		}
		
		private function showShipInfo(e:MouseEvent):void {
			var xSelectedShip:XML;
			
			for (var i:int = 0, len:int = this.shipArray.length; i < len; i++) {
				if (this.shipArray[i].shipType == e.target.text) {
					xSelectedShip = this.shipArray[i];
					this.selectedShipName = this.shipArray[i].shipType;
					break;
				}
			}
		
			try {
				this.subWin.removeChild(this.shipInfo);
				this.shipInfo = null;
			} catch (e:Error) {
				//trace("shipInfo not a child of subWin");
			}
				
			this.shipInfo = new Sprite();
			this.shipInfo.y = this.shipInfoWinHeight;
			var sShipInfo:String = "Ship Info:\n";
			sShipInfo += "Ship Type: " + xSelectedShip.shipType + "\n";
			sShipInfo += "Equipped Modules:\n";
			
			for each (var xModule:XML	 in xSelectedShip.modules.module) {
				sShipInfo += "    " + xModule + "\n";
			}
			
			sShipInfo += "Cargo:\n";
			
			for each (var xItem:XML in xSelectedShip.cargo.item) {
				sShipInfo += "    " + xItem + " " + xItem.@volume + " m3\n";
			}
			
			var sTest:TextField = this.drawText(sShipInfo, this.subWindowWidth);
			sTest.height = this.shipInfoWinHeight;
			this.shipInfo.addChild(sTest);
			this.subWin.addChild(this.shipInfo);
			
			try {
				this.makeActive.removeEventListener(MouseEvent.CLICK, changeShips);
				this.subWin.removeChild(this.makeActive);
				this.makeActive = null;
			} catch (e:Error) {
				//trace("makeActive button not a child of subWin");
			}
			
			this.makeActive = this.drawButton("Make this ship Active", 150, 150);
			this.makeActive.addEventListener(MouseEvent.CLICK, changeShips);
			this.subWin.addChild(this.makeActive);
		}
		
		private function changeShips(e:MouseEvent):void {
			this.oGL.changeShips(this.selectedShipName, this.sb);
			this.getShips();
		}
		
		private function unDock():void {
			this.sb.doAction("Undock");
			this.destroy();
		}
		
		///-- trade --///
		
		private var mineralValue:int = 20;
		
		private function trade():void {
			this.drawSubWindow();
			var rows:Array = new Array();
			var cargoHeadingText:Array = ["Desc.", "Volume", "Value", "Total"];
			rows.push(cargoHeadingText);
			
			// get active ship's cargo data
			for each (var xItem:XML in this.oGL.activeShip.cargo.item) {
				// get value of each item...	hack
				var value:int = 0;
				var total:int = 0;
				
				if (xItem == "minerals") {
					value = this.mineralValue;
					total = this.mineralValue * xItem.@volume;
				}
			
				var lineText:Array = new Array(xItem, xItem.@volume + " m3", value + " / m3", total, "sell");
				rows.push(lineText);
			}
			
			var table:Sprite = this.drawTable(rows, this.subWindowWidth, this.lineHeight);
			table.addEventListener(MouseEvent.CLICK, sellStuff);
			this.subWin.addChild(table);
		}
		
		private function sellStuff(e:MouseEvent):void {
			var globalClick:Point = new Point (e.stageX, e.stageY);
			var tablePoint:Point = this.subWin.globalToLocal(globalClick);
			
			// kind of hackish
			var rows:int = 0;
			
			for each (var xItem:XML in this.oGL.activeShip.cargo.item) {
				rows++;
			}
			
			var tableHeight:int = rows * this.lineHeight + this.lineHeight;
			var columns:int = 5;
			var columnWidth:int = Math.floor(this.subWindowWidth / columns);
			var xOffset:int = (columns - 1) * columnWidth;
			var yOffset:int = this.lineHeight;
			var sellValue:int = 0;
			var s:String = "";
			
			if (tablePoint.x >= xOffset && tablePoint.x <= this.subWindowWidth && tablePoint.y > yOffset && tablePoint.y < tableHeight) {
				var loX:int = tablePoint.x - xOffset;
				var loY:int = tablePoint.y - yOffset;
				var indx:int = loY / this.lineHeight;
				var i:int = 0;
				
				for each (var xItem2:XML in this.oGL.activeShip.cargo.item) {
					if (i == indx) {
						if (xItem2 == "minerals") {	// sell them rocks yo
							sellValue = xItem2.@volume * this.mineralValue;
							this.oGL.playerShip.removeCargo(xItem2);
						} else {
							s += "<item volume=\"" + xItem2.@volume + "\">" + xItem2 + "</item>";
						}
					}
					i++;
				}
				
				var curMoney:int = new int(this.oGL.oPlayerData.xmlData.money);
				this.oGL.oPlayerData.xmlData.money = XML(sellValue + curMoney);
				this.getShips();
				this.trade();	// redraw Window
			}
		}
		
		///-- goof --///
		
		private function hackTheGibson():void {
			this.drawSubWindow();
			var t:TextField = this.drawText("You need more googolflops to perform this action.", this.subWindowWidth);
			this.subWin.addChild(t);
		}
	
		///-- --///
		
		public function destroy():void {	// need to loop through the event listeners here too
			this.graphics.clear();
			this.parent.removeChild(this);
		}
	}
}