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
	import com.thebitstream.provider.IProvide;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public class Control implements IControl
	{
		private var _provider:IProvide;
		
		private var loader:ItemLoader;
		
		public function Control(load:ItemLoader,prov:IProvide)
		{
			loader=load;
			_provider=prov;
		}

		public function playItem(item:int):void
		{			
			loader.playItem(item);
		}
		
		public function playNext():void
		{
			loader.playNext();			
		}
		public function get itemLoader():ItemLoader
		{
			return loader;
		}
		public function playStream(position:Number=0):void
		{
			_provider.playStream(position);			
		}
		
		public function seekStream(position:Number):void
		{
			_provider.seekStream(position);
		}
		
		public function stopStream():void
		{
			loader.close()
		}
		
		public function pauseStream():void
		{
			_provider.pauseStream();
		}
		
		public function set volume(val:Number):void
		{
			_provider.volume=val;
		}
		
		public function get volume():Number
		{
			return _provider.volume;
		}
	}
}