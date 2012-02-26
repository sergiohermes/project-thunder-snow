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
	
	public class MetaData extends CodecBase
	{
		
		public override function get type():String{
			return "MetaData";
		}
		
		public override function get flag():uint
		{
			return  FLAG_SCRIPT;
		}
		
		public override function get scriptName():String
		{
			return "onMetaData";
		}
		
		public override function readMetaObject(data:Object,streamTime:int):void
		{
			var metaTag:Tag = createScriptDataTag(scriptName,data);
			
			var event:StreamDataEvent=new StreamDataEvent(StreamDataEvent.DATA,this,metaTag);
			event.timeCode=streamTime;
			dispatchEvent(event);
		}		
	}
}