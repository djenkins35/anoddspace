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
	import flash.display.Stage;
	import flash.display.Sprite;
	import flash.utils.Timer;
	
	import app.baseClasses.realMover;
	import app.baseClasses.asteroid;
	import app.baseClasses.starBase;
	import app.userInterface.game.starBaseUI;
	import app.baseClasses.fighterHanger;
	import app.loaders.gameSound;
	import app.loaders.parallax;
	import app.loaders.userInput;
	import app.loaders.dataLoader;
	import app.loaders.dataEvent;
	
	
	public class gameloader extends Sprite {
		public var gamescreen:Sprite;						// parent of all display objects but the UI
		public var pllx:parallax;
		public var oGS:gameSound;
		public var usrInpt:userInput;
		public var playerShip:realMover;
		public var playerTargetArray:Array = new Array();	// target info for the UI
		public var isUserInput:Boolean = true;
		public var objectArray:Array = new Array();			// holds anything worth targeting
		public var heartBeatInterval:uint = 250;			// milliseconds between global heartbeats
		public var heartBeatTimer:Timer = new Timer(heartBeatInterval, 0);
		
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
		public var oMapData:dataLoader;		// instantiated in constructor
		public var oShipData:dataLoader = new dataLoader(xmlDataDir + '/ships.xml', 'shipData', this);
		public var oEquipmentData:dataLoader = new dataLoader(xmlDataDir + '/equipment.xml', 'equipmentData', this);
		
		public function gameloader(map:String):void {
			this.oMapData = new dataLoader(mapDataDir + '/' + map, 'mapData', this);
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		//
		///-- Callbacks & XML Loaders --///
		//
		
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
					this.oMapData.load();
					break;
				
				case "mapData" :
					this.loadGame();
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
		
		///-- XML Data Loaded, Load Game --///
		
		private function loadMapData():void {
			for each (var xObj:XML in this.oMapData.xmlData.*) {
				
				// get string value from the first tag
				var sTest:String = xObj.toXMLString();
				var s1:int = sTest.indexOf("<");
				var s2:int = sTest.indexOf(">");
				var sArr:Array = sTest.substring(s1 + 1,s2).split(' ');	// weed out attributes
				
				switch (sArr[0]) {
					case "asteroid" :
						var ast:asteroid = new asteroid(xObj, this);
						this.objectArray.push(ast);
						break;
					
					case "hanger" :
						var fh:fighterHanger = new fighterHanger(xObj, this);
						this.objectArray.push(fh);
						break;
						
					case "starBase" :
						var sb:starBase = new starBase(xObj, this);
						this.objectArray.push(sb);
						break;
					
					case "ship" :
						for each (var shipSpec:XML in this.oShipData.xmlData.ship) {
							if (shipSpec.@shipType == xObj.@shipType) {
								var oShip:realMover = new realMover(this, shipSpec, xObj.toString());
								
								// set default actions
								oShip.actionArr = oShip.defaultActions;
								this.objectArray.push(oShip);
							}
						}
						
						break;
						
					case "playerStart" :
						var startPos:Array = xObj.position.split(',');
						this.playerShip = new realMover(this, this.activeShipSpec);
						this.playerShip.x = startPos[0];
						this.playerShip.y = startPos[1];
						this.playerShip.faction = xObj.faction;
						this.objectArray.push(this.playerShip);
						break;
				}
			}
		}
		
		private function loadGame():void {
			this.gamescreen = new Sprite();
			this.addChild(this.gamescreen);
			
			this.usrInpt = new userInput();
			this.usrInpt.oGL = this;
			this.addChild(this.usrInpt);
			
			this.oGS = new gameSound(this);
			
			this.loadMapData();
			
			for (var i:uint = 0, len:uint = this.objectArray.length; i < len; i++) {
				this.objectArray[i].indx = i;
				
				if (this.objectArray[i] is realMover) {
					this.gamescreen.addChildAt(this.objectArray[i], this.gamescreen.numChildren);
				} else {	// place stationary objects lower in the display list
					this.gamescreen.addChildAt(this.objectArray[i], 0);
				}
			}
			
			this.pllx = new parallax(this);
			this.pllx.focalPoint = this.playerShip;
			this.gamescreen.addChildAt(this.pllx, 0);
			this.gamescreen.scaleX = this.pllx.zoomLevel;
			this.gamescreen.scaleY = this.pllx.zoomLevel;
			
			this.heartBeatTimer.addEventListener(TimerEvent.TIMER, sendHeartBeat);
			this.heartBeatTimer.start();
			
			this.dispatchEvent(new Event('gameLoaded'));
		}
		
		//
		///-- Public Functions --///
		//
			
		public function unloadObject(obj:*):void {
			this.gamescreen.removeChild(obj);
			this.objectArray.splice(this.objectArray.indexOf(obj), 1);
			
			// reset all objects' index property
			for (var i:uint = 0, len:uint = this.objectArray.length; i < len; i++) {
				this.objectArray[i].indx = i;
				
				// dispatch custom event for module listeners
				this.objectArray[i].dispatchEvent(new dataEvent(obj, "targetDied"));
			}
			
			obj = null;
		}
		
		public function closeGame():void {
			this.heartBeatTimer.stop();
			
			this.oGS.destroy();
			this.oGS = null;
			
			this.playerShip.destroy();
			this.playerShip = null;
			
			this.pllx.destroy();
			this.pllx = null;
			
			this.usrInpt.destroy();
			this.usrInpt = null;
		
			for each (var obj:* in this.objectArray) {
				obj.destroy();
				obj = null;
			}
			
			this.objectArray = null;
			
			this.oPlayerData.destroy();
			this.oMapData.destroy();
			this.oShipData.destroy();
			this.oEquipmentData.destroy();
			
			this.destroy();
		}
		
		
		///-- Player Ship Functions --///
		
		public function updateCargo():void {
			for each (var ship:XML in this.oPlayerData.xmlData.ships.ship) {
				if (ship.@active == "yes") {
					ship.cargo = "";
					
					for each (var obj:Object in this.playerShip.cargoArray) {
						var s:String = "<item volume=\"" + obj.volume + "\">" + obj.item + "</item>";
						ship.cargo.item += XML(s);
					}
				}
			}
		}
		
		public function updatePlayerData(shipName:String, base:starBase):void {
			for each (var ship:XML in this.oPlayerData.xmlData.ships.ship) {
				if (ship.@active == "yes") {
					ship.@active = "no";
					ship.location = base.baseName;
					ship.cargo = "";
					
					for each (var obj:Object in this.playerShip.cargoArray) {
						var s:String = "<item volume=\"" + obj.volume + "\">" + obj.item + "</item>";
						ship.cargo.item += XML(s);
					}
				}
				
				if (ship.shipType == shipName && ship.location == base.baseName) {
					ship.@active = "yes";
					ship.location = "";
					this.activeShip = ship;
					
					this.processShipData();
				}
			}
		}
		
		public function changeShips(shipName:String, base:starBase):void {
			var tmpFaction:String = this.playerShip.faction;
			this.updatePlayerData(shipName, base);
			this.playerShip.destroy();
			this.playerShip = null;
			this.playerShip = new realMover(this, this.activeShipSpec);
			
			this.playerShip.faction = tmpFaction;
			this.objectArray.push(this.playerShip);
			
			this.playerShip.x = base.x;
			this.playerShip.y = base.y;
			this.pllx.focalPoint = this.playerShip;
			this.gamescreen.addChildAt(this.playerShip, this.gamescreen.numChildren);
		}
		
		public function dockShip(dockTarget:starBase):void {
			this.playerShip.AI.moveCoords.x = dockTarget.x;
			this.playerShip.AI.moveCoords.y = dockTarget.y;
			this.playerShip.AI.isStopping = true;
			this.playerShip.AI.isMoving = true;
			this.playerShip.AI.moveToCoords();
			
			this.usrInpt.toggleUserInput();
			this.updateCargo();
		}
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.ENTER_FRAME, main);
			this.addEventListener('updatePlayerTargetArray', updatePlayerTargetArray);
			this.oPlayerData.load();
		}
		
		private function updatePlayerTargetArray(e:dataEvent):void {
			// deselect the currently selected objects
			for each (var obj:Object in this.objectArray) {
				obj.dispatchEvent(new Event('deSelected'));
			}
			
			// reset the target array
			this.playerTargetArray = new Array();
			
			// add ships to the target array, and dispatch the event to trigger the overlay
			for each (var ship:realMover in e.dataObj) {
				this.playerTargetArray.push(ship);
				ship.dispatchEvent(new Event('selected'));
			}
		}
		
		//
		///-- Main Loops --///
		//
		
		private function getTargetDistance(dx:Number, dy:Number):Number {	// used in heartbeat loop
			var maxRange:Number = this.playerShip.radarRange;						// throw out anything that is definitely out of range
			
			if (dx <= maxRange && dy <= maxRange) { 						// maybe in range
				var dist:Number = Math.sqrt(dx * dx + dy * dy);
				
				if (dist <= maxRange) {
					return dist;
				} else {
					return -1;
				}
			} else {
				return -1;
			}
		}
		
		private function sendHeartBeat(e:TimerEvent):void {
			for (var i:uint = 0, len:int = this.objectArray.length; i < len; i++) {
				if (this.objectArray[i] != null) { 
					this.objectArray[i].heartBeat(); 
				}
			}
			
			this.oGS.heartBeat();
		}
		
		private function main(e:Event):void {
			if (this.playerShip != null) {
				if (this.usrInpt.upArrowPressed) {
					this.playerShip.applyThrust();
				} else {
					this.playerShip.killThrust();
				}
				
				if (this.usrInpt.downArrowPressed) {
					this.playerShip.slowDown();
				}
				
				if (this.usrInpt.leftArrowPressed) {
					this.playerShip.rotateCCW();
				}
				
				if (this.usrInpt.rightArrowPressed) {
					this.playerShip.rotateCW();
				}
			
				if (this.usrInpt.tKeyPressed) {
					//this.playerShip.cycleTargets();
					this.playerShip.dispatchEvent(new Event('cycleTargets'));
					this.usrInpt.tKeyPressed = false;
				}
				
				if (this.usrInpt.eKeyPressed) {
					this.playerShip.targetClosestEnemy();
					this.usrInpt.eKeyPressed = false;
				}
				
				if (this.usrInpt.spacePressed) {
					this.playerShip.toggleModules();
					this.usrInpt.spacePressed = false;
				}
			}
		}
	
		//
		///-- destructor --///
		//
		
		public function destroy():void {
			this.heartBeatTimer.removeEventListener(TimerEvent.TIMER, sendHeartBeat);
			this.removeEventListener(Event.ENTER_FRAME, main);
			this.dispatchEvent(new Event('gameClosed'));
		}
	}
}
