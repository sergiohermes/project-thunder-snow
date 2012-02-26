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
package com.thebitstream.flv.codec.pack
{
	import com.thebitstream.flv.CodecFactory;
	import com.thebitstream.flv.codec.*;

	
	import flash.display.Sprite;

	[SWF(width="2",height="2")]
	public class CodecPack extends Sprite
	{
		public function CodecPack()
		{
			super();		
			CodecFactory.ImportCodec(AAC);
			CodecFactory.ImportCodec(AACP);
			CodecFactory.ImportCodec(MP3);						
			CodecFactory.ImportCodec(VP61);
			CodecFactory.ImportCodec(VP62);	
			CodecFactory.ImportCodec(x264);
			CodecFactory.ImportCodec(H264);
			CodecFactory.ImportCodec(MetaData);
			CodecFactory.ImportCodec(SUBT);
			
		}
	}
}