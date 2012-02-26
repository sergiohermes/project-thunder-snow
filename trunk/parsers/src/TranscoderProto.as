/**
 LICENSE:
 
 	Project Thunder Snow
 	Copyright 2011 thebitstream.com
 
 Description:
 	*A Multimedia engine and transcoding framework for playing audio,
 		visual, and scripted-data streams from any networked resource.
 
 */
package
{
	import com.thebitstream.control.Streamer;
	import com.thebitstream.flv.CodecFactory;
	import com.thebitstream.flv.codec.*;
	import com.thebitstream.flv.codec.MetaData;
	import com.thebitstream.flv.codec.x264;
	import com.thebitstream.ice.*;
	import com.thebitstream.mp3.MP3File;
	import com.thebitstream.nsv.*;
	import com.thebitstream.provider.StreamFactory;
	import com.thebitstream.view.ViewFactory;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.filters.DropShadowFilter;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	/**
	 * Project Thunder Snow.
	 *  
	 * @author Andy Shaules
	 * 
	 */	
	[SWF(width="372", backgroundColor="#000066")]
	public class TranscoderProto extends Sprite
	{	
		private var streamLoader:Streamer;
		
		public function TranscoderProto()
		{		
			streamLoader=new Streamer();
			StreamFactory.importStreamer("ShoutcastFile",ShoutcastFile);
			StreamFactory.importStreamer("Shoutcast",Shoutcast);
			StreamFactory.importStreamer("Icecast",Icecast);
			StreamFactory.importStreamer("IcecastSocket",IcecastSocket);
			StreamFactory.importStreamer("IcecastFLV",IcecastFLV);
			StreamFactory.importStreamer("IcecastNSV",IcecastNSV);
			StreamFactory.importStreamer("MP3File", MP3File);
			
			CodecFactory.ImportCodec(MetaData);
			CodecFactory.ImportCodec(MP3);
			CodecFactory.ImportCodec(x264);
			CodecFactory.ImportCodec(VP61);
			CodecFactory.ImportCodec(VP62);
			CodecFactory.ImportCodec(H264);
			CodecFactory.ImportCodec(SUBT);
			CodecFactory.ImportCodec(AAC);
			CodecFactory.ImportCodec(AACP);			

			streamLoader.addEventListener(Event.OPEN, onStreamEvent);
			streamLoader.addEventListener(Event.CLOSE, onStreamEvent);
			streamLoader.addEventListener(Event.COMPLETE, onStreamEvent);
			flash.utils.setTimeout(present,500);
		}
		
		private function present():void
		{		
			var playlistFile:String="playlist.xml";

			streamLoader.loadPlaylist(playlistFile);
		}
		private function onClick(me:MouseEvent):void
		{
		
		}
		private function onStreamEvent(e:Event):void
		{
			switch(e.type)
			{
				case Event.OPEN:
					while(numChildren)
					{
						removeChildAt(0);
					}
					addChild((streamLoader.itemProjector as DisplayObject));
					streamLoader.itemControler.volume=.5;
					
					
					
					
					break;
				
				case Event.CLOSE:
					break;
				
				case Event.COMPLETE:
					break;				
			}
		}
		
	}
}