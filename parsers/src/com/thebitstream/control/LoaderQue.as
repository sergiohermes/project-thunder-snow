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
package com.thebitstream.control
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.utils.setTimeout;
	/**
 	 * 
 	 */
	[Event(type="flash.events.Event",name="complete")]
	/**
	 * 
	 */	
	[Event(type="flash.events.Event",name="change")]
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	internal class LoaderQue extends EventDispatcher
	{
		private var loaders:Array=[];

		internal function startLoad():void
		{
			flash.utils.setTimeout(loadOne,125);
		}
		
		private function loadOne():void
		{
			if(loaders.length)
			{
				var rsl:ExternalLib=loaders.shift() as ExternalLib;
				rsl.load();
			}			
		}
		
		internal function addItem(external:ExternalLib):void
		{
			external.loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaded);
			external.loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onLoaded);
			loaders.push(external);
		}
		
		private function onLoaded(e:*):void
		{
			if(loaders.length)
			{
				dispatchEvent(new Event(Event.CHANGE));
				flash.utils.setTimeout(loadOne,125);
			}
			else
			{
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
	}
}