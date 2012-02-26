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
	import com.thebitstream.flv.codec.mpeg.AVC;
	
	import flash.utils.ByteArray;

	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public class x264 extends AVC
	{
		public override function get flag():uint
		{
			return CodecBase.FLAG_VIDEO;
		}
		
		public override function readMetaObject(data:Object,streamTime:int):void
		{
			data.videoccodecid="7";
			data.videoccodec="x264";
		}
		
		public override function get type():String
		{
			return "x264";
		}
	}

}