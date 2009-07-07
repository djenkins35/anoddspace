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
	import flash.text.*;
	import flash.events.*;
	import flash.display.*
	import flash.utils.Timer;
	import flash.geom.*;
	import flash.net.URLRequest;
	import flash.system.System;
	
	import app.userInterface.levelEditor.radarUI;
	import app.userInterface.levelEditor.objectEditorUI;
	import app.baseClasses.realMover;
	import app.loaders.gameloader;
	import app.loaders.levelEditor;
	import app.loaders.imageLoader;
	import app.baseClasses.starBase;
	
	
	public class levelEditorUI extends Sprite {
		include "commonUI.as";							// common UI drawing functions
		private const ninety:Number = Math.PI / 2;
		private var editor:levelEditor;
		
		private var subWindowWidth:int = 200;
		private var subWindowHeight:int = 600;
		
		private var imageScale:uint = 50;
		private var imageDir:String = "app/media/images/";
		private var mainMenuText:Array = ["Back To Menu", "Add Objects", "Edit Map Details", "Save to Clipboard", "Open Map"];
		private var objectCategories:Array = ["Stationary", "Starbases", "Asteroids", "Ships", "Presets"];
		private var editFunctions:Array = ["Rotate", "Edit Specs", "Delete", "Save as Preset"];
		private var buttonArr:Array = new Array();			// main window buttons
		private var objectList:Array;						// holds xmlData for each item in selected category
		private var targetBox:Sprite;
		private var tbDims:Array = [599,0,200,100];			// x,y,width,height for 'targetBox'
		private var reticule:Sprite = new Sprite();			// box around the 'selected' object
		private var dragCircle:Sprite = new Sprite();		// used to edit an object's rotation
		public var selectedObj:*;							// public for use by objectEditor.as
		private var pGlobal:Point = new Point();			// for globalToLocal
		private var pLocal:Point = new Point();				// for localToGlobal
		private var radar:radarUI;
		private var OAIndex:int = 0;						// index for the object array, incremented when dragging a new object to the map
		private var objEditor:objectEditorUI = new objectEditorUI(XML(''), null);		// hackish
		private var isCopied:Boolean = false;
		private var xPresetData:XML = new XML("<presets></presets>");
		
		///-- constructor --///
		
		public function levelEditorUI(editor:levelEditor):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.editor = editor;	
		}
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.loadUI();
			
			// radar
			this.radar = new radarUI(this.editor)
			this.addChild(this.radar);
			this.radar.drawPanOverlay();
		}
		
		///-- drawing stuff --///
		
		private function loadUI():void {
			// left box
			this.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.graphics.beginFill(this.fillStyle[0], this.fillStyle[1]);
			this.graphics.drawRect(0,0,this.iWidth,this.iHeight);
			this.graphics.endFill();
			
			// main menu
			var menuContainer:Sprite = this.drawList(this.mainMenuText, mainMenuHandler);
			this.addChild(menuContainer);
			
			// draw targetBox
			this.drawTargetBox();
		}
		
		private function drawTargetBox():void {
			try { 
				this.removeChild(this.targetBox);
				this.targetBox = null;
			} catch (e:Error) {}
			
			this.targetBox = new Sprite();
			this.targetBox.x = this.tbDims[0];
			this.targetBox.y = this.tbDims[1];
			this.targetBox.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			this.targetBox.graphics.beginFill(this.fillStyle[0], this.fillStyle[1]);
			this.targetBox.graphics.drawRect(0,0,this.tbDims[2],this.tbDims[3]);
			this.targetBox.graphics.endFill();
			this.addChild(this.targetBox);
		}
		
		private function drawReticule(oTarget:Object):void {	// needs cleaning
			this.reticule.graphics.clear();
			this.reticule.graphics.lineStyle(1, 0xFFFF00, 1);
			this.reticule.graphics.drawRect(0,0,50,50);
			this.reticule.x = oTarget.x - 25;
			this.reticule.y = oTarget.y - 25;
			this.editor.gamescreen.addChild(this.reticule);
		}
		
		public function drawRotationCircle():void {
			// draw a circle around the object to indicate where to drag
			// get the largest of target width or height to use as radius
			
			if (this.selectedObj != null) {
				if (!this.editor.contains(this.dragCircle)) {
					var radius:Number = 0;
					
					if (this.selectedObj.width >= this.selectedObj.height) {
						radius = this.selectedObj.width;
					} else {
						radius = this.selectedObj.height;
					}
					
					this.editor.gamescreen.addChild(dragCircle);
					this.dragCircle.x = this.selectedObj.x;
					this.dragCircle.y = this.selectedObj.y;
					this.dragCircle.graphics.clear();
					this.dragCircle.graphics.lineStyle(this.lineStyle[0],this.lineStyle[1]);
					this.dragCircle.graphics.beginFill(this.fillStyle[0], 0.1);
					this.dragCircle.graphics.drawCircle(0, 0, radius);
					this.dragCircle.graphics.endFill();
					
					this.dragCircle.addEventListener(MouseEvent.MOUSE_DOWN, startRotation);
				}
			}
		}
		
		///-- data --///
		
		private function saveToClipBoard():void {
			var s:String = "<?xml version=\"1.0\"?>\n\n<mapObjects>\n\n";
		
			for each (var obj:XML in this.editor.objectArray) {
				s += obj + "\n\n";
			}
			
			s += "</mapObjects>";
			System.setClipboard(s);
		}
		
		private function editObjectSpecs():void {
			if (!this.contains(this.objEditor)) {
				this.objEditor = null;
				this.objEditor = new objectEditorUI(XML(this.selectedObj.details), this.editor);
				this.addChild(this.objEditor);
			}
		}
		
		private function updatePos(obj:Object, pos:Array):void {
			var xData:XML = XML(obj.details);
			xData.position = <position>{pos[0]},{pos[1]}</position>;
			obj.details = xData
			
			// write data to the objectArray
			this.editor.updateObjectArray(xData);
			
			// update the radar
			this.radar.calculateRadar();
		}
		
		private function updateRotation():void {
			var xData:XML = XML(this.selectedObj.details);
			xData.rotation = <rotation>{this.selectedObj.rotation}</rotation>
			this.selectedObj.details = xData;
			
			this.editor.updateObjectArray(xData);
		}
		
		private function getVector(dx:Number, dy:Number):Number {	// pilfered from artificialIgnorance.as rather than importing that whole class
			var vector:Number = 0;
			
			if (dx == 0) {
				if (dy <= 0) {
					vector = 0;
				} else {
					vector = Math.PI;
				}
			} else {
				if (dy == 0) {
					if (dx > 0) {
						vector = ninety;
					} else {
						vector = -ninety;
					}
				} else {
					if (dx > 0) {
						if (dy > 0) {
							vector = ninety + Math.atan(dy / dx);
						} else {
							vector = -Math.atan(dx / dy);
						}
					} else {
						if (dy > 0) {
							vector = -ninety + Math.atan(dy / dx);
						} else {
							vector = -Math.atan(dx / dy);
						}
					}
				}
			}
			
			return vector;
		}
		
		///-- event handlers --///
		
		// lists
		
		private function mainMenuHandler(e:MouseEvent):void {
			switch (e.target.text) {
				case "Back To Menu" :
					this.editor.closeEditor();
					break;
					
				case "Add Objects" :
					this.drawSubWindow(this.subWindowWidth, this.subWindowHeight, 0, this.mainMenuText.length * this.lineHeight);
					var catList:Sprite = this.drawList(this.objectCategories, showObjects);	// showObjects is the event listener for mouseclicks
					this.subWin.addChild(catList);
					break;
				
				case "Edit Map Details" :
				
					break;
				
				case "Save to Clipboard" :
					this.saveToClipBoard();
					break;
				
				case "Open Map" :
				
					break;
			}
		}
		
		private function showObjects(e:MouseEvent):void {	// needs cleaning
			try { this.subWin.removeChildAt(1); } catch (e:Error) {}
		
			this.objectList = new Array();
			var container:Sprite = new Sprite();				// container for images and text
			container.graphics.clear();
			
			///-- this needs to be cleaned up ---///
			container.y = this.objectCategories.length * this.lineHeight + this.lineHeight;
			container.x = 5;
			container.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
			container.graphics.moveTo(-5,-this.lineHeight);
			container.graphics.lineTo(this.subWin.width - 5,-this.lineHeight);
			///--- ---///
			
			var xObj:XMLList;
			
			switch (e.target.text) {
				case "Stationary" :
					xObj = this.editor.oMapObjects.xmlData.playerStart;
					xObj += this.editor.oMapObjects.xmlData.hangers.hanger;
					break;
					
				case "Starbases" :
					xObj = this.editor.oMapObjects.xmlData.starBases.starBase;
					break;
					
				case "Asteroids" :
					xObj = this.editor.oMapObjects.xmlData.asteroids.asteroid;
					break;
					
				case "Ships" :
					xObj = this.editor.oShipData.xmlData.ship;
					break;
					
				case "Presets" :
					xObj = this.xPresetData.*;
					
					
					break;
			}
			
			var i:uint = 0;	// for the y offset
			
			for each (var xItem:XML in xObj) {
				var pic:imageLoader = new imageLoader(this.imageDir + xItem.imageURL);
				pic.details = xItem;
				
				// scale image once it's loaded (sent via custom event dispatcher in imageLoader)
				pic.addEventListener('imageLoaded', scaleImageDimensions);
				
				// listener for dragging to map
				pic.addEventListener(MouseEvent.MOUSE_DOWN, dragToMap);
				
				// position each image under the previous image
				pic.y = i * (this.imageScale + this.lineHeight);
				
				// show the name under the picture
				var picText:TextField = this.drawText(xItem.name);
				picText.y = i * (this.imageScale + this.lineHeight) + this.imageScale;
				
				container.addChild(pic);
				container.addChild(picText);
				this.subWin.addChild(container);
				
				i++;
			}
		}
		
		private function scaleImageDimensions(e:Event):void {
			e.target.removeEventListener('imageLoaded', scaleImageDimensions);
			
			if (e.target.height > this.imageScale) {
				e.target.scaleX = e.target.scaleY = this.imageScale / e.target.height;
			}
		}
		
		// moving
		
		private function dragToMap(e:MouseEvent):void {
			var xData:XML = XML(e.target.details);
			var pic:imageLoader = new imageLoader(this.imageDir + xData.imageURL, true);
			
			// add an index for the objectArray
			xData.OAIndex = <OAIndex>{this.OAIndex}</OAIndex>;
			this.OAIndex++;
			pic.details = xData;
			
			// map to local coordinates
			this.pGlobal.x = e.stageX;
			this.pGlobal.y = e.stageY;
			this.pLocal = this.editor.gamescreen.globalToLocal(this.pGlobal);
			pic.x = pLocal.x;
			pic.y = pLocal.y;;
			
			this.editor.gamescreen.addChild(pic);
			pic.addEventListener(MouseEvent.MOUSE_UP, dropObject);
			pic.startDrag();
		}
		
		private function dropObject(e:MouseEvent):void {
			// have to listen on the parent because of the offset sprite :(
			e.target.parent.removeEventListener(MouseEvent.MOUSE_UP, dropObject);
			e.target.parent.stopDrag();
			this.updatePos(e.target.parent, [e.target.parent.x,e.target.parent.y]);
			
			// add event listener for editing after the drop
			if (!e.target.parent.hasEventListener(MouseEvent.MOUSE_DOWN)) {
				e.target.parent.addEventListener(MouseEvent.MOUSE_DOWN, selectObject);
			} else {
				this.drawReticule(e.target.parent);
			}
		}
		
		// editing
		
		private function selectObject(e:MouseEvent):void {
			this.selectedObj = e.target.parent;
			this.drawReticule(e.target.parent);
			
			// bring object to the front of the display list
			this.editor.gamescreen.setChildIndex(this.selectedObj, this.editor.gamescreen.numChildren - 1);
			
			// update the target box info
			this.drawTargetBox();
			
			// show the target name
			var targetName:* = XML(this.selectedObj.details).name;		// throws an error if you cast to string
			this.targetBox.addChild(this.drawText(targetName));
			
			// show the edit options
			var editMenu:Sprite = this.drawList(this.editFunctions, editSelected);
			editMenu.y = this.lineHeight;
			this.targetBox.addChild(editMenu);
			
			this.selectedObj.addEventListener(MouseEvent.MOUSE_UP, dropObject);
			this.selectedObj.startDrag();
		}
		
		private function editSelected(e:MouseEvent):void {
			switch (e.target.text) {
				case "Rotate" :
					this.drawRotationCircle();
					break;
					
				case "Edit Specs" :
					this.editObjectSpecs();
					break;
					
				case "Delete" :
					this.reticule.graphics.clear();
					this.editor.gamescreen.removeChild(this.selectedObj);
					this.editor.deleteObj(XML(this.selectedObj.details));
					this.drawTargetBox();
					break;
				
				case "Save as Preset" :
					var xTest:XML = XML(this.selectedObj.details);
					this.xPresetData.appendChild(xTest);
					break;
			}
		}
		
		// rotation
		
		private function startRotation(e:MouseEvent):void {
			e.target.removeEventListener(MouseEvent.MOUSE_DOWN, startRotation);
			e.target.addEventListener(MouseEvent.MOUSE_MOVE, dragRotation);
			e.target.addEventListener(MouseEvent.MOUSE_UP, stopRotation);
		}
		
		private function dragRotation(e:MouseEvent):void {
			var p1:Point = new Point;
			p1.x = e.target.x;
			p1.y = e.target.y;
			var p2:Point = this.editor.gamescreen.localToGlobal(p1);
			
			var dx:Number = e.stageX - p2.x;
			var dy:Number = e.stageY - p2.y;
			this.selectedObj.rotation = this.getVector(dx,dy) * 180 / Math.PI;
		}
		
		private function stopRotation(e:MouseEvent):void {
			e.target.removeEventListener(MouseEvent.MOUSE_MOVE, dragRotation);
			e.target.removeEventListener(MouseEvent.MOUSE_UP, stopRotation);
			this.editor.gamescreen.removeChild(this.dragCircle);
			
			this.updateRotation();
		}
		
		///-- destructor --///
		
		public function destroy():void {	// need to loop through the event listeners here too
			this.graphics.clear();
			this.parent.removeChild(this);
		}
	}
}
