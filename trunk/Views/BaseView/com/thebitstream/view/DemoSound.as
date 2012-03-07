package com.thebitstream.view {
	import com.rgr.thundersnow.player.VolumeHandler;
	import flash.display.MovieClip;
	import flash.display.DisplayObject;
	import com.thebitstream.control.IControl;
	import flash.text.TextField;
	import fl.controls.Slider;
	import fl.events.SliderEvent;
	
	import flash.events.MouseEvent;
	import fl.controls.ProgressBar;
	import flash.display.SimpleButton;
	import flash.events.Event;
	
	public class DemoSound extends MovieClip implements IProject {
		
		private var presentation:DisplayObject;
		private var playerControl:IControl;
		private var slider:Slider;
		private var meta:Object={};
		private var pWidth:Number=360;
		private var pHeight:Number=240;
		private var volumeHander:VolumeHandler;
		public function DemoSound()
		{
			
			btnNext.addEventListener(MouseEvent.CLICK, onClickNext);
			btnPause.addEventListener(MouseEvent.CLICK, onClickPause);
			btnPrev.addEventListener(MouseEvent.CLICK, onClickPrev);
			btnStop.addEventListener(MouseEvent.CLICK, onClickStop);
			btnPlay.addEventListener(MouseEvent.CLICK, onClickPlay);
			txtHtml.htmlText="<a href='http://thundersnow.thebitstream.com' target='_info'>Project Thunder Snow</a>"
			txtDesc.text="";
			txtName.text="";
			txtTime.selectable=false;			
			volumeHander=new VolumeHandler(volumeControl);
			volumeHander.addEventListener(Event.CHANGE, onVolume);
		}
		
		private function onVolume(e:Event):void
		{
			if(playerControl)
			playerControl.volume=volumeHander.volume;
		}
		

		
		/**
		 * Name of class.
		 * @return 
		 * 
		 */		
		public function get type():String
		{
			return "DemoView";
		}
		
		/**
		 * Sets the provider object.
		 * <p> The projector should show the displayobject from Point(0,0) to Point(providerWidth,providerHeight).GUI elements should be resized or moved according to presentation size.</p> 
		 * @param prov
		 * 
		 */		
		public function set provider(prov:DisplayObject):void
		{
			presentation=prov;
			//presentation.x=360/2 - pWidth/2
			//add to the screen layer if video
			//addChild(presentation);
		}
		
		/**
		 * Sets the reported width of the presentation visual data. 
		 * @param val
		 * 
		 */		
		public function set providerWidth(val:Number):void
		{
			pWidth=val;
			if(val){
				if(presentation)
				presentation.x=360/2 - pWidth/2
			}
		}
		
		/**
		 * Sets the reported height of the presentation visual data. 
		 * @param val
		 * 
		 */			
		public function set providerHeight(val:Number):void
		{
			pHeight=val;
			if(val){
				if(presentation)
				presentation.y=240/2 - pHeight/2
			}
		}
		
		/**
		 * Sets the current presentation play-head stream time in seconds. 
		 * @param val
		 * 
		 */		
		public function set time(val:Number):void
		{

			var seconds:int= val%60;
			var minutes:int=val/60;
			var hours:int=minutes/60;
			
			txtTime.text=(hours.toString().length<2?"0"+hours.toString():hours.toString())
			+":"+(minutes.toString().length<2?"0"+minutes.toString():minutes.toString())
			+":"+(seconds.toString().length < 2 ?"0"+seconds.toString()  :seconds.toString());

		}
		
		/**
		 * Sets the reported progress of the data that has been read into flv format. 
		 * @param val 0 to 1;
		 * 
		 */		
		public function set parsingProgress(val:Number):void
		{
			var prog:ProgressBar=pgbParse;
			prog.setProgress(val,1);
		}
		
		/**
		 * Sets the reported progress of the tcp stream being read into the parsing buffer. 
		 * @param val 0 to 1
		 * 
		 */		
		public function set rawProgress(val:Number):void
		{
			var prog:ProgressBar=pgbRaw;
			prog.setProgress(val,1);		
		}
		
		/**
		 * Sets the reported current play back shuttle position in the stream.
		 * <p>Non-seekable live or file streams may not indicate a position</p> 
		 * @param val 0 to 1
		 * 
		 */		
		public function set position(val:Number):void
		{
			
		}
		
		/**
		 * Sets if the current presentation can seek. 
		 * @param val 
		 * 
		 */		
		public function set canSeek(val:Boolean):void
		{
			
		}
		
		/**
		 * Sets the controller client for current presentation play/pause/seek/next control. 
		 * @param val
		 * 
		 */		
		public function set controlClient(val:IControl):void
		{
			playerControl=val;
			playerControl.volume=volumeHander.volume;
		}
		
		/**
		 * Sets the metadata for the current presentation. 
		 * @param val
		 * 
		 */		
		public function set metaData(val:Object):void
		{
			trace("Metadata : ");
			for(var prop:String in val)
			{
				trace('\t',prop,':',val[prop])
			}	
			if(val.url && val.url.length && val.name && val.name.length)
			txtHtml.htmlText="<a href='"+val.url+"' target='_info'>"+val.name+"</a>"
			
			if(val.StreamTitle && val.StreamTitle.length){
				val.StreamTitle=String(val.StreamTitle).replace("`","");
				val.StreamTitle=String(val.StreamTitle).replace("'","");
				txtName.text=val.StreamTitle;
			}
			
			if(val.genre && val.genre.length){
				txtDesc.text=val.genre;
			}
			
			if(val.description && val.description.length){
				txtDesc.text= val.description +"  "+  txtDesc.text;
			}
			
			meta=val;			
		}
		
		/**
		 * Sets the current playlist as loaded by the controller.
		 * <p></p> 
		 * @param val
		 * 
		 */		
		public function set playList(val:XMLList):void
		{
			
		}
		
		/**
		 * Sets the current playlist item being loaded by the controller. 
		 * @param val
		 * 
		 */		
		public function set playListItem(val:XML):void
		{
			if(val.child("width").length()>0)
				providerWidth=parseInt( val.child("width").toString());
			if(val.child("height").length()>0)
				providerHeight=parseInt( val.child("height").toString());
		};
		
		/**
		 * Called when a scriptdata event is called from the flv stream.
		 * <p>Subtitles from the nsv stream will arrive as cue points.</p> 
		 * 
		 * @param val Object with name and value properties of the cue point.
		 * 
		 */		
		public function onScriptData(val:Object):void
		{
			switch(val.name)
			{
				case "onSubt"://nsv subtitle
					trace("Subtitle\n",val.value.subtitle);
					txtDesc.text=""+val.subtitle;
					break;
				case "onAsyn"://nsv stream segment end.	
					trace("End of stream segment notification. New metadata pending...\n\n");				
					break;
			}			
		}
		
		private function onClickPrev(se:MouseEvent):void{
			if(playerControl)
			{
				var i:int=playerControl.itemLoader.nextItem;
				
				i-=2;
				i=i<0?0:i;
				playerControl.playItem(i);
				
			}
		}
		
		private function onClickNext(se:MouseEvent):void{
			if(playerControl)
			{
				var i:int=playerControl.itemLoader.nextItem;
				
				if(i < playerControl.itemLoader.list.length())
					playerControl.playNext();
				else
					playerControl.playItem(0);
			}
		}
		public function onClickPause(me:MouseEvent)
		{
			if(playerControl)
			playerControl.pauseStream();
		}	
		public function onClickStop(me:MouseEvent)
		{
			if(playerControl)
			playerControl.stopStream();
		}	
		
		public function onClickPlay(me:MouseEvent)
		{
			if(playerControl)
			{
				var i:int=playerControl.itemLoader.nextItem;
				i--;
				playerControl.playItem(i);
			}
		}	
	}
	
}
