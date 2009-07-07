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


package app.userInterface.levelEditor {
	import flash.display.Sprite;
	import flash.text.*;
	import flash.events.*;
	import flash.geom.Point;
	
	import app.loaders.levelEditor;
	import app.loaders.imageLoader;
		
	public class objectEditorUI extends Sprite {
		include "commonUI.as";
		private var xOffset:int = 220;
		private var yOffset:int = 0;
		private var subWindowWidth:int = 300;
		private var subWindowHeight:int = 400;
		private var newWidth:int = 300;
		private var newHeight:int = 400;
		private var labelWidth:int = 150;
		private var inputColor:uint = 0x333366;		// background color for input boxes
		private var shipOptions:Array = ["Details", "Modules", "Cargo"];
		private var shipDetails:Array = ["faction", "name", "hull", "shield", "acceleration", "angularSpeed", "maxSpeed", "radarRange", "cargoCapacity"];
		
		private var shipTab:String = "";			// used as a switch value for the saveShip() event listner
		private var xObj:XML;
		private var oGL:levelEditor;
		
		
		///-- constructor --///
		
		public function objectEditorUI(xDetails:XML, oGL:levelEditor):void {
			this.xObj = xDetails;
			this.oGL = oGL;
		
			// override the defaults in commonUI.as
			this.iWidth = this.newWidth;
			this.iHeight = this.newHeight;
			
			// draw new window
			this.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.graphics.beginFill(this.fillStyle[0], this.fillStyle[1]);
			this.graphics.drawRect(0,0,this.iWidth,this.iHeight);
			this.graphics.endFill();
			this.x = this.xOffset;
			this.y = this.yOffset;
		
			// check object type
			var sTest:String = xDetails.toXMLString();
			var s1:int = sTest.indexOf("<");
			var s2:int = sTest.indexOf(">");
			var sArr:Array = sTest.substring(s1 + 1,s2).split(' ');	// weed out attributes
			
			switch (sArr[0]) {
				case "asteroid" :
					this.editAsteroid();
					break;
				
				// starbase - ???
				case "starBase" :
					this.editStarbase();
					break;
				
				case "ship" :
					this.editShip();
					break;
				
				// stationary - hull, shield, modules
				case "hanger" :
					trace(xDetails);
					break;
			}
			
			// add event listener to close window
			var closeButton:Sprite = this.drawButton("Close");
			closeButton.addEventListener(MouseEvent.CLICK, closeWindow);
			this.addChild(closeButton);
		}
		
		///-- common functions --///
		
		private function drawInput(s:String, sLabel:String = "", inputWidth:int = 150, BGColor:uint = 0):TextField {
			var inpt:TextField = new TextField();
			inpt.textColor = this.txtColor;
			inpt.height = this.lineHeight;
			inpt.text = s;
			inpt.name = sLabel;				// useful for the event listener
			inpt.width = inputWidth;
			inpt.border = true;
			inpt.background = true;
			inpt.type = TextFieldType.INPUT;
			
			if (BGColor != 0) {
				inpt.backgroundColor = BGColor;
			} else {
				inpt.backgroundColor = this.inputColor;
			}
			
			return inpt;
		}
		
		private function drawHMenu(arr:Array, menuWidth:int = 300, eventListener:Function = null):Sprite {
			var hMenu:Sprite = new Sprite();
			
			// get each button's width
			var len:int = arr.length
			var itemWidth:int = Math.floor(menuWidth / len);
			
			for (var i:int = 0; i < len; i++) {
				var b:Sprite = this.drawButton(arr[i], itemWidth);
				
				if (eventListener != null) {
					b.addEventListener(MouseEvent.CLICK, eventListener);
					b.x = i * itemWidth;
				}
				
				hMenu.addChild(b);
			}
			
			return hMenu;
		}
		
		private function drawInputList(arr:Array, listWidth:int = 300):Sprite {
			var inputList:Sprite = new Sprite();
			var elementWidth:int = Math.floor(listWidth / 2);
			
			// draw a label and input field for each item in the array
			// the label name needs to match the xmlData for the event listener to work properly
			for (var i:int = 0, len:int = arr.length; i < len; i++) {
				var label:TextField = this.drawText(arr[i], elementWidth);
				label.y = i * this.lineHeight;
				inputList.addChild(label);
				var inpt:TextField = this.drawInput(this.xObj.child(arr[i]), arr[i], elementWidth - 1);
				inpt.x = elementWidth;
				inpt.y = i * this.lineHeight;
				inputList.addChild(inpt);
			}
			
			return inputList;
		}
		
		///-- --///
		
		private function editStarbase():void {
			this.drawSubWindow(this.subWindowWidth, this.subWindowHeight, 0, this.lineHeight);
			
			// label
			var label:TextField = this.drawText("Faction", this.labelWidth);
			this.subWin.addChild(label);
			
			// input box
			var faction:TextField = this.drawInput(this.xObj.faction, "faction", Math.floor(this.newWidth / 2));
			faction.x = this.labelWidth;
			this.subWin.addChild(faction);
			
			// save button
			var saveButton:Sprite = this.drawButton("Save");
			saveButton.y = this.lineHeight;
			saveButton.addEventListener(MouseEvent.CLICK, saveStarbase);
			this.subWin.addChild(saveButton);
		}
		
		
		private function editAsteroid():void {
			this.drawSubWindow(this.subWindowWidth, this.subWindowHeight, 0, this.lineHeight);
			
			// label
			var label:TextField = this.drawText("Edit Mineral Amount", this.labelWidth);
			this.subWin.addChild(label);
			
			// input box
			var minerals:TextField = this.drawInput(this.xObj.minerals, "minerals", Math.floor(this.newWidth / 2));
			minerals.x = this.labelWidth;
			this.subWin.addChild(minerals);
			
			// save button
			var saveButton:Sprite = this.drawButton("Save");
			saveButton.y = this.lineHeight;
			saveButton.addEventListener(MouseEvent.CLICK, saveAsteroid);
			this.subWin.addChild(saveButton);
		}
		
		private function editShip(sTab:String = ""):void {
			try {
				this.removeChild(this.subWin);
				this.subWin = null;
			} catch (e:Error) { /*trace("subWin not drawn");*/ }
			
			this.drawSubWindow(this.subWindowWidth, this.subWindowHeight, 0, this.lineHeight);
			
			// tabs for: details, modules, cargo
			this.subWin.addChild(this.drawHMenu(this.shipOptions, this.newWidth, onShipTabSelect));
			
			
			switch (sTab) {
				case "Modules" :
					this.shipTab = "Modules";
					this.configureModules();
					break;
					
				case "Cargo" :
					this.shipTab = "Cargo";
				
					break;
					
				case "Details" :
					// fall through
					
				default :
					// edit details
					this.shipTab = "Details";
					var inptList:Sprite = this.drawInputList(this.shipDetails);
					inptList.y = this.lineHeight * 2;
					inptList.name = "inputList";
					this.subWin.addChild(inptList);
					
					break;
			}
			
			// add save button
			var saveButton:Sprite = this.drawButton("Save");
			saveButton.y = this.lineHeight;
			saveButton.addEventListener(MouseEvent.CLICK, saveShip);
			this.subWin.addChild(saveButton);
		}
		
		private function configureModules():void {	// this will eventually be its own class
			// list modules
			var modArr:Array = new Array();
			
			for each (var xModule:XML in this.oGL.oEquipmentData.xmlData.modules.module) {
				modArr.push(xModule);
			}
			
			// show picture of ship w/ external module slots
			var img:imageLoader = new imageLoader(this.oGL.imageDir + "/" + this.xObj.imageURL);
			img.addEventListener('imageLoaded', scaleShipImage);
			img.y = 100; 	// hack
			img.x = 20;		// ^	
			this.subWin.addChild(img);
			
			// draw external module slots
			var pointArr:Array = new Array();
			
			// draw an overlay for the indicator lines
			// basically just need something that sits on top of the imageLoader
			var graphOverlay:Sprite = new Sprite();
			graphOverlay.x = img.x;
			graphOverlay.y = img.y;
			this.subWin.addChild(graphOverlay);
			
			for (var i:int = 0, len:int = this.xObj.externalHardPoints.hardPoint.length(); i < len; i++) {
				var hpArr:Array = this.xObj.externalHardPoints.hardPoint[i].split(',');
				var newPoint:Point = new Point(hpArr[0], hpArr[1]);
				pointArr.push(newPoint);
				
				// draw a circle
				var moduleOverlay:Sprite = new Sprite;
				moduleOverlay.x = newPoint.x;
				moduleOverlay.y = newPoint.y;
				moduleOverlay.graphics.lineStyle(1, 0x000000);
				moduleOverlay.graphics.beginFill(0xFFFFFF);
				moduleOverlay.graphics.drawEllipse(0, 0, 10, 10);
				moduleOverlay.graphics.endFill();
				img.addChild(moduleOverlay);
				
				// draw an input box for each module
				var inpt:TextField;
				
				// check if module exists
				if (this.xObj.hasOwnProperty("modules") && this.xObj.modules.module.length() > i) {
					inpt = this.drawInput(this.xObj.modules.module[i], "module" + i);
				} else {
					inpt = this.drawInput("empty", "module" + i);
				}
				
				inpt.x = 149;
				inpt.y = i * this.lineHeight + this.lineHeight;		// offset for top menu
				this.subWin.addChild(inpt);
				
				// draw a line from the module to the input box
				var p1:Point = new Point(moduleOverlay.x + 5, moduleOverlay.y + 5);
				var p2:Point = new Point(inpt.x, inpt.y + this.lineHeight / 2);
				var gP1:Point = moduleOverlay.localToGlobal(p1);
				var gP2:Point = this.subWin.localToGlobal(p2);
				var loP1:Point = graphOverlay.globalToLocal(gP1);
				var loP2:Point = graphOverlay.globalToLocal(gP2);
				
				graphOverlay.graphics.lineStyle(1, 0xFFFFFF);
				graphOverlay.graphics.moveTo(loP1.x, loP1.y);
				graphOverlay.graphics.lineTo(loP2.x, loP2.y);
			}
		
			// show list of internal modules installed
		}
		
		///-- event listeners --///
		
		private function onShipTabSelect(e:MouseEvent):void {	// passes target text to editShip()
			this.editShip(e.target.text);
		}
		
		private function saveAsteroid(e:MouseEvent):void {
			// parent.parent is the subWin container
			var mineralAmount:int = new int(e.target.parent.parent.getChildByName("minerals").text);
			
			// update the details in the objectArray, and the selectedObj
			for (var i:int = 0, len:int = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].OAIndex == this.xObj.OAIndex) {
					this.xObj.minerals = mineralAmount;
					this.oGL.updateObjectArray(this.xObj);
					
					// update the details in the levelEditor UI also
					this.oGL.ui.selectedObj.details = this.xObj;
					break;
				}
			}
			
			// close window & remove event listners
			e.target.parent.removeEventListener(MouseEvent.CLICK, saveAsteroid);
			this.parent.removeChild(this);
		}
		
		private function saveStarbase(e:MouseEvent):void {
			// parent.parent is the subWin container
			var faction:String = e.target.parent.parent.getChildByName("faction").text;
			
			// update the details in the objectArray, and the selectedObj
			for (var i:int = 0, len:int = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].OAIndex == this.xObj.OAIndex) {
					this.xObj.faction = faction;
					this.oGL.updateObjectArray(this.xObj);
					
					// update the details in the levelEditor UI also
					this.oGL.ui.selectedObj.details = this.xObj;
					break;
				}
			}
			
			// close window & remove event listners
			e.target.parent.removeEventListener(MouseEvent.CLICK, saveStarbase);
			this.parent.removeChild(this);
		}
		
		private function saveShip(e:MouseEvent):void {
			var i:int;
			var len:int;
		
			switch (this.shipTab) {
				case "Details" :
					var inptList:Sprite = e.target.parent.parent.getChildByName("inputList");
					
					for (i = 0, len = this.shipDetails.length; i < len; i++) {
						// here be dragons...
						// have to get the the index of the XML property you want to edit
						// why? because you can't set properties with child() :(
						var detailName:String = this.shipDetails[i];
						var txt:* = inptList.getChildByName(detailName);	// casting to textfield throws an error
						var indx:int = this.xObj.child(detailName).childIndex();
						this.xObj.*[indx] = txt.text;
					}
					
					break;
					
				case "Modules" :
					for (i = 0, len = this.xObj.externalHardPoints.hardPoint.length(); i < len; i++) {
						this.xObj.modules.module[i] = e.target.parent.parent.getChildByName("module" + i).text;
						this.xObj.modules.module[i].@moduleType = "external";
						this.xObj.modules.module[i].@position = i;
					}
					
					break;
					
				case "Cargo" :
				
					break;
			}
			
			// update the details in the objectArray, and the selectedObj
			for (i = 0, len = this.oGL.objectArray.length; i < len; i++) {
				if (this.oGL.objectArray[i].OAIndex == this.xObj.OAIndex) {
					this.oGL.objectArray[i] = this.xObj;
					this.oGL.ui.selectedObj.details = this.xObj;
					break;
				}
			}
		}
		
		private function scaleShipImage(e:Event):void {		// custom 'imageLoaded' event assigned in configureModules()
			e.target.removeEventListener('imageLoaded', scaleShipImage);
			var w:int = 100;	// scale the image to this
			var imgWidth:int = e.target.width;
			var coef:Number = w / imgWidth;
			e.target.width *= coef;
			e.target.height *= coef;
		}
		
		private function closeWindow(e:MouseEvent):void {
			e.target.removeEventListener(MouseEvent.CLICK, closeWindow);
			this.parent.removeChild(this);
		}
		
		///-- destructor --///
		
		public function destroy():void {
		
		}
	}
}