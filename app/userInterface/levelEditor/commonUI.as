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

private var txtColor:uint = 0xFFFFFF;
private var lineStyle:Array = new Array(1,0xFFFFFF);
private var fillStyle:Array = new Array(0xFF0000, 0.25);
private var fillStyle2:Array = new Array(0x00FF00, 0.25);
private var lineHeight:uint = 20;
private var iWidth:int = 200;
private var iHeight:int = 599;
private var subWin:Sprite;

///-- common functions --///

private function isArray(obj:*):Boolean {
	try {
		typeof obj[0];
		return true;
	} catch (e:Error) {
		return false;
	}
	
	return false;
}

private function drawSubWindow(w:int = 200, h:int = 600, xOffset:int = 0, yOffset:int = 0):void {
	try {
		for (var i:int = 0, len:int = this.subWin.numChildren; i < len; i++) {
			this.subWin.removeChildAt(i);
		}
		this.subWin.graphics.clear();
		this.removeChild(this.subWin);
		this.subWin = null;
	} catch (e:Error) {
		//trace("subWindow not present");
	}
	
	this.subWin = new Sprite();
	
	// kindof hackish
	this.subWin.x = xOffset;
	this.subWin.y = yOffset;
	var subHeight:uint = h - yOffset;
	
	this.subWin.graphics.lineStyle(this.lineStyle[0], this.lineStyle[1]);
	this.subWin.graphics.beginFill(this.fillStyle2[0], this.fillStyle2[1]);
	this.subWin.graphics.drawRect(0, 0, w, subHeight);
	this.subWin.graphics.endFill();
	this.addChild(subWin);
}

private function drawButton(s:String, txtWidth:int = 100, xOffset:int = 0, yOffset:int = 0):Sprite {
	var line:Sprite = new Sprite();
	var txt:TextField = this.drawText(s, txtWidth);
	line.addChild(txt);
	line.x = xOffset;
	line.y = yOffset;
	return line;
}

private function drawText(s:String, txtWidth:int = 100, xOffset:int = 0, yOffset:int = 0):TextField {
	var txt:TextField = new TextField();
	txt.width = txtWidth;
	txt.height = this.lineHeight;
	txt.textColor = this.txtColor;
	txt.text = s;
	txt.x = xOffset;
	txt.y = yOffset;
	return txt;
}

// eventually needs a wrapping algorithm
private function drawTextBox(s:String, txtWidth:int = 100, txtHeight:int = 100, xOffset:int = 0, yOffset:int = 0):TextField {
	var txt:TextField = new TextField();
	txt.width = txtWidth;
	txt.height = txtHeight;
	txt.textColor = this.txtColor;
	txt.text = s;
	txt.x = xOffset;
	txt.y = yOffset;
	return txt;
}

private function drawTable(a:Array, tblWidth:int, rowHeight:int):Sprite {		// a needs to be a 2-dimensional array :: [[col1, col2][row2]]
	var table:Sprite = new Sprite();
	var lineArray:Array = new Array();
	var columnLength:int = 0;
	
	// loop once to get the longest row
	for (var i:int = 0, len:int = a.length; i < len; i++) {
		if (a[i].length > columnLength) {
			columnLength = a[i].length;
		}
	}
	
	var columnWidth:int = Math.floor(tblWidth / columnLength);
	
	// now loop to draw the textFields
	for (var row:int = 0, rowLen:int = a.length; row < rowLen; row++) {
		for (var col:int = 0, colLen:int = a[row].length; col < colLen; col++) {
			var t:TextField = this.drawText(a[row][col], columnWidth, columnWidth * col);
			t.y = row * rowHeight;
			table.addChild(t);
		}
	}
	
	return table;
}

private function drawList(a:Array, eventListener:Function = null, listWidth:int = 100, rowHeight:int = 20):Sprite {	// a is a one dimensional list
	var list:Sprite = new Sprite();
	
	for (var i:uint = 0, len:uint = a.length; i < len; i++) {
		var b:Sprite = this.drawButton(a[i], listWidth, 0, i * rowHeight);
		
		if (eventListener != null) {
			b.addEventListener(MouseEvent.CLICK, eventListener);
		}
		
		list.addChild(b);
	}
	
	return list;
}
