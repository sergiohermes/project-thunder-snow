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
package com.thebitstream.mp3
{

	import com.thebitstream.flv.CodecFactory;
	import com.thebitstream.flv.Transcoder;
	import com.thebitstream.flv.codec.MP3;
	import com.thebitstream.flv.codec.MetaData;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.StreamEvent;
	
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.media.SoundTransform;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;

	/**
	 * Experimental
	 *  
	 * @author Andy Shaules
	 * 
	 */	
	public class MP3File extends BaseProvider
	{
		private const MP3_FILE:uint=1;
		
		private var streamType:uint=0;
		
		private var serverConnection:URLStream;		
		private var lastTime:uint=0;
		private var transcoder :Transcoder;
		private var transport :NetConnection;
		private var transportStream :NetStream;		
		public function MP3File()
		{
			initStream(null);
			
		}
		
		public override function initStream(item:XML):void
		{
			var resource:String ="audio.mp3";
			if(item && item.child("uri").length())
				resource=item.child("uri").toString();	
			
			var cf:CodecFactory;
			CodecFactory.ImportCodec(MP3);
			CodecFactory.ImportCodec(MetaData);
			
			serverConnection=new URLStream();
			serverConnection.addEventListener(ProgressEvent.PROGRESS, onProgress);
			serverConnection.addEventListener(IOErrorEvent.IO_ERROR, handleClose);
			var request:URLRequest=new URLRequest(resource);
			serverConnection.load(request);

			streamType=MP3_FILE;
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,true))
			transcoder=new Transcoder();
			transcoder.initiate();
			transcoder.loadCodec("MP3");
			
			transcoder.addEventListener(StreamDataEvent.DATA, onTag);
			transport = new NetConnection();
			transport.connect(null);
			
			transportStream = new NetStream(transport);
			transportStream.backBufferTime=0;
			transportStream.bufferTime=1;
			transportStream.client = this;				
			transportStream.play(null);	
			super.volume=.5;
			transportStream.soundTransform=new SoundTransform(_vol);
			transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			var renew:ByteArray=transcoder.createHeader(false,true);
			transportStream.appendBytes(renew);				
			renew.clear();
			transcoder.readMetaObject({name:"", size:120},0);	
		}
		
		private function handleClose(pe:IOErrorEvent):void
		{
			trace("handleClose");
		}
		
		public function onMetaData(e:Object):void
		{			
		}
		
		private function onTag(sde:StreamDataEvent):void
		{		
			sde.tag.position=0;
			transportStream.appendBytes(sde.tag);	
		}
		
		private function onProgress(pe:ProgressEvent):void
		{			
			var ba:ByteArray=new ByteArray();
			if(! serverConnection.bytesAvailable)
				return;
			
			while(serverConnection.bytesAvailable) 
			{
				var i:int=serverConnection.readByte();
	
				ba.writeByte(i);
				
			}
			

			//TODO regulate the feed!
			
			if(!ba.length)
			return;
			
			ba.position=0;
			
			if(streamType==MP3_FILE)
			{
				transcoder.addRawData(ba,0,"MP3");
			}			
		}
		
		public override function close():void
		{
			transportStream.close();
			transport.close();
			transcoder.initiate();
		}
		
		public override function set volume(val:Number):void
		{
			super.volume=val;
			transportStream.soundTransform=new SoundTransform(_vol);
		}
		
		public override function get content():String
		{
			return "audio/mpeg";
		}
		
		public override function get type():String
		{
			return "MP3File";
		}
		
		public override function get time():Number
		{
			return transportStream.time;
		}
		
		public override function get duration():Number
		{
			return lastTime;
		}
		
		public override function pauseStream():void
		{
			if(transportStream)
			{
				transportStream.togglePause();
			}			
		}
	}
}