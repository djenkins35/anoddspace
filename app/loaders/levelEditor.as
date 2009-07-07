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


package app.loaders {
	import flash.events.*;
	import flash.geom.Point;
	import flash.display.Stage;
	import flash.display.Sprite;
	
	import app.baseClasses.realMover;
	import app.baseClasses.asteroid;
	import app.baseClasses.starBase;
	import app.baseClasses.fighterHanger;
	import app.loaders.dataLoader;
	import app.loaders.parallax;
	import app.loaders.userInput;
	import app.userInterface.levelEditor.levelEditorUI;
	
	public class levelEditor extends Sprite {
		public var ui:levelEditorUI;
		public var objectArray:Array = new Array();			// holds anything worth targeting
		public var zoomLevel:Number = 1;					// set parallax.as::zoom()
		public var gamescreen:Sprite = new Sprite();
		public var pllx:parallax;
		public var focalPoint:Point;			// focus of parallax.centerOnFocus()
		private var usrInpt:userInput;
		private var panSpeed:int = 15;						// panning the gamescreen via arrow keys
		
		///-- Data Directories --///
		public var imageDir:String = "app/media/images";
		public var soundDir:String = "app/media/sounds";
		public var xmlDataDir:String = "app/xmlData";
		public var mapDataDir:String = xmlDataDir + "/mapData";
		public var playerDataDir:String = xmlDataDir + "/playerData";
		
		///-- XML Data --///
		public var activeShip:XML;
		public var activeShipSpec:XML;
		public var oPlayerData:dataLoader = new dataLoader(playerDataDir + '/testPlayer.xml', 'playerData', this);
		public var oMapObjects:dataLoader = new dataLoader(xmlDataDir + '/mapObjects.xml', 'mapObjects', this);
		public var oShipData:dataLoader = new dataLoader(xmlDataDir + '/ships.xml', 'shipData', this);
		public var oEquipmentData:dataLoader = new dataLoader(xmlDataDir + '/equipment.xml', 'equipmentData', this);
		//public var oMapData:dataLoader = new dataLoader(mapDataDir + '/testmap.02.xml', 'mapData', this);
		
		public function levelEditor():void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.ENTER_FRAME, main);
		}
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oPlayerData.load();
		}
		
		///-- Callbacks & XML Loaders --///
		
		public function dataCallBack(s:String):void {
			switch (s) {
				case "playerData" :
					this.processPlayerData();
					this.oShipData.load();
					break;
				
				case "shipData" :
					this.processShipData();
					this.oEquipmentData.load();
					break;
				
				case "equipmentData" :
					this.oMapObjects.load();
					break;
				
				case "mapData" :
					//this.oMapObjects.load();
					break;
					
				case "mapObjects" :
					this.loadEditor();
					break;
			}
		}
		
		private function processPlayerData():void {
			for each (var ship:XML in this.oPlayerData.xmlData.ships.ship) {
				if (ship.@active == "yes") {
					this.activeShip = ship;
					break;
				}
			}
		}
		
		private function processShipData():void {
			for each (var shipSpec:XML in this.oShipData.xmlData.ship) {
				if (shipSpec.@shipType == this.activeShip.shipType) {
					this.activeShipSpec = shipSpec;
					break;
				}
			}
		}
		
		///-- XML Data Loaded, Load Editor --///
		
		private function loadEditor():void {
			this.pllx = new parallax(this)
			this.focalPoint = new Point();
			this.focalPoint.x = 0;
			this.focalPoint.y = 0;
			this.pllx.focalPoint = this.focalPoint;
			this.gamescreen.addChildAt(this.pllx, 0);
			this.stage.addChild(this.gamescreen);
			
			this.ui = new levelEditorUI(this);
			this.stage.addChild(this.ui);
			
			this.usrInpt = new userInput();
			this.usrInpt.oGL = this;
			this.stage.addChild(this.usrInpt);
		}
		
		///-- Public Functions --///
		
		public function dragMap(focalPointX:Number, focalPointY:Number):void {	// called from radarUI.as
			this.focalPoint.x = focalPointX;
			this.focalPoint.y = focalPointY;
			this.pllx.focalPoint.x = this.focalPoint.x;
			this.pllx.focalPoint.y = this.focalPoint.y;
		}
		
		public function updateObjectArray(xData:XML):void {		// called from levelEditorUI.as
			var isNew:Boolean = true;
			
			// check if object exists in array
			for (var i:int = 0, len:int = this.objectArray.length; i < len; i++) {
				if (this.objectArray[i].OAIndex == xData.OAIndex) {
					isNew = false;
					this.objectArray[i] = xData;
					break;
				}
			}
			
			if (isNew) {	// if not, add to array
				this.objectArray.push(xData);
			}
		}
		
		public function deleteObj(xData:XML):void {
			for (var i:int = 0, len:int = this.objectArray.length; i < len; i++) {
				if (this.objectArray[i].OAIndex == xData.OAIndex) {
					this.objectArray.splice(i, 1);
					break;
				}
			}
		}
		
		public function closeEditor():void {
			this.pllx.destroy();
			this.ui.destroy();
			this.destroy();
		}
		
		///-- destructor --///
		
		public function destroy():void {
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.stage.removeChild(this.gamescreen);
			this.dispatchEvent(new Event('editorClosed'));
			this.parent.removeChild(this);
		}
		
		///-- Main --///
		
		private function main(e:Event):void {
			if (this.focalPoint != null) {
				if (this.usrInpt.upArrowPressed) {
					this.focalPoint.y -= this.panSpeed;
					this.gamescreen.dispatchEvent(new Event('radarPanChanged'));
				}
				
				if (this.usrInpt.downArrowPressed) {
					this.focalPoint.y += this.panSpeed;
					this.gamescreen.dispatchEvent(new Event('radarPanChanged'));
				}
				
				if (this.usrInpt.leftArrowPressed) {
					this.focalPoint.x -= this.panSpeed;
					this.gamescreen.dispatchEvent(new Event('radarPanChanged'));
				}
				
				if (this.usrInpt.rightArrowPressed) {
					this.focalPoint.x += this.panSpeed;
					this.gamescreen.dispatchEvent(new Event('radarPanChanged'));
				}
				
				if (this.usrInpt.rKeyPressed) {
					this.ui.drawRotationCircle();
				}
			}
		}
	}
}
