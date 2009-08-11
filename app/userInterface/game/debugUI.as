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
	import flash.utils.Timer;
	import flash.system.*;
	
	import mx.containers.Canvas;
	import mx.controls.TextArea;
	
	import app.loaders.gameloader;
			
	public class debugUI extends Canvas {
		
		// Data Properties
		private var oGL:Object;
		private var frameCounter:Number = 0;
		private var frameTimer:Timer = new Timer(1000, 0);
		private var frameRate:int;	// frames per second
		private var targetRef:Object;	// reference to the first object in 'oGL.playerTargetArray'
		
		// Display Properties
		private var debugDims:Array = [250, 175];	// width, height
		private var textBox:TextArea = new TextArea();
		
		//
		///-- Constructor --///
		//
		
		public function debugUI(oGL:gameloader):void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.oGL = oGL;
			this.textBox.width = this.debugDims[0];
			this.textBox.height = this.debugDims[1];
		}
		
		///-- Event Listeners --///
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.addChild(this.textBox);
			this.frameTimer.addEventListener(TimerEvent.TIMER, getFrameRate);
			this.frameTimer.start();
		}
		
		private function getFrameRate(e:TimerEvent):void {
			this.frameRate = this.frameCounter;
			this.frameCounter = 0;
		}
		
		private function onEnterFrame(e:Event):void {
			this.frameCounter++;
			this.targetRef = this.oGL.playerTargetArray[0];
			
			this.textBox.text = "*Debug*";
			this.textBox.text += "\n" + this.frameRate + " FPS";
			this.textBox.text += "\nMemory Used: " + Math.round(System.totalMemory / 1048576) + "MB";
			this.textBox.text += "\nObject Array Length: " + this.oGL.objectArray.length;
			
			
			if (targetRef != null && this.oGL.objectArray.indexOf(targetRef) != -1) {
				this.textBox.text += "\n\n*Current Target*"
				this.textBox.text += "\n" + this.targetRef.name;
				this.textBox.text += "\nObject Array Index: " + this.targetRef.indx;
				if (targetRef.hasOwnProperty('isHostile')) {this.textBox.text += "\nisHostile: " + targetRef.isHostile};
				if (targetRef.hasOwnProperty('AI')) {this.textBox.text += "\nCurrent Action: " + targetRef.AI.curAction};
			}
		}
		
		///-- Destructor --///
		
		public function destroy():void {
			this.frameTimer.stop();
			this.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			this.frameTimer.removeEventListener(TimerEvent.TIMER, getFrameRate);
			this.parent.removeChild(this);
		}
	}
}
