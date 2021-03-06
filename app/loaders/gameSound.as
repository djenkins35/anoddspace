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
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	
	import app.loaders.gameloader;
	
	public class gameSound extends Object {
		private var oGL:gameloader;
		private var playerShip:Object;	// referenced here to be able to remove event listeners even if the gameloader's playership changes
		public var isSound:Boolean = true;	// public for use in gameOptionsUI
		private var isHit:Boolean = false;
		private var isMiningSound:Boolean = false;
		private var isLaserSound:Boolean = false;
		private var isThrust:Boolean = false;
		
		private var mainChannel:SoundChannel = new SoundChannel();
		private var shipChannel:SoundChannel = new SoundChannel();
		private var thrustChannel:SoundChannel = new SoundChannel();
		private var hitChannel:SoundChannel = new SoundChannel();
		private var mainTransform:SoundTransform = new SoundTransform(0.3);
		private var laserTransform:SoundTransform = new SoundTransform(0.1);
		private var hitTransform:SoundTransform = new SoundTransform(0.3);
		
		private var soundDir:String;	// retreived from oGL.soundDir
		private var thrustSoundURL:String 		= "/thrust.mp3";
		private var hitSoundURL:String 			= "/hitSoft.mp3";
		private var laserSoundURL:String 		= "/laserFire1.mp3";
		private var boomSoundURL:String 		= "/explosion.mp3";
		private var shieldWarningURL:String 	= "/shieldCritical.mp3";
		private var miningSoundURL:String 		= "/miningLaser01.mp3";
		
		private var thrustSound:Sound;
		private var hitSound:Sound;
		private var laserSound:Sound;
		private var boomSound:Sound;
		private var shieldWarning:Sound;
		private var miningSound:Sound;
		
		
		//
		///-- Constructor --///
		//
		
		public function gameSound(oGL:gameloader):void {
			this.oGL = oGL;
			this.playerShip = this.oGL.playerShip;
			this.loadSounds();
			
			this.oGL.addEventListener('SoundOn', toggleSound);
			this.oGL.addEventListener('SoundOff', toggleSound);
			
			// add listeners for only the player's ship
			this.oGL.playerShip.addEventListener('flameOn', playThrust);
			this.oGL.playerShip.addEventListener('flameOff', killThrust);
		}
		
		//
		///-- Private Methods --///
		//
		
		private function loadSounds():void {
			this.soundDir 		= this.oGL.soundDir;
			this.thrustSound 	= new Sound(new URLRequest(this.soundDir + this.thrustSoundURL));
			this.hitSound 		= new Sound(new URLRequest(this.soundDir + this.hitSoundURL));
			this.laserSound 	= new Sound(new URLRequest(this.soundDir + this.laserSoundURL));
			this.boomSound 		= new Sound(new URLRequest(this.soundDir + this.boomSoundURL));
			this.shieldWarning	= new Sound(new URLRequest(this.soundDir + this.shieldWarningURL));
			this.miningSound 	= new Sound(new URLRequest(this.soundDir + this.miningSoundURL));
		}
		
		/*private function playSound(s:String, p:String):void {
		
			switch (p) {
				case "play":
					if (!this.isThrust) {
						trace('flameon');
						this.thrustChannel = null;
						this.thrustChannel = this.thrustSound.play(0, 0);
						this.isThrust = true;
						//this.thrustChannel.soundTransform = this.mainTransform;
					}
				
					break;
					
				case "stop":
					this.isThrust = false;
					break;
			
			}
			
			if (this.isSound) {
				switch (p) {
					case "play" :
						switch (s) {
							case "hitSound" :
								if (!isHit) {
									this.hitChannel = this.hitSound.play(0, 0);
									this.hitChannel.soundTransform = this.hitTransform;
									this.isHit = true;
								}
								
								break;
								
							case "laserSound" :
								if (!this.isLaserSound) {
									this.isLaserSound = true;
									this.shipChannel = null;
									this.shipChannel = this.laserSound.play(0, 0);
									this.shipChannel.soundTransform = this.laserTransform;
									this.shipChannel.addEventListener(Event.SOUND_COMPLETE, laserComplete);
								}
								break;
								
							case "thrustSound" :
								if (!this.isThrust) {
									trace('hey');
									this.thrustChannel = null;
									this.thrustChannel = this.thrustSound.play(0, 0);
									this.isThrust = true;
									//this.thrustChannel.soundTransform = this.mainTransform;
								}
								break;
								
							case "boomSound" :
								this.shipChannel = null;
								this.shipChannel = this.boomSound.play(0, 0);
								break;
								
							case "shieldWarning" :
								this.mainChannel = null;
								this.mainChannel = this.shieldWarning.play(0, 0);
								break;
								
							case "miningLaser" :
								if (!this.isMiningSound) {
									this.isMiningSound = true;
									this.mainChannel = null;
									this.mainChannel = this.miningSound.play(0, 1000);
									this.mainChannel.soundTransform = this.laserTransform;
								}
								break;
						}
						
						break;
					
					case "stop" :
						switch (s) {
							case "thrustSound" :
								if (this.thrustChannel != null) {
									this.thrustChannel.stop();
									this.thrustChannel = null;
								}
								this.isThrust = false;
								
								break;
								
							case "hitSound" :
								break;
								
							case "laserSound" :
								break;
								
							case "boomSound" :
								break;
								
							case "shieldWarning" :
								break;
								
							case "miningLaser" :
								if (this.mainChannel != null) {
									this.mainChannel.stop();
									this.mainChannel = null;
								}
								
								this.isMiningSound = false;
								break;
						}
					
						break;
				}
			}
			
			
		}*/
		
		/*private function killSounds():void {
			this.playSound('hitSound', 'stop');
			this.playSound('laserSound', 'stop');
			this.playSound('thrustSound', 'stop');
			this.playSound('boomSound', 'stop');
			this.playSound('shieldWarning', 'stop');
			this.playSound('miningSound', 'stop');
		}*/
		
		//
		///-- Event Listeners --///
		//
		
		private function toggleSound(e:Event):void {
			if (this.isSound == true) {
				if (this.mainChannel != null) {		// hack for miningSound bug @ miningLaser.as::mineTarget()
					this.mainChannel.stop();
					this.mainChannel = null;
				}
				
				//this.killSounds();
				this.isSound = false;
			} else {
				this.isSound = true;
			}
		}
		
		private function laserComplete(e:Event):void {
			this.shipChannel.removeEventListener(Event.SOUND_COMPLETE, laserComplete);
			this.isLaserSound = false;
		}
		
		
		// testing
		private function playThrust(e:Event):void {
			if (!this.isThrust) {
				if (this.isSound) {
					this.thrustChannel = this.thrustSound.play(0, 1000);
					this.isThrust = true;
					this.thrustChannel.soundTransform = this.mainTransform;
				}
			}
		}
		
		private function killThrust(e:Event):void {
			if (this.isThrust) {
				if (this.thrustChannel != null) {
					this.thrustChannel.stop();
					this.thrustChannel = null;
				}
				
				this.isThrust = false;
			}
		}
		
		//
		///-- Destructor --///
		//
		
		public function destroy():void {
			this.oGL.removeEventListener('SoundOn', toggleSound);
			this.oGL.removeEventListener('SoundOff', toggleSound);
			this.oGL.playerShip.removeEventListener('flameOn', playThrust);
			this.oGL.playerShip.removeEventListener('flameOff', killThrust);
			
			this.mainChannel = null;
			this.shipChannel = null;
			this.thrustChannel = null;
			this.hitChannel = null;
			this.mainTransform = null;
			this.laserTransform = null;
			this.hitTransform = null;
			
			this.thrustSound = null;
			this.hitSound = null;
			this.laserSound = null;
			this.boomSound = null;
			this.shieldWarning = null;
		}
	}
}