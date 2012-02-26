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
	
	
	/**
	 * Red5 MP3header class translated to Action script 3.
	 * 
	 * @author The Red5 Project 
	 * @author Joachim Bauch
	 * @author Andy Shaules
	 * 
	 */	
	public class MP3Header
	{	
		public function readHeader(data:uint):void
		{			
			data &= 0x1fffff;	
			audioVersionId =  ((data >> 19) & 3);
			layerDescription =  ((data >> 17) & 3);
			protectionBit = ((data >> 16) & 1) == 0 ;
			bitRateIndex =  ((data >> 12) & 15);
			samplingRateIndex =  ((data >> 10) & 3);
			paddingBit = ((data >> 9) & 1) != 0 ;
			mode =  ((data >> 6) & 3);
		}
		
		public function frameDuration():Number
		{
			switch (layerDescription) 
			{
				case 3:					
					return 384 / (getSampleRate() * 0.001);
					
				case 2:
				case 1:
					if (audioVersionId == 3) 
					{
						
						return 1152 / (getSampleRate() * 0.001);
					} 
					else 
					{
						
						return 576 / (getSampleRate() * 0.001);
					}					
				default:
					return -1;
			}
		}
		
		public function frameSize():int 
		{
			switch (layerDescription) 
			{
				case 3:					
					return (12 * getBitRate() / getSampleRate() + (paddingBit ? 1
						: 0)) * 4;
					
				case 2:
				case 1:					
					if (audioVersionId == 3) 
					{						
						return 144 * getBitRate() / getSampleRate()
							+ (paddingBit ? 1 : 0);
					} 
					else 
					{						
						return 72 * getBitRate() / getSampleRate()
							+ (paddingBit ? 1 : 0);
					}
					
				default:					
					return -1;
			}
		}
		
		public function isStereo():Boolean 
		{
			return (mode != 3);
		}
		
		public function getBitRate():int 
		{
			var result:int=0;
			switch (audioVersionId) 
			{
				case 1:
					return -1;
					
				case 0:
				case 2:
					if (layerDescription == 3)
					{
						result = BITRATES[3][bitRateIndex];
					} 
					else if (layerDescription == 2 || layerDescription == 1) 
					{
						result = BITRATES[4][bitRateIndex];
					} 
					else 
					{
						return -1;
					}
					break;
				
				case 3:
					if (layerDescription == 3) 
					{
						result = BITRATES[0][bitRateIndex];
					} 
					else if (layerDescription == 2) 
					{
						result = BITRATES[1][bitRateIndex];
					}
					else if (layerDescription == 1) 
					{
						result = BITRATES[2][bitRateIndex];
					} 
					else 
					{
						return -1;
					}
					break;
				
				default:
					return -1;
			}
			
			return result * 1000;
		}
		
		public function getSampleRate():int 
		{
			return SAMPLERATES[audioVersionId][samplingRateIndex];
		}
		
		public function getFLVSampleRateFlag():uint
		{
			
			var ret:uint=0;
			switch(getSampleRate()){
				
				default:
					ret=0;
					break;			
				case 11025:
					ret=1;
					break;
				case 22050:
					ret=2;
					break;
				case 44100:
					ret=3;
					break;
				
			}
			return ret;
			
			
		}		
		public var audioVersionId:uint;
		public var layerDescription:uint;
		public var protectionBit:Boolean;
		public var bitRateIndex:uint;
		public var samplingRateIndex:uint;
		public var paddingBit:Boolean;
		public var mode:uint;
		
		private static const BITRATES:Array = [
			[ 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416,448, -1 ],
			[ 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320,	384, -1 ],
			[ 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320,	-1 ],
			[ 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224,	256, -1 ],
			[ 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, -1 ], 
		];
		
		
		private static const  SAMPLERATES:Array = [
			[ 11025, 12000, 8000, -1 ],
			[ -1, -1, -1, -1 ],
			[ 22050, 24000, 16000, -1 ],
			[ 44100, 48000, 32000, -1 ], 
		];	
	}
}