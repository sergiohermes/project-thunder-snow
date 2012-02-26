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
package com.thebitstream.flv.codec
{
	import com.thebitstream.flv.io.Tag;
	
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	/**
	 * Codec to read subtitles. 
	 * @author Andy Shaules
	 * 
	 */	
	public class SUBT extends CodecBase
	{
		
		public function SUBT()
		{
			_isReady=true;
			flash.utils.setTimeout(notify,2);
		}
		
		private function notify():void
		{
			dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,this));
		}
		
		public override function get scriptName():String
		{
			return "onSubt";
		}
		
		/**
		 * Subtitle payload.
		 * @param data Payload
		 * @param streamTime Current input stream time.
		 * 
		 */		
		public override function readTag(data:ByteArray, streamTime:int):void
		{
			data.position=0;
			
			_lastTimestamp=streamTime;
			
			var char:uint=0;
			var sze:uint=data.readByte() | data.readByte()<< 8;
			var lng:String="";
			var subtitle:String="";
			var chunk:Object={};
			

			
			do
			{
				char=data.readByte();
				sze--;
				lng=lng + String.fromCharCode(char);
				
			}while	
				(sze  &&  char != 0);	
			
			chunk.language=lng
			
			do
			{
				char=data.readByte();
				sze--;
				
				subtitle=subtitle + String.fromCharCode(char);
				
			}while	
				(sze>0  &&  char != 0);	
			
			chunk.subtitle=subtitle
			
			chunk. latency=data.readByte() | data.readByte()<< 8;
			
			chunk. length=data.readByte() | data.readByte()<< 8 | data.readByte()<< 16 | data.readByte()<< 24;
			
			chunk. position=new Point(data.readByte(),data.readByte() )
			
			chunk. color=new uint(  data.readByte() | data.readByte()<< 8 | data.readByte()<< 16 );
			
			chunk. fontSize=data.readByte();			
			
			dispatchSubtitle(chunk,streamTime);
			
		}
		
		public override function readMetaObject(data:Object,streamTime:int):void
		{
			data.subtitleVersion="1.0";
		}
		
		public function dispatchSubtitle(data:Object,streamTime:int):void
		{
			var subtTag:Tag = new Tag();
			subtTag.writeByte(2);
			subtTag.writeShort( scriptName.length); 
			subtTag.writeUTFBytes( scriptName ); 
			
			writeObject(subtTag,data);
			
			var event:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,subtTag);
			event.timeCode=streamTime;
			dispatchEvent(event);
		}
		
		public override function get type():String
		{
			return  "SUBT";
		}
		/**
		 * 
		 * @return script data tag id.
		 * 
		 */		
		public override function get flag():uint
		{
			return  FLAG_SCRIPT;
		}
	}
}