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
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	
	import app.baseClasses.realMover;
	import app.baseClasses.asteroid;
	import app.baseClasses.starBase;
	import app.baseClasses.fighterHanger;
	import app.loaders.gameSound;
	import app.loaders.parallax;
	import app.loaders.userInput;
	import app.loaders.dataEvent;
	
	
	public class gameloader extends Sprite {
		public var gamescreen:Sprite;						// parent of all display objects but the UI
		public var pllx:parallax;
		public var oGS:gameSound;
		public var usrInpt:userInput;
		public var playerShip:realMover;
		public var playerFaction:String;	// set in loadMapData() - eventually going to need a seperate player class for all this stuff
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
		public var mapDataURL:String;	// set in constructor
		public var playerDataURL:String = 'testPlayer.xml';	// tbr with player class
		public var shipDataURL:String = 'ships.xml';
		public var equipmentDataURL:String = 'equipment.xml';
		
		///-- XML Data --///
		public var activeShip:XML;
		public var activeShipSpec:XML;
		public var xPlayerData:XML;
		public var xMapData:XML;
		public var xShipData:XML;
		public var xEquipmentData:XML;
		
		
		//
		///-- Constructor --///
		//
		
		public function gameloader(map:String):void {
			this.mapDataURL = map;
			
			// this starts the xml data loading chain that eventually calls the loadGame method to start the game
			var playerDataLoader:URLLoader = new URLLoader();
			playerDataLoader.addEventListener('complete', xmlDataLoaded);
			playerDataLoader.load(new URLRequest(this.playerDataDir + '/' + this.playerDataURL));
			
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		//
		///-- Private Methods --///
		//
		
		private function loadGame():void {	// called at the end of the xmlDataLoaded chain
			this.gamescreen = new Sprite();
			this.addChild(this.gamescreen);
			
			this.usrInpt = new userInput();
			this.usrInpt.oGL = this;
			this.addChild(this.usrInpt);
			
			this.oGS = new gameSound(this);
			
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
			
			this.destroy();
		}
		
		
		///-- Player Ship Functions --///
		
		public function updateCargo():void {
			for each (var ship:XML in this.xPlayerData.ships.ship) {
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
			for each (var ship:XML in this.xPlayerData.ships.ship) {
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
					
					//this.processShipData();
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
		
		//
		///-- Event Listeners --///
		//
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.ENTER_FRAME, main);
			this.addEventListener('updatePlayerTargetArray', updatePlayerTargetArray);
			this.addEventListener('playerShipDocked', onPlayerShipDocked);
			this.addEventListener('undockPlayerShip', onPlayerShipUndocked);
		}
		
		private function xmlDataLoaded(e:Event):void {	// chain loads and processes the various xml data files
			e.target.removeEventListener('complete', xmlDataLoaded);
			
			var xData:XML = XML(e.target.data);
			
			switch (xData.name().toString()) {
				case 'player':	// get the active ship
					this.xPlayerData = xData;
					
					for each (var ship:XML in this.xPlayerData.ships.ship) {
						if (ship.@active == 'yes') { this.activeShip = ship; break; }
					}
					
					// load the ship data
					var shipDataLoader:URLLoader = new URLLoader();
					shipDataLoader.addEventListener('complete', xmlDataLoaded);
					shipDataLoader.load(new URLRequest(this.xmlDataDir + '/' + this.shipDataURL));
					
					break;
					
				case 'ships':	// get the active ship's specs
					this.xShipData = xData;
					
					for each (var shipSpec:XML in this.xShipData.ship) {
						if (shipSpec.@shipType == this.activeShip.shipType) { this.activeShipSpec = shipSpec; break; }
					}
					
					// load equipment data
					var equipmentDataLoader:URLLoader = new URLLoader();
					equipmentDataLoader.addEventListener('complete', xmlDataLoaded);
					equipmentDataLoader.load(new URLRequest(this.xmlDataDir + '/' + this.equipmentDataURL));
					
					break;
					
				case 'equipment':	// load the map data
					this.xEquipmentData = xData;
					var mapDataLoader:URLLoader = new URLLoader();
					mapDataLoader.addEventListener('complete', xmlDataLoaded);
					mapDataLoader.load(new URLRequest(this.mapDataDir + '/' + this.mapDataURL));
					break;
					
				case 'mapObjects':	// populate the objectArray
					this.xMapData = xData;
					
					for each (var xObj:XML in this.xMapData.*) {
						// get string value from the first tag
						// can't use xObj.name because I've got my own name tag, oops
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
								for each (var xShipSpec:XML in this.xShipData.ship) {
									if (xShipSpec.@shipType == xObj.@shipType) {
										var oShip:realMover = new realMover(this, xShipSpec, xObj.toString());
										this.objectArray.push(oShip);
									}
								}
								
								break;
								
							case "playerStart" :
								var startPos:Array = xObj.position.split(',');
								this.playerShip = new realMover(this, this.activeShipSpec);
								this.playerShip.x = startPos[0];
								this.playerShip.y = startPos[1];
								this.playerShip.faction = this.playerFaction = xObj.faction;
								this.objectArray.push(this.playerShip);
								
								break;
						}
					}
					
					// we're done, now load the game
					this.loadGame();
					
					break;
			}
		}
		
		private function updatePlayerTargetArray(e:dataEvent):void {
			// deselect the currently selected objects
			for each (var obj:Object in this.objectArray) {
				obj.dispatchEvent(new Event('deSelected'));
			}
			
			// reset the target array
			this.playerTargetArray = new Array();
			
			// add ships to the target array, and dispatch the event to trigger the overlay
			for each (var ship:Object in e.dataObj) {
				this.playerTargetArray.push(ship);
				ship.dispatchEvent(new Event('selected'));
			}
		}
		
		private function onPlayerShipDocked(e:dataEvent):void {	// gameUI.as also has a listener for this event to bring up the starBaseUI
			this.usrInpt.dispatchEvent(new Event('toggleUserInputOff'));
			this.updateCargo();
		}
		
		private function onPlayerShipUndocked(e:Event):void {
			this.usrInpt.dispatchEvent(new Event('toggleUserInputOn'));
		}
		
		//
		///-- Main Loops --///
		//
		
		private function sendHeartBeat(e:TimerEvent):void {
			for (var i:uint = 0, len:int = this.objectArray.length; i < len; i++) {
				if (this.objectArray[i] != null) { 
					this.objectArray[i].heartBeat(); 
				}
			}
		}
		
		private function main(e:Event):void {
			if (this.playerShip != null) {
				if (this.usrInpt.upArrowPressed) {
					this.playerShip.applyThrust();
				} else {
					if (this.playerShip.AI.isStopping == false	// don't override the AI
						&& this.playerShip.AI.isMoving == false) {
						
						this.playerShip.killThrust();
					}
				}
				
				if (this.usrInpt.downArrowPressed) {
					this.playerShip.AI.isStopping = true;
				}
				
				if (this.usrInpt.leftArrowPressed) {
					this.playerShip.rotateCCW();
				}
				
				if (this.usrInpt.rightArrowPressed) {
					this.playerShip.rotateCW();
				}
			
				if (this.usrInpt.tKeyPressed) {
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
			this.removeEventListener('playerShipDocked', onPlayerShipDocked);
			this.removeEventListener('undockPlayerShip', onPlayerShipUndocked);
			this.removeEventListener('updatePlayerTargetArray', updatePlayerTargetArray);
			this.dispatchEvent(new Event('gameClosed'));
		}
	}
}
