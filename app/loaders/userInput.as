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
	import flash.ui.Keyboard;
	import flash.display.Stage;
	import flash.display.Sprite;
	
	import app.loaders.gameloader;
	
	public class userInput extends Sprite {
		public var isUserInput:Boolean = true;
		public var oGL:*;		// either gameloader or levelEditor
		
		public var upArrowPressed:Boolean = false;
		public var downArrowPressed:Boolean = false;
		public var leftArrowPressed:Boolean = false;
		public var rightArrowPressed:Boolean = false;
		public var tKeyPressed:Boolean = false;
		public var pKeyPressed:Boolean = false;
		public var eKeyPressed:Boolean = false;
		public var rKeyPressed:Boolean = false;
		public var spacePressed:Boolean = false;
		
		public function userInput():void {
			this.addEventListener(Event.ADDED_TO_STAGE, onStageAdd);
		}
		
		private function onStageAdd(e:Event):void {
			this.removeEventListener(Event.ADDED_TO_STAGE, onStageAdd);
			this.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownPressed);
			this.stage.addEventListener(KeyboardEvent.KEY_UP, keyUpPressed);
			this.stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
		}
		
		public function toggleUserInput():void {
			if (this.isUserInput) {
				this.isUserInput = false;
			} else {
				this.isUserInput = true;
			}
		}
		
		private function mouseWheelHandler(e:MouseEvent):void {
			if (e.delta > 0) {
				this.oGL.pllx.zoomIn();
			} else {
				this.oGL.pllx.zoomOut();
			}
		}
		
		private function keyDownPressed(e:KeyboardEvent):void {
			//trace(e.keyCode);
		
			if (isUserInput) {
				switch (e.keyCode) {
					case Keyboard.UP :
						this.upArrowPressed = true;
						break;
						
					case Keyboard.DOWN :
						this.downArrowPressed = true;
						break;
						
					case Keyboard.LEFT :
						this.leftArrowPressed = true;
						break;
						
					case Keyboard.RIGHT :
						this.rightArrowPressed = true;
						break;
						
					case 82:	// 'r'
						this.rKeyPressed = true;
						break;
						
					case 80:	// 'p'
						this.pKeyPressed = true;
						break;
						
					case 84 :	// 't'
						this.tKeyPressed = true;
						break;
						
					case 69 : 	// 'e'
						this.eKeyPressed = true;
						break;
						
					case Keyboard.SPACE :
						this.spacePressed = true;
						break;
				}
			}
		}
		
		private function keyUpPressed(e:KeyboardEvent):void {
			switch (e.keyCode) {
				case Keyboard.UP :
					this.upArrowPressed = false;
					break;
					
				case Keyboard.DOWN :
					this.downArrowPressed = false;
					break;
					
				case Keyboard.LEFT :
					this.leftArrowPressed = false;
					break;
					
				case Keyboard.RIGHT :
					this.rightArrowPressed = false;
					break;
				
				case 82:	// 'r'
					this.rKeyPressed = false;
					break;
					
				case 80:	// 'p'
					this.pKeyPressed = false;
					break;
					
				case 84 :	// 't'
					this.tKeyPressed = false;
					break;
					
				case 69 : 	// 'e'
					this.eKeyPressed = false;
					break;
					
				case Keyboard.SPACE :
					this.spacePressed = false;
					break;
			}
		}
		
		///-- destructor --///
		
		public function destroy():void {
			this.stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownPressed);
			this.stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpPressed);
			this.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelHandler);
			this.parent.removeChild(this);
		}
	}
}