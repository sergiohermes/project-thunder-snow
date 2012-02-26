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
	/**
	 * The base interface for parsers that can be loaded or imported.
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public interface IProvide
	{
		
		function initStream(item:XML):void;
		function close():void;
		function set client(val:Object):void;
		function set volume(val:Number):void
		function get volume():Number;
		function get metaData():Object;
		function get content():String;
		function get type():String;
		function get providerWidth():int;
		function get providerHeight():int;
		function get time():Number;
		function get rawProgress():Number;
		function get parsingProgress():Number;
		function get providerPosition():Number;
		function get duration():Number;
		function get canSeek():Boolean;
		function seekStream(position:Number):void;
		function playStream(position:Number=0):void;
		function stopStream():void;
		function pauseStream():void;
	}
}