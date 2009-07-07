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


package app {
	
	import flash.events.*;
	
	import mx.containers.Canvas;
	import mx.containers.Panel;
	import mx.containers.Box;
	import mx.controls.List;
	import mx.controls.TextArea;
	import mx.events.ListEvent;
	
	import app.loaders.dataLoader;
	import app.loaders.gameloader;
	import app.loaders.levelEditor;
	import app.userInterface.game.gameUI;
	
	public class appRoot extends Canvas {
		
		///-- Data Properties --///
		
		private var mapDataDir:String = 'app/xmlData/mapData/';
		private var mapListURL:String = 'mapList.xml';
		private var mapURL:String;
		private var oMapList:dataLoader = new dataLoader(mapDataDir + mapListURL, "mapList" , this);
		
		///-- Display Properties --///
		
		private var pre:Panel;
		private var mainMenu:List;
		private var subWin:Box;
		private var sVersion:String = "v 0.20.1";
		private var sTitle:String = "An Odd Space";
		
		private var panelDims:Array = [50,100,400,300];	// x,y,w,h
		private var menuDims:Array = [0,0,100,240];		// x,y,w,h
		private var contentDims:Array = [0,0,252,240];	// x,y,w,h
		
		private var menuItems:Array = ["New Game", "Load Map", "Instructions", "Hardware Test", "Level Editor", "Credits"];
		private var selectedItem:Object;
		
		// These need to be loaded from an external file or something... I pity the fool who has to edit these (me)
		private var sInstructions:String = "Controls:\n\nControl the player ship with the arrow keys. You can target objects with the mouse or the 't' key. Target closest 'enemy' with the 'e' key. Use space to activate modules.\n\nIn the level editor, you can use the arrow keys or the radar overlay to pan around the map. 'r' is a shortcut to rotate the selected object. ";
		private var sCredits:String = 'All actionscript and mxml code was written by me and is released for use under a <a href="http://www.opensource.org/licenses/mit-license.php">MIT license</a>.\n\nAll pictures and models in the \'media\' folder made by me are released under a <a href="http://creativecommons.org/licenses/by-nc-nd/2.5/">Creative Commons attribution nc-nd license</a>.\n\nThe \'Sun Night\' Flex theme is released under a <a href="http://creativecommons.org/licenses/by-nc-nd/2.5/">Creative Commons attribution nc-nd license</a> by Erick Ghaumez - <a href="http://www.scalenine.com">http://www.scalenine.com</a>\n\nThe song, \'Sodium Sonet\', is used with permission from Timothy Lamb - <a href="http://trash80.net">http://trash80.net</a> under a <a href="http://creativecommons.org/licenses/by-nc-nd/2.5/">Creative Commons attribution nc-nd license</a>.\n\nTools used:\n* Adobe Flex SDK - (<a href="http://opensource.adobe.com/wiki/display/flexsdk/">http://opensource.adobe.com/wiki/display/flexsdk/</a>)\n* GIMP - textures and scaling / importing blender renders to .png (<a href="http://www.gimp.org/">http://www.gimp.org/</a>)\n* blender - source files included for the models I\'ve made so far (<a href="http://www.blender.org/>http://www.blender.org/</a>)\n* audacity - trimming and encoding audio to .mp3 (required by flash player - <a href="http://audacity.sourceforge.net/">http://audacity.sourceforge.net/</a>)\n* espeak - TTS engine (<a href="http://espeak.sourceforge.net/">http://espeak.sourceforge.net/</a>)\n* abox - audio synthesizer (<a href="http://www.andyware.com/index.html">http://www.andyware.com/index.html</a>)';
		
		
		//
		///-- Constructor --///
		//
		
		public function appRoot():void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		///-- Data Functions --///
		
		public function dataCallBack(s:String):void {
			//trace(this.oMapList.xmlData);
		}
		
		///-- Display Functions --///
		
		private function loadMenu():void {
			this.oMapList.load();
			
			this.pre = new Panel;
			this.pre.title = this.sTitle;
			this.pre.status = this.sVersion;
			this.pre.y = this.panelDims[1];
			this.pre.width = this.panelDims[2];
			this.pre.height = this.panelDims[3];
			
			this.subWin = new Box();
			this.subWin.direction = "horizontal";
			this.pre.addChild(this.subWin);
			
			this.mainMenu = new List();
			this.mainMenu.width = this.menuDims[2];
			this.mainMenu.height = this.menuDims[3];
			this.mainMenu.dataProvider = this.menuItems;
			this.mainMenu.addEventListener(ListEvent.CHANGE, onMenuChange);
			this.subWin.addChild(this.mainMenu);
			
			this.addChild(this.pre);
		}
		
		private function showMaplist():void {
			var list1:List = new List();
			list1.dataProvider = this.oMapList.xmlData.map;
			list1.width = this.contentDims[2];
			list1.height = this.contentDims[3];
			list1.addEventListener(ListEvent.CHANGE, loadMap);
			this.subWin.addChild(list1);
		}
		
		private function showEditorList():void {
			var list2:List = new List();
			var temp:XML = this.oMapList.xmlData.copy();
			temp.prependChild("<map>New Map</map>");
			var mapList:XMLList = temp.map;
			
			list2.dataProvider = mapList;
			list2.width = this.contentDims[2];
			list2.height = this.contentDims[3];
			list2.addEventListener(ListEvent.CHANGE, loadEditor);
			this.subWin.addChild(list2);
		}
		
		private function showInstructions():void {
			var text1:TextArea = new TextArea();
			text1.width = this.contentDims[2];
			text1.height = this.contentDims[3];
			text1.text = this.sInstructions;
			this.subWin.addChild(text1);
		}
		
		private function showCredits():void {
			var text1:TextArea = new TextArea();
			text1.width = this.contentDims[2];
			text1.height = this.contentDims[3];
			text1.htmlText = this.sCredits;
			this.subWin.addChild(text1);
		}
		
		///-- Event Listeners --///
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.loadMenu();
		}
		
		private function onMenuChange(e:ListEvent):void {
			this.selectedItem = e.target.selectedItem;
			
			if (this.subWin.numChildren > 1) {	// remove the second child (content container)
				this.subWin.removeChildAt(1);
			}
			
			switch (this.selectedItem) {
				case "New Game":
					break;
					
				case "Load Map":
					this.showMaplist();
					break;
					
				case "Instructions":
					this.showInstructions();
					break;
					
				case "Hardware Test":
					break;
				
				case "Level Editor":
					this.showEditorList();
					break;
					
				case "Credits":
					this.showCredits();
					break;
			}
		}
		
		private function loadMap(e:ListEvent):void {
			e.target.removeEventListener(ListEvent.CHANGE, loadMap);
			this.destroy();
			
			// gameloader
			var oGL:gameloader = new gameloader(e.target.selectedItem);
			oGL.addEventListener('gameClosed', onGameClosed);
			this.rawChildren.addChild(oGL);
			this.stage.focus = oGL;				// set input focus to the gamescreen
			
			// User Interface
			var UI:gameUI = new gameUI(oGL);
			UI.width = this.stage.width;		// needed to keep everything centered correctly
			this.addChild(UI);
		}
		
		private function loadEditor(e:ListEvent):void {
			trace(e.target.selectedItem);
		
			e.target.removeEventListener(ListEvent.CHANGE, loadEditor);
			var oEditor:levelEditor = new levelEditor();
			oEditor.addEventListener('editorClosed', onEditorClosed);
			this.stage.addChild(oEditor);
			this.destroy();
		}
		
		private function onGameClosed(e:Event):void {
			var oGL:* = e.target;	// not typed because Event object != :gameloader/display Object
			e.target.removeEventListener('gameClosed', onGameClosed);
			
			// remove gameloader
			this.rawChildren.removeChild(oGL);
			
			// remove gameUI
			this.removeChildAt(this.numChildren - 1);
			
			this.loadMenu();
		}
		
		private function onEditorClosed(e:Event):void {
			e.target.removeEventListener('editorClosed', onEditorClosed);
			this.loadMenu();
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.selectedItem = null;
			this.removeChild(this.pre);
		}
	}
}
