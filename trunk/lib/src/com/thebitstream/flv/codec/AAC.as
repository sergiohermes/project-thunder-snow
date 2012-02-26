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
	import flash.utils.ByteArray;
	/**
	 * @author Andy Shaules 
	 * @author Wittawas Nakkasem
	 */	
	public class AAC extends CodecBase
	{
		public static const  SAMPLERATES:Array=[ 96000, 88200, 64000, 48000, 44100, 32000, 24000, 22050, 16000, 12000,11025, 8000, 7350];		
		
		private var frameSynched:Boolean
		private var buffer:ByteArray;
		private var remainder:ByteArray;
		private var isFirst:Boolean=true;
		private var profile:int=0;
		private var sampleRateIndex:int=0;
		private var channels:int=0;
		private var aacTimecodeOffset:int=0;
		private var lastTimecode:int=0;
		private var lastSample:int=0;
		private var aacFrequency:int=-1;
		private var samplesPerFrame:int=-1;
		private var frameRemainder:int=0;
		private var dataBlock:int=0;
		
		public function AAC()
		{
			reset();
		}
		
		public override function get flag():uint
		{
			return FLAG_AUDIO;
		}
		
		public override function readMetaObject(data:Object , streamTime:int):void
		{
			data.audiocodecid=10;
			data.audiocodec=type;
		}
		
		public function reset():void 
		{			
			remainder = null;
			buffer = null;
			frameRemainder = 0;
			frameSynched = false;
			isFirst = true;
			aacFrequency = -1;
			samplesPerFrame = -1;
			aacTimecodeOffset = 0;
			lastTimecode = 0;
			lastSample = 0;
		}
		
		public override function get type():String
		{
			return "AAC";
		}
		
		public override function readTag(ba:ByteArray,streamTime:int):void
		{
			_lastTimestamp= streamTime;
			
			if(!ba.length)
				return ;
			
			var data:ByteArray=new ByteArray();
			if(remainder)
			{
				data.writeBytes(remainder);
				remainder.clear();
				remainder=null;
			}
			data.writeBytes(ba);
			
			var offset:int = 0;
			var adtsSkipped:int = 0;
			while ((data.length - offset) > 7)
			{
				if (!frameSynched) 
				{
					if ((data[offset++] & 0xff) == 0xff)
					{
						if ((data[offset++] & 0xf6) == 0xf0) 
						{
							profile = (data[offset] & 0xC0) >> 6;
							sampleRateIndex = (data[offset] & 0x3C) >> 2;
							channels = ((data[offset] & 0x01) << 2) | ((data[offset + 1] & 0xC0) >> 6);	
							frameRemainder = (((data[offset + 1] & 0x03) << 8) | ((data[offset + 2] & 0xff) << 3) | ((data[offset + 3] & 0xff) >>> 5)) - 7;
							dataBlock = data[(offset + 4)] & 0x3;
							offset += 5; 	
							adtsSkipped += 7;
							frameSynched = true;
							if(!_isReady)
							{
								_isReady=true;
								dispatchEvent(new CodecEvent(CodecEvent.STREAM_READY,this));
							}
						}
					}
				}
				else
				{
					var remain:int = (data.length - offset);
					var bytesToRead:int = frameRemainder;
					
					if (bytesToRead > remain)
						bytesToRead = remain;
					
					if (buffer == null) 
					{
						buffer=new ByteArray();
						buffer.writeByte(0xAF);
						buffer.writeByte(0x01);
					}
					
					buffer.writeBytes(data, offset, bytesToRead);
					
					offset += bytesToRead;
					frameRemainder -= bytesToRead;					

					if (frameRemainder == 0) 
					{						
						
						var newBuffer:ByteArray = new ByteArray();
						buffer.position=0;
						newBuffer.writeBytes(buffer);
												
						if (SAMPLERATES.length <= sampleRateIndex)
						{
							isFirst = false;
							buffer = null;
							frameSynched = false;
							return;
						}
						
						deliverAACFrame(newBuffer, SAMPLERATES[sampleRateIndex], (dataBlock + 1) * 1024);
						
						isFirst = false;
						buffer = null;
						frameSynched = false;						
					}					
				}
			}			
			var remain2:int = data.length - offset;
			
			if (remain2 > 0) 
			{				
				remainder=new ByteArray();
				remainder.writeBytes(data,offset);
			}
			return;
		}
				
		private function deliverAACFrame(dat:ByteArray,sampleRate:int,sampleCount:int):ByteArray
		{			
			if (aacFrequency == -1) 
			{
				aacFrequency = sampleRate;
				samplesPerFrame = sampleCount;
			}
			
			if ((aacFrequency != sampleRate) || (samplesPerFrame != sampleCount)) 
			{
				aacFrequency = sampleRate;
				samplesPerFrame = sampleCount;
				aacTimecodeOffset = lastTimecode;
				lastSample = 0;
			}			
			var timeSpan:Number = 0;
			
			if (isFirst) 
			{
				isFirst=false;
				timeSpan = 0;
				lastSample = 0;
				lastTimecode = 0;			
			}
			else 
			{
				lastSample += sampleCount;
				timeSpan = aacTimecodeOffset + sample2TimeCode(lastSample, sampleRate) - lastTimecode;				
				lastTimecode += timeSpan;
				
			}
			
			var se:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,dat);
			se.timeCode=lastTimecode;
			dispatchEvent(se);
			return dat;
		}
		
		public override function get privateData():ByteArray
		{		
			var ret:ByteArray=new ByteArray();
			ret.writeByte( 0xaf);
			ret.writeByte( 0x00);
			ret.writeByte(  ( ((profile > 2)  ? 2 :  profile << 3) | ((sampleRateIndex >> 1) & 0x03))  );
			ret.writeByte((((sampleRateIndex & 0x01) << 7) | ((channels & 0x0F) << 3)));
			return ret;
		}
				
		private function sample2TimeCode( time:Number,  sampleRate:int):Number 
		{
			return (time * 1000 / sampleRate);
		}		
	}
}