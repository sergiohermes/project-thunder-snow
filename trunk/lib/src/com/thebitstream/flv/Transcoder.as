/**
 LICENSE:
 
 Project Thunder Snow
 Copyright 2011 thebitstream.com
 
 Description:
 *A Multimedia engine and transcoding framework for playing audio,
 visual, and scripted-data streams from any networked resource.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */
package com.thebitstream.flv
{
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.flv.io.Tag;
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	/**
	 * Dispatched when a codec is ready 
	 */	
	[Event(type="com.thebitstream.flv.CodecEvent",name="ready")]
	/**
	 * Dispatched when a new tag is ready for streaming. 
	 */	
	[Event(type="com.thebitstream.flv.StreamDataEvent",name="data")]
	/**
	 * Dispatched when auxiliary audio stream data tag is ready for streaming.
	 */	
	[Event(type="com.thebitstream.flv.StreamDataEvent",name="aux_data")]
	
	/**
	 * A Transcoder is used to process the writing of raw data payloads into a playable flv stream. It handles loading the codecs, and passing the payloads to the correct codec.
	 * <p>While parsing an incoming stream, the first step is to identify the content of the raw payloads. 
	 * Second is to pass them to this method for processing. 
	 * To playback the content as an AV stream, you will need to create a netstream, append a header, 
	 * and then append every subsequent data tag that is dispatched as StreamEvent.DATA</p> 
	 * <p>Supported codecs : MP3, AAC/AACP, AVC Video, SUBT, AUXA, ASYN, VP6</p>
	 * @author Andy Shaules
	 * 
	 */	
	public class Transcoder extends EventDispatcher 
	{
		public static const HAS_VIDEO:uint= 1;
		
		public static const HAS_AUDIO:uint= 1<<2;
		
		public static const MAGIC_NUMBER:uint = 0x46<<24   |  0x4C<<16  | 0x56<<8 | 0x1;
		
		private var _previousTagSize : uint = 0;
		private var _previousTimeStamp : uint = 0;
		private var _metaHandler:CodecBase;
		private var _channels:Object={};
		
		/**
		 * Clear channels and create a new default meta handler. 
		 * 
		 */		
		public function initiate():void
		{
			_channels={};
			if(_metaHandler)
				_metaHandler.removeEventListener(StreamDataEvent.DATA,onTag);
			
			_metaHandler=CodecFactory.CreateCodec("MetaData");
			if(_metaHandler){
				_metaHandler.addEventListener(StreamDataEvent.DATA,onTag);
				dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,_metaHandler));
			}		
		}
		
		/**
		 * Push raw data into the transcoder by type.
		 * @param dat Data buffer.
		 * @param timeStamp Stream time, if it exists.
		 * @param cod fourCC of data type.
		 *  
		 * 
		 */		
		public function addRawData(dat : ByteArray, timeStamp : uint, cod:String=null) : void 
		{
			var dec:CodecBase=getCodec(cod);
			
			if(dec==null)
			{
				try
				{	cod=cod.replace(" ","");				
					dec=CodecFactory.CreateCodec(cod);
					codec=dec;
					
					dec.addEventListener(CodecEvent.STREAM_READY,onCodecReady);
					dec.addEventListener(StreamDataEvent.DATA,onTag);
				}
				catch (e:Error){}
				
				if(dec== null)
					return;				
			}
			
			dec.readTag(dat,timeStamp);					
		}
		/**
		 *
		 * @param cod fourCC string.
		 * 
		 */		
		public function loadCodec(cod:String):void
		{
			try
			{			
				cod=cod.replace(" ","");				
				var dec:CodecBase=CodecFactory.CreateCodec(cod);
				codec=dec;
				
				dec.addEventListener(CodecEvent.STREAM_READY,onCodecReady);
				dec.addEventListener(StreamDataEvent.DATA,onTag);
			}
			catch (e:Error){}
		}
		/**
		 * Adds a codec to the channel bank. 
		 * @param val
		 * 
		 */		
		private function set codec(val:CodecBase):void
		{
			_channels[val.type]=val;
		}
		
		private function getCodec(type:String):CodecBase
		{
			type=type.replace(" ","");
			return _channels[type];	
		}	
		
		private function onCodecReady(ce:CodecEvent):void
		{
			
			dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,ce.codec));
			
			if(ce.codec.privateData != null)
			{			
				trace("Codec private data is available");
				var tag:Tag=new Tag();				
				tag.writeInt(_previousTagSize);
				tag.writeByte(ce.codec.flag);
				tag.writeUnsignedInt24( ce.codec.privateData.length);
				tag.writeUnsignedInt24( _previousTimeStamp);
				tag.writeByte(_previousTimeStamp>>24);								
				tag.writeUnsignedInt24( ce.codec.streamId);			
				tag.writeBytes(ce.codec.privateData);				
				_previousTagSize= tag.length;
				
				var e:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,ce.codec,tag)
				e.timeCode=_previousTimeStamp;
				dispatchEvent(e);	
				
				tag.clear();
			}			
		}
		
		private function onTag(sde:StreamDataEvent):void
		{
			
			_previousTimeStamp=sde.timeCode;	
			
			if(sde.codec.streamId==0)
			{	
				var tag:Tag=new Tag();		
				tag.writeInt(_previousTagSize);		
				tag.writeByte(sde.codec.flag);		
				tag.writeUnsignedInt24( sde.tag.length);
				tag.writeUnsignedInt24(sde.timeCode);
				tag.writeByte(sde.timeCode >> 24 );		
				tag.writeUnsignedInt24( sde.codec.streamId);
				tag.writeBytes(sde.tag);				
				_previousTagSize= tag.length;
				
				var e:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,sde.codec,tag)
				e.timeCode=sde.timeCode;
				dispatchEvent(e);	
			}
			else
			{	//auxiliary audio streams.
				var aux:StreamDataEvent=new StreamDataEvent(StreamDataEvent.AUX_DATA,sde.codec,sde.tag)
				aux.timeCode=sde.timeCode;
				dispatchEvent(aux);
			}
			
			
			tag.clear();			
		}
		/**
		 * Transcodes object into flv tag if it qualifies. 
		 * @param data
		 * @param time
		 * 
		 */		
		public function readMetaObject(data:Object,time:int=0):void
		{
			if(time==0){
				time=_previousTimeStamp	
			}
			for (var code:String in _channels)
			{
				CodecBase(_channels[code]).readMetaObject(data,time);
			}
			if(_metaHandler)
				_metaHandler.readMetaObject(data,time);
		}
		/**
		 * Create an flv header packet. 
		 * @param hasVid
		 * @param hasAud
		 * @return The packet.
		 * 
		 */		
		public function createHeader(hasVid:Boolean=true,hasAud:Boolean=true) : ByteArray 
		{	
			var fileHeader : ByteArray = new ByteArray();			
			fileHeader.writeUnsignedInt(MAGIC_NUMBER);						
			var flags:uint= ((hasVid ) ? HAS_VIDEO : 0 ) | ( ( hasAud ) ? HAS_AUDIO : 0);			
			fileHeader.writeByte(flags);
			fileHeader.writeUnsignedInt(0x09);	
			
			return fileHeader;
		}	
		
		public function get metaHandler():CodecBase
		{
			return _metaHandler;
		}		
		public function set metaHandler(value:CodecBase):void
		{
			if(_metaHandler)
				_metaHandler.removeEventListener(StreamDataEvent.DATA,onTag);
			
			_metaHandler = value;
			_metaHandler.addEventListener(StreamDataEvent.DATA,onTag);				
			dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,_metaHandler));			
		}		
	}
}
