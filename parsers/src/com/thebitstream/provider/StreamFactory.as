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
package com.thebitstream.provider
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class StreamFactory
	{
		private static var streamers:Object={};
							
		public static function registerStreamer(type:String, qClassName:String):void
		{
			streamers[type]=qClassName;
		}
		
		public static function importStreamer(type:String, cls:Class):void
		{
			var qClassName:String=flash.utils.getQualifiedClassName(cls);
			streamers[type]=qClassName;
		}
		
		public static function createStreamer(type:String ):BaseProvider
		{
			try
			{
				if(streamers[type] != null)
				{
					var qName:String=streamers[type];
					var streamerType:*=flash.utils.getDefinitionByName(qName);
					var instance:BaseProvider=new streamerType();
					return instance;
				}
				
			}catch(e : Error){};
			
			return null;
		}
	}
}