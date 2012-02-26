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
	import com.thebitstream.flv.codec.mpeg.MP3Header;
	
	import flash.utils.ByteArray;
	
	/**
	 * @author Andy Shaules
	 * 
	 */	
	public class MP3 extends CodecBase
	{
		private var currentTime:Number=0;
		private var buffer:ByteArray;
		private var isSync:Boolean;
		private var reader:MP3Header=new MP3Header();
		
		public override function readMetaObject(data:Object , streamTime:int):void
		{
			data.audiocodecid=2;
			data.audiocodec="MP3";
		}
		
		public override function readTag(ba:ByteArray,streamTime:int):void
		{			
			findHeader(ba);			
		}
		
		private function findHeader(bad:ByteArray):int
		{
			var ba:ByteArray=new ByteArray();
			
			if(buffer!= null)
			{
				buffer.position=0;
				ba.writeBytes(buffer);
				buffer.clear();
				buffer=null;
			}
			
			bad.position=0;
			ba.writeBytes(bad);
			bad.clear();
			ba.position=0;
						
			var nextFrame:int=0;
			var lastTry:Number=0;
			var i:int=0;
			
			for( i; i < ba.length - 3 ; i++ )
			{				
				if(nextFrame != 0)
				{					
					if(nextFrame < ba.length )
					{ 
						if( ba[nextFrame] != 0xff)
						{
							isSync=false;
						}
						else
						{
							isSync=true;
							i=nextFrame;
						}
					}				
					nextFrame=0;
				}				
				
				if (ba[i] != 0xff)
				{
					if(isSync){
						i=lastTry;
						isSync=false;
					}
					continue;
				}
				else
				{
					if ((ba[i+1] & 0xe0) == 0xe0)
					{ 						
						ba.position=0;
						var start:int=i;
						
						reader.readHeader( (ba[i]<<24) |  (ba[i+1]<<16) |  (ba[i+2]<<8) |  (ba[i+3]) );
						
						if(reader.getSampleRate()<=0 || reader.getBitRate()<=0 ||reader.frameDuration()<=0 || reader.frameSize()<=0 )
						{							
							nextFrame=0;
							ba.position= 0;
							continue;
						}						
						
						if( (isSync) &&  (ba.length ) <  i + reader.frameSize()  )
						{	
							break;
						}
						
						if(!isSync){
							nextFrame= i + reader.frameSize();
							lastTry=i;
							continue;
						}						
						
						var rem:Number=ba.length - i - reader.frameSize();						
						if( rem < 0)
						{
							buffer=new ByteArray();
							buffer.writeBytes(ba, i,  ba.length - i);
							buffer.position=0;
							ba.position=0;
							nextFrame=0;
							ba.clear();
							return -1;
						}
						else
						{
							if(!_isReady)
							{
								_isReady=true;
								var d:CodecEvent= new CodecEvent(CodecEvent.STREAM_READY,this);
								dispatchEvent(d);
							}
							
							var tag:ByteArray=new ByteArray();
							var flgs:uint=0;
								
							flgs =  (0x2 <<4);//TODO except for 8kh 
							flgs |= reader.getFLVSampleRateFlag()<<2; 
							flgs |= 1<<1;
							flgs |= reader.isStereo()?1:0;
							
							tag.writeByte(flgs);
							tag.writeBytes(ba,i,reader.frameSize());							
	
							ba.position=0;
	
							tag.position=0;
							
							var sde:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,tag);
							sde.timeCode=int(currentTime);
							isSync=true;
							dispatchEvent(sde);
							tag.clear();
							
							currentTime+=reader.frameDuration();
							nextFrame=0;
							i += reader.frameSize()-1;		
							continue;
						}
					}
					else
					{
						if(isSync)
						{
							nextFrame=0;
							isSync=false;
						}
					}
				}				
			}		
					
			buffer=new ByteArray();
			buffer.writeBytes(ba, i ,ba.length-i);
			buffer.position=0
			ba.clear();
			nextFrame=0;
			return -1;
		}
		
		public override function get flag():uint
		{
			return FLAG_AUDIO;
		}
		
		public override function get type():String
		{
			return "MP3";
		}
	
	
	}
}