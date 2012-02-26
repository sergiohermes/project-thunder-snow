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
	import flash.events.Event;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class StreamEvent extends Event
	{
		public static const STATUS_CHANGED:String="status_changed";
				
		public static const CONTENT_CHANGED:String="content_changed";
		
		public static const METADATA_CHANGED:String="metadata_changed";
				
		public static const CUEPOINT:String="cuepoint";
		
		public var data:Object;
		
		public function StreamEvent(type:String, val:Object)
		{
			data=val;
			super(type, false, false);
		}
	}
}