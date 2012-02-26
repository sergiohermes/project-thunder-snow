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
	import flash.events.Event;
	import flash.utils.ByteArray;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class StreamDataEvent extends Event
	{
		public static const DATA:String="data";
		
		public static const AUX_DATA:String="aux_data";
		
		public var codec:ICodec;
				
		public var timeCode:int=0;
		
		public var tag:ByteArray;
				
		public function StreamDataEvent(type:String,cod:ICodec,data:ByteArray)
		{
			codec=cod;
			tag=data;
			super(type,false,false);
		}
	}
}