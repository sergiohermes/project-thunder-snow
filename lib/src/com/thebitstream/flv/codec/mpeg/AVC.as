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
package com.thebitstream.flv.codec.mpeg
{
	import com.thebitstream.flv.codec.AAC;
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.flv.io.Tag;
	
	import flash.utils.ByteArray;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public class AVC extends CodecBase
	{
		private var aac:AAC=new AAC();
		private var t:Number;
		private  var _codecSetupLength:int;
		
		private  var codecSent:Boolean;
		
		private  var _SPSLength:int;
		
		private  var _PPSLength:int;
		
		private var _pCodecSetup:Array;
		
		private var _pSPS:Array;
		
		private var _pPPS:Array;
		
		private var _pSEI:Array;
		

		
		public function AVC()
		{
			aac.addEventListener(CodecEvent.STREAM_READY, onReady);
			aac.addEventListener(StreamDataEvent.DATA, onTag);
		}
		private function onReady(ce:CodecEvent):void
		{
			t=new Date().time;
			trace("onReady "+ ce.codec.type);
			var cre:CodecEvent=new CodecEvent(ce.type,ce.codec);
			dispatchEvent(cre);
		}
		private function onTag(ce:StreamDataEvent):void
		{
			
			var sde:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,aac,ce.tag);
			sde.timeCode=ce.timeCode;
			dispatchEvent(sde);
		}		
		public override function readTag(frame:ByteArray,  timecode:int):void
		{		
			for (var i:int = 0; i < frame.length-4; i++) 
			{
				if (frame[i] == 0) 
				{
					if (frame[i + 1] == 0) 
					{
						if (frame[i + 2] == 0) 
						{
							if (frame[i + 3] == 1) 
							{
								i += 4;
								
								var  size:int = this.findFrameEnd(frame, i);
								
								if (size == -1)
									size = frame.length - i;
								else
									size = size - i;
								
								processNal(frame, i, size,timecode);
								
								i += size-1;
							}
							else
							{//ouch
								trace('ouch')
							}
						}
						else
						{
							if(frame[i + 2]== 1)
							{
								i += 3;
								trace('hrm')
								var  size2:int = this.findFrameEnd(frame, i);
								if (size2 == -1)
									size2 = frame.length - i;
								else
									size2 = size2 - i;
								
								processNal(frame, i, size2,timecode);
								
								i += size2-1;
							}
						}
					}
				}
			}			
		}
		
		public override function get privateData():ByteArray
		{
			if (_pCodecSetup == null)
				return null;
			
			var buffV:ByteArray = new ByteArray();
			
			for (var p :int= 0; p < _pCodecSetup.length; p++)
				buffV.writeByte( _pCodecSetup[p]);
			
			buffV.position=0;
			
			return buffV;
		}
		
		private function processNal( frame:ByteArray, i:int,  size:int, timecode:int):void 
		{
			
			var type:int = readNalHeader(frame[i]);
			var k:int=0;
			var r:int = 0
			switch (type) 
			{
				case SPS:
					_pSPS = null;
					_SPSLength = size;
					_pSPS = new Array(_SPSLength);
					for ( k = 0; k < size; k++) 
					{
						_pSPS[k] = frame[k + i];
					}
					break;
				
				case PPS:
					_pPPS = null;
					_PPSLength = size;
					_pPPS = new Array(size);
					for (k = 0; k < size; k++) 
					{
						_pPPS[k] = frame[k + i];
					}
					break;
				case SEI:
					_pSEI = null;
					_pSEI = new Array(size);
					for (k = 0; k < size; k++) 
					{
						_pSEI[k] = frame[k + i];
					}
					break;
			}
			trace(names[type])
			switch (type) 
			{
				case AUD:
					frame.position=0;
					aac.readTag(frame,0);
					break;
					
				case IDR:					
					if (!codecSent  )
					{
						buildCodecSetup();
						sendAVCDecoderConfig(timecode);
					}
					
					if (!codecSent)
						return;
					
					var buffV:Tag = new Tag();
					buffV.writeByte( 0x17);
					buffV.writeByte( 0x01);
					buffV.writeUnsignedInt24(0);
					buffV.writeUnsignedInt(size);
					
					for ( r = 0; r < size - 1; r++) 
					{
						buffV.writeByte( frame[r + i]);
					}
					buffV.writeByte( 0);
					
					buffV.position=0;
					
					var keyEvent:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,buffV);
					keyEvent.timeCode=timecode + (new Date().time-t);
					dispatchEvent(keyEvent);
					buffV.clear();
					break;
				case CodedSlice:
					if (!codecSent)
					{					
						return;
					}
					
					var buffV2:Tag = new Tag();				
					buffV2.writeByte( 0x27);
					buffV2.writeByte( 0x01);				
					buffV2.writeUnsignedInt24(0);				
					buffV2.writeUnsignedInt(size);
					
					for ( r = 0; r < size - 1; r++) 
					{
						buffV2.writeByte( frame[r + i]);
					}
					buffV2.writeByte( 0);				
					buffV2.position=0;
					
					var slice:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,buffV2);
					slice.timeCode=timecode + (new Date().time-t);
					dispatchEvent(slice);
					buffV2.clear();
					break;
			}
		}
		
		private function buildCodecSetup():void 
		{
			
			if (_pPPS == null && _pSPS == null) 
			{
				return;
			}
			
			_codecSetupLength = 5 
				+ 8 
				+ _SPSLength 
				+ 3 
				+ _PPSLength; 
			
			_pCodecSetup = new Array(_codecSetupLength);
			var cursor:int = 0;
			
			trace( _pSPS[1]);
			trace( _pSPS[2]);
			trace( _pSPS[3]);
			
			_pCodecSetup[cursor++] = 0x17;
			_pCodecSetup[cursor++] = 0; 
			_pCodecSetup[cursor++] = 0; 
			_pCodecSetup[cursor++] = 0; 
			_pCodecSetup[cursor++] = 0; 			
			_pCodecSetup[cursor++] = 1; 
			_pCodecSetup[cursor++] = _pSPS[1]; 
			_pCodecSetup[cursor++] = _pSPS[2]; 
			_pCodecSetup[cursor++] = _pSPS[3]; 			
			_pCodecSetup[cursor++] = 0x3; 
			_pCodecSetup[cursor++] = 0x1; 
			_pCodecSetup[cursor++] = ((_SPSLength >> 8) & 0xFF);
			_pCodecSetup[cursor++] = (_SPSLength & 0xFF);
			
			var sizeS:int = _pCodecSetup[cursor - 2] << 8 | _pCodecSetup[cursor - 1];
			
			var k:int = 0
			
			for (k=0; k < _SPSLength; k++) 
			{
				_pCodecSetup[cursor++] = _pSPS[k];
			}
			
			_pCodecSetup[cursor++] = 1; 			
			_pCodecSetup[cursor++] = ((_PPSLength >> 8) & 0x000000FF);
			_pCodecSetup[cursor++] = (_PPSLength & 0x000000FF);			
			
			var sizeP:int = _pCodecSetup[cursor - 2] << 8 | _pCodecSetup[cursor - 1];			
			
			for ( k = 0; k < _PPSLength; k++) 
			{
				_pCodecSetup[cursor++] = _pPPS[k];
			}
			
		}
		
		private function sendAVCDecoderConfig(timecode:int):void 
		{
			
			if (_pCodecSetup == null)
				return;
			
			var buffV:ByteArray = new ByteArray();
			
			for (var p :int= 0; p < _pCodecSetup.length; p++)
			{	
				buffV.writeByte( _pCodecSetup[p]);
			}
			buffV.position=0;
			codecSent = true;
			
			var cde:CodecEvent=new CodecEvent(CodecEvent.STREAM_READY,this);
			dispatchEvent(cde);	
			
		}
		
		private function readNalHeader( bite:int):int 
		{
			var NALUnitType:int =  (bite & 0x1F);
		//	trace(names[NALUnitType], NALUnitType);
			return NALUnitType;
		}
		
		private function findFrameEnd( frame:ByteArray,  offset:int):int
		{			
			for (var i:int = offset; i < frame.length - 3; i++) 
			{
				if (frame[i] == 0) 
				{
					if (frame[i + 1] == 0) 
					{
						if (frame[i + 2] == 0) 
						{
							if (frame[i + 3] == 1) 
							{
								return i;
							}
						}
					}
				}
			}			
			return -1;
		}
		
		private static const CodedSlice:int = 1;
		private static const DataPartitionA:int = 2;
		private static const DataPartitionB:int = 3;
		private static const DataPartitionC:int = 4;
		private static const IDR:int = 5;
		private static const SEI:int = 6;
		private static const SPS:int = 7;
		private static const PPS:int = 8;
		private static const AUD:int  = 9;
		private static const names:Array = ["Undefined", "Coded Slice", "Partition A", "Partition B", "Partition C", "IDR", "SEI", "SPS", "PPS", "AUD" ];
		
	}
}