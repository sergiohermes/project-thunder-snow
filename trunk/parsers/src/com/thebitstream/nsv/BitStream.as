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
package com.thebitstream.nsv
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class BitStream 
	{
		public var data:ByteArray=new ByteArray();
		
		public var currentByte:int=0;
		
		public var bitsUsed:int=0;
		
		public var bitPosition:int=0;
		
		public function BitStream()
		{
			data.endian=Endian.LITTLE_ENDIAN;
		}
		
		public function gc():void
		{
			if(bitPosition==0)
				return;
			
			var resized:ByteArray=new ByteArray();
			
			if(data.length>bitPosition/8)
				resized.writeBytes(data, bitPosition/8, data.length- bitPosition/8);
			
			bitsUsed=resized.length*8;
			bitPosition=0;
			data.clear();
			data=null;			
			data=resized;
		}  
		
		public function read(num:int):uint
		{    
			var ret:uint=0;			
			var index:int= bitPosition/8;
			
			for (var writePosition:int=0; writePosition < num; writePosition++ )
			{
				ret |= (  ( data[index]>>( bitPosition & 7 ) )& 0x1 ) << writePosition;
				index += int(( (++bitPosition) &7 )== 0 );
			}      
			return ret;
		}
		
		public function addInt(value:int):void
		{
			addByte((value)&0xFF);
			addByte((value>>8)&0xFF);
			addByte((value>>16)&0xFF);
			addByte((value>>24)&0xFF);
		}
		
		public function readInt():uint
		{
			var ret:uint=(read(8))|
				(read(8)<<8)|
				(read(8)<<18)|
				(read(8)<<24);
			return ret;
		}
		
		public function readByte():uint
		{
			return read(8);
		}
		
		public function addByte(byte:uint):void
		{
			write(8,byte);
		}
		
		public function write(num:int, value:uint):void
		{   
			while (num-- > 0)
			{
				currentByte |= (value& 0x01)<<(bitsUsed&7);
				if (!((++bitsUsed)&7))
				{
					data.writeByte(currentByte);
					currentByte=0;
				}
				value>>=1;
			}
		}
		
		public function seek( nbits:int):void
		{
			bitPosition+=nbits;
			
			if (bitPosition < 0) 
				bitPosition=0; 

		}
		
		public function clear():void
		{
			if(data)
			{
				data.clear();
				data=null;
			}
			
			data=new ByteArray();
			data.endian=Endian.LITTLE_ENDIAN;
			bitPosition=0;		
			currentByte=0;
			bitsUsed=0
		}
		
		public function avail():int
		{
			return data.length*8 - bitPosition; 
		}
		
		public static function  decodeFramerate(code:int):Number
		{
			var baseTimes:Array=[ 30, 30*1000/1001.0, 25, 24 * 1000/1001.0];
			
			if (!(code&0x80)) 
				return code;
			
			var scale:Number;
			var divisor:int = code & 0x7f>> 2;
			
			if (divisor < 16) 
				scale = 1.0 / Number(divisor+1);
			else 
				scale = divisor-15;
			
			var index:int= code & 0x03 ;
			
			return baseTimes[index] * scale; 
		}
	}
}