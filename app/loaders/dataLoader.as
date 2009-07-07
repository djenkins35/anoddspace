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
	import flash.net.URLRequest;
	import flash.net.URLLoader;
	
	public class dataLoader extends Object {
		private var xmlLoader:URLLoader = new URLLoader();
		public var xmlData:XML = new XML();
		public var dataURL:String = '';
		public var callBack:String = '';
		public var oGL:*;				// gameloader
		
		public function dataLoader(dataURL:String, callBack:String, oGL:*):void {
			this.dataURL = dataURL;
			this.callBack = callBack;
			this.oGL = oGL;
		}
		
		public function load():void {
			this.xmlLoader.addEventListener("complete", onDataLoaded);
			
			if (this.dataURL != '' && this.callBack != '' && this.oGL != null) {
				this.xmlLoader.load(new URLRequest(this.dataURL));
			} else {
				trace('missing input to dataLoader');
			}
		}
		
		private function onDataLoaded(e:Event):void {
			this.xmlData = XML(this.xmlLoader.data);
			this.oGL.dataCallBack(this.callBack);
		}
		
		///-- destructor --///
		
		public function destroy():void {
			this.xmlLoader.removeEventListener("complete", onDataLoaded);
		}
	}
}