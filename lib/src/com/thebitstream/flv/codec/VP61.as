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
	
	import flash.utils.ByteArray;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class VP61 extends CodecBase
	{
			
		public override function get type():String
		{ 
			return "VP61";
		}
				
		public override function get flip():Boolean
		{
			return true;
		}
		
		public override function get flag():uint
		{
			return FLAG_VIDEO;
		}
		
		public override function readTag(ba:ByteArray,streamTime:int):void
		{
			var v : ByteArray = new ByteArray();
			
			var flags:uint = 0x00;
			var crops:uint = 0x00;
			var key:Boolean = ( ba[0] >> 7 == 0 );
			
			if(!_isReady && key)
			{
				_isReady=true;
				dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,this));
			}
			
			if(!_isReady && !key)
			{
				return;
			}
			if (!key) 
			{
				flags = (0x02) << 4 | (0x04);
			} 
			else 
			{					
				flags = (0x01) << 4 | (0x04);
			}
			
			v.writeByte(flags);
			v.writeByte(crops);
			
			while(ba.position < ba.length)
				v.writeByte(ba.readByte());
			
			v.position=0;
			
			var sde:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,v);
			sde.timeCode=streamTime;
			dispatchEvent(sde);
			
		}
		
		public override function readMetaObject(data:Object , streamTime:int):void
		{
			data.videocodecid=type;
			data.flipVideo=1;
		}
	}
}