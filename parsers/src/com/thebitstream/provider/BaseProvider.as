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

	import flash.display.Sprite;
	import flash.events.Event;

	/**
	 * Dispatched when stream becomes connected or disconnected from resource. Or if the item has been closed. 
	 */		
	[Event (type="com.thebitstream.provider.StreamEvent",name="status_changed")]
	/**
	 * Dispatched when the content type has been identitfied, and before parsing begins.
	 */	
	[Event (type="com.thebitstream.provider.StreamEvent",name="content_changed")]
	/**
	 * Dispatched when the metadata has been updated. 
	 */	
	[Event (type="com.thebitstream.provider.StreamEvent",name="metadata_changed")]
	/**
	 * Any out-of-band data is dispatched as a cuepoint from the provider in the same way as metadata.
	 * <p>Out of band data is a scriptdata tag that requires a non-existent callback. 
	 * Providers which potentially deliver OOB data should be dynamic and use the OOBHandler object. Out of band data tags are typically passed to the IProjector interface.</p>
	 * <p>CodecBase objects that produce script tag types will also provide a string version of their script function name. 
	 * This will be used to check against the existing handler functions and create a dynamic property before invocation. MetaData returns 'onMetaData' etc..
	 * </p>
	 */			
	[Event (type="com.thebitstream.provider.StreamEvent",name="cuepoint")]
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class BaseProvider extends Sprite implements IProvide
	{
		protected var _vol:Number=1;
		protected var _metaData:Object={};
		protected var _content:String;
		protected var _client:Object;
		
		public function set client(val:Object):void
		{
			_client=val;
		}
		
		public override function dispatchEvent(event:Event):Boolean
		{
			if(_client != null)
			{	
				trace("_client.processEvent", event.type);
				
				_client.processEvent(event);
				
				return true;
			}
			
			return super.dispatchEvent(event);
		}		
		/**
		 * 
		 * @param item Playlist item.
		 * 
		 */		
		public function initStream(item:XML):void
		{
			
		}
		/**
		 * Call from gui to seek, if possible. 
		 * @param position
		 * 
		 */		
		public function seekStream(position:Number):void
		{
			
		}
		/**
		 * Call from gui to play stream at position offset in seconds, if possible. 
		 * @param position
		 * 
		 */		
		public function playStream(position:Number=0):void
		{
			
		}
		/**
		 * Stop the stream. 
		 * 
		 */		
		public function stopStream():void
		{
			
		}
		
		/**
		 * Pause and buffer incoming if possible. 
		 * 
		 */		
		public function pauseStream():void
		{
			
		}
		/**
		 *  
		 * @return 0-1 Indication of incoming byte data.
		 * 
		 */		
		public function get rawProgress():Number
		{
			return 0;
		}
		/**
		 * 
		 * @return  0-1 Indication of parsing data into playable flv packets.
		 * 
		 */		
		public function get parsingProgress():Number
		{
			return 0;
		}
		/**
		 *  
		 * @return 0-1 Indication of playhead position in parsed segment. 
		 * 
		 */		
		public function get providerPosition():Number
		{
			return 0;
		}
		/**
		 * 
		 * @return Width of visual data.
		 * 
		 */		
		public function get providerWidth():int
		{
			return 0;
		}
		/**
		 * 
		 * @return Height of visual data.
		 * 
		 */		
		public function get providerHeight():int
		{
			return 0;
		}
		/**
		 *  
		 * @return If seeking is possible.
		 * 
		 */		
		public function get canSeek():Boolean
		{
			return false;
		}
		/**
		 * Close the stream and free resources. 
		 * 
		 */		
		public function close():void
		{			
		}
		/**
		 * Play head netstream time. 
		 * @return 
		 * 
		 */		
		public function get time():Number
		{
			return 0;
		}
		/**
		 *  
		 * @return duration of stream, if any.
		 * 
		 */		
		public function get duration():Number
		{
			return 0;
		}
		
		public function set volume(val:Number):void
		{
			_vol=val;
		}
		
		public function get volume():Number
		{
			return _vol;
		}
		
		public function get metaData():Object
		{
			return _metaData;
		}
		
		public function get content():String
		{
			return _content;
		}
		
		public function get type():String
		{
			return "BaseProvider";
		}
	}
}