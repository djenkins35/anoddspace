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
	import flash.net.URLRequest;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.*;
	import flash.text.*;

	public class imageLoader extends Sprite {
		private var txtColor:uint = 0xFFFFFF;
	
		private var loader:Loader = new Loader;
		private var progressText:TextField = new TextField();
		public var details:String;								// useful to set details for click events
		private var isOffset:Boolean = false;						// whether or not to center the image to 0,0
		
		public function imageLoader(sURL:String, isOffset:Boolean = false):void {
			this.progressText.textColor = this.txtColor;
			this.isOffset = isOffset;
			this.loader.contentLoaderInfo.addEventListener(Event.OPEN, imageOpened);
			this.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, imageLoaded);
			this.loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, updateProgress);
			this.loader.load(new URLRequest(sURL));
		}
		
		private function imageOpened(e:Event):void {
			this.loader.contentLoaderInfo.removeEventListener(Event.OPEN, imageOpened);
			this.addChild(this.progressText);
		}
		
		private function updateProgress(e:ProgressEvent):void {
			var pgText:String = e.bytesLoaded / e.bytesTotal + "%";
			this.progressText.text = pgText;
			this.progressText.autoSize = TextFieldAutoSize.LEFT;
		}
		
		private function imageLoaded(e:Event):void {
			this.loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, imageLoaded);
			this.loader.contentLoaderInfo.removeEventListener(ProgressEvent.PROGRESS, updateProgress);
			this.removeChild(this.progressText);
			this.progressText = null;
			
			// center image to 0,0
			// place at the bottom of display list
			if (this.isOffset) {
				var offsetSprite:Sprite = new Sprite();
				offsetSprite.x = -this.loader.width / 2;
				offsetSprite.y = -this.loader.height / 2;
				offsetSprite.addChild(loader.content);
				this.addChildAt(offsetSprite, 0);
			} else {
				this.addChildAt(this.loader.content, 0);
			}
			
			this.loader = null;
			
			// let whatever called us know that we're done
			// useful for getting the image dimensions
			this.dispatchEvent(new Event('imageLoaded'));
		}
	}
}