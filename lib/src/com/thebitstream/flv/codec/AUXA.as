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
	import com.thebitstream.flv.CodecFactory;
	
	import flash.utils.ByteArray;

	/**
	 * Auxiliary audio stream. 
	 * @author Andy Shaules
	 * 
	 */	
	public class AUXA extends CodecBase
	{
		
		/**
		 * List of aux channels. 
		 */		
		public var tracks:Array=[];
		
		/**
		 * List of Netstreams.
		 */		
		public var streams:Array=[]; 
		
		/**
		 * Payload includes :<br />
		 * 1 byte track ID,<br />
		 * 4 byte format descriptor,<br />
		 * 2 bytes of video sync offset,<br />
		 * plus audio data.
		 * 
		 * @param payload
		 * @param streamTime
		 * 
		 */		
		public override function readTag(payload:ByteArray, streamTime:int):void
		{
			var track:int=payload.readByte();
			if(tracks[track] == null)
			{
				var type:String=String.fromCharCode(payload.readByte(),payload.readByte(),payload.readByte());
				tracks[track]=CodecFactory.CreateCodec(type);
				
				if(tracks[track] == null)//no codec.
					return;
								
				CodecBase(tracks[track]).streamId=track;
				CodecBase(tracks[track]).addEventListener(StreamDataEvent.DATA, onData);
			
			}
			else
			{
				payload.readInt();//dispose
			}
			
			var offset:int=payload.readShort();//double check this..
			
			var data:ByteArray=new ByteArray();
			
			data.writeBytes(payload,payload.position);
			
			CodecBase(tracks[track]).readTag(data , streamTime  );
			
			data.clear();
		}
		

		/**
		 * Dispatch regular DATA event. The transcoder will determine that the data is aux_data by stream id. 
		 * @param sde
		 * 
		 */		
		private function onData(sde:StreamDataEvent):void
		{
			var tagEvent:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,tracks[sde.codec.streamId],sde.tag );
			tagEvent.timeCode=sde.timeCode;			
			 dispatchEvent(tagEvent);
		}
	}
}