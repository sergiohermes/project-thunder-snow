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
package com.thebitstream.flv
{
	import com.thebitstream.flv.codec.CodecBase;
	
	import flash.utils.getDefinitionByName;

	/**
	 * Supported codecs : MP3, AAC/AACP, AVC Video, SUBT, AUXA, ASYN, VP6 
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class CodecFactory
	{
		private static var bannedCodecs:Object={};
		
		private static var importedCodecs:Array=[];
		/**
		 * Import a codec at compilation time.
		 * <p>To import at runtime, 
		 * load a swf or rsl that contains the codec definition into the current application domain.</p> 
		 * @param type
		 * 
		 */		
		public static function ImportCodec(type:Class):void 
		{
			importedCodecs.push(type);
		}
		/**
		 * Load a codec. 
		 * @param type fourCC string.
		 * @return the codec.
		 * 
		 */		
		public static function CreateCodec(type:String):CodecBase 
		{
			
			if(bannedCodecs[type])
			{
				return null;
			}
			
			try
			{				
				var codecType:*=flash.utils.getDefinitionByName("com.thebitstream.flv.codec." + type );
				var codec:CodecBase=new codecType();
				return codec;
			
			}
			catch (e:Error)
			{
				trace("Codec factory banned type:"+type);
				bannedCodecs[type]=true;
			}
			return null;
		}
		
		public static function getCodecs():Array
		{
			return importedCodecs;
		}
	}
}
