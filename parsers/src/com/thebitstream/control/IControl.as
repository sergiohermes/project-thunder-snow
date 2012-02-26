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
	public interface IControl
	{
		function playItem(item:int):void;
		function playNext():void;
		function playStream(position:Number=0):void;
		function seekStream(position:Number):void;
		function stopStream():void;
		function pauseStream():void;
		function set volume(val:Number):void;
		function get volume():Number;
		function get itemLoader():ItemLoader;
	}
}