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
	
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	
	[Event(type="com.thebitstream.flv.CodecEvent",name="ready")]
	
	[Event(type="com.thebitstream.flv.StreamDataEvent",name="data")]
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class CodecBase  extends EventDispatcher implements ICodec
	{
		public static const FLAG_AUDIO:uint= 0x08;
		
		public static const FLAG_VIDEO:uint= 0x09;
		
		public static const FLAG_SCRIPT:uint= 0x13;
		
		protected var _lastTimestamp:int=0;
		
		protected var _isReady:Boolean=false;
		
		protected var _id:int=0;
		
		public function get streamId():int
		{
			return _id;	
		}
		
		public function set streamId(val:int):void
		{
			 _id=val;	
		}		
		public function get flag():uint
		{
			return 0;
		}
				
		public function get privateData():ByteArray
		{
			return null;
		}
		
		public function get type():String
		{
			return null;
		}
		
		public function get flip():Boolean
		{
			return false;
		}
		
		public function get scriptName():String
		{
			return null;
		}
		
		public function readTag(ba:ByteArray,streamTime:int):void
		{			
		}
		/**
		 * Metadata generators should dispatch a script data event.
		 * Non-metadata generators should add version and codec information.
		 * @param data The meta data info accumulated.
		 * @param streamTime
		 * 
		 */		
		public function readMetaObject(data:Object,streamTime:int):void
		{			
		}
		

		
		public static function createScriptDataTag(name:String,data:Object):Tag
		{
			var scrptTag:Tag = new Tag();
			scrptTag.writeByte(2);
			scrptTag.writeShort( name.length); 
			scrptTag.writeUTFBytes( name ); 
			
			writeObject(scrptTag,data);
			return scrptTag;
		}
		
		public static function writeObject(tag:Tag,val:Object):void
		{
			tag.writeByte(8);
			
			var cnt:uint=0;
			
			for(var props:String in val)
			{
				cnt++;
			}
			
			tag.writeUnsignedInt(cnt);
			
			for(var prop:String in val)
			{	
				tag.writeShort( prop.length); 
				tag.writeUTFBytes( prop );
				writeStringProp(tag,val[prop]);
			}
			
			tag.writeUnsignedInt24(9);
		}		
		public static function writeStringProp(tag:ByteArray,val:String):void
		{
			tag.writeByte(2);
			tag.writeShort( val.length); 
			tag.writeUTFBytes( val );	
		}
		
		public static function writeBoolean(tag:ByteArray,val:Boolean):void
		{
			tag.writeByte(1);
			tag.writeByte(int(val)); 			
		}
		
		public static function writeNumber(tag:ByteArray,val:uint):void
		{
			tag.writeByte(0);
			tag.writeUnsignedInt(val); 			
		}		
	}
}