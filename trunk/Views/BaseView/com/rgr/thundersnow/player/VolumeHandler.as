package com.rgr.thundersnow.player{
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.events.EventDispatcher;
	import flash.events.Event;
	
	[Event (type="flash.events.Event" , name="change")]
	
	public class VolumeHandler extends EventDispatcher{

		private var volumeControl:MovieClip;
		
		public function VolumeHandler(clip:MovieClip) 
		{
			volumeControl=clip;
			MovieClip(volumeControl).addEventListener(MouseEvent.MOUSE_DOWN, onMouse);
			MovieClip(volumeControl).addEventListener(MouseEvent.MOUSE_UP, onMouse);
			MovieClip(volumeControl).addEventListener(MouseEvent.MOUSE_MOVE, onMouse);
			MovieClip(volumeControl).addEventListener(MouseEvent.MOUSE_OUT, onMouse);		
		}
		
		public function get volume():Number
		{
			volumeControl.slider.x=volumeControl.slider.x>0?0:volumeControl.slider.x
			volumeControl.slider.x=volumeControl.slider.x<-30?-30:volumeControl.slider.x
			return (volumeControl.slider.x+30)  / 30;
		}
		
		public function set volume(val:Number):void
		{
			volumeControl.slider.x=-30 + (val * 30)
		}
		
		private function onMouse(me:MouseEvent):void
		{
			switch(me.type)
			{
				case MouseEvent.MOUSE_DOWN:
					MovieClip(volumeControl.slider).startDrag();					
					break;
				case MouseEvent.MOUSE_UP:
					MovieClip(volumeControl.slider).stopDrag();
					break;
				case MouseEvent.MOUSE_MOVE:					
					dispatchEvent(new Event(Event.CHANGE));
					break;
				case MouseEvent.MOUSE_OUT:
					MovieClip(volumeControl.slider).stopDrag();
					break;				
			}
					volumeControl.slider.y=0;
					volumeControl.slider.x=volumeControl.slider.x>0?0:volumeControl.slider.x
					volumeControl.slider.x=volumeControl.slider.x<-30?-30:volumeControl.slider.x
		}

	}
	
}
