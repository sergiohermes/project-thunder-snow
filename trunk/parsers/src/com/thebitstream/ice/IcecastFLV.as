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
package com.thebitstream.ice{


	import com.thebitstream.provider.BaseProvider;

	import com.thebitstream.provider.StreamEvent;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.net.URLStream;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public dynamic class IcecastFLV extends BaseProvider {
		
		public var serverConnection:IDataInput;		
		public var request:URLRequest;		
		
		public var frames:Number=0;
		public var streamWidth:uint;
		public var streamHeight:uint;
		
		public var connected:Boolean=false;
		public var synchronized:Boolean=false;
		
		public var transport :NetConnection;
		public var transportStream :NetStream;
		
		public var bufferTime:Number=2;
		public var backBufferTime:Number=0;
		
		public var shutDown:Boolean=false;		
		
		public var totalBytes:int=0;
		public var lastChunk:int=0;
		public var item:XML;
		
		
		public function IcecastFLV():void
		{			
			createStream(320,240,true,{});			
		}
		
		public override function initStream(item:XML):void
		{		
			shutDown=false;
			this.item=item;
			
			
			if(item.child("policy").length())
				Security.loadPolicyFile(item.child("policy").toString());
			
			var host:String ="localhost";
			if(item.child("host").length())
				host=item.child("host").toString();
			
			
			var resource:String ="/listen1";
			if(item.child("uri").length())
				resource=item.child("uri").toString();			
			
			serverConnection=new URLStream();
			EventDispatcher(serverConnection).addEventListener(ProgressEvent.PROGRESS,loaded);
			URLStream(serverConnection).addEventListener(IOErrorEvent.IO_ERROR, onIo);					
			EventDispatcher(serverConnection).addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
			EventDispatcher(serverConnection).addEventListener(Event.CLOSE, onClose);
			request=new URLRequest(host+resource);
			
			request.requestHeaders=[new URLRequestHeader("GET",resource+" HTTP/1.0+\r\nIcy-MetaData:1\r\n")];
			request.requestHeaders=[new URLRequestHeader("Icy-MetaData","1")];
			request.method=URLRequestMethod.GET;
			URLStream(serverConnection).load(request);					
		}
		
		private function onIo(pe:IOErrorEvent):void
		{			
		}		
		
		private function onNoPolicy(se:SecurityErrorEvent):void
		{
			trace("No policy file");
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));
		}
		
		public override function get providerWidth():int
		{
			return streamWidth;
		}
		
		public override function get providerHeight():int
		{
			return streamHeight;
		}
		
		private function onError(io:IOErrorEvent):void
		{
			if(!connected)
			{
				dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));
			}
		}
		
		private function createStream(Swidth:int=320,Sheight:int=240,hasAud:Boolean=true, meta:Object=null):void{
			
			if(! synchronized )
			{	
				
				
				synchronized=true;
				if(!transport)
				{
					transport = new NetConnection();
					transport.connect(null);
					
					transportStream = new NetStream(transport);
					transportStream.backBufferTime=backBufferTime;
					transportStream.bufferTime=bufferTime;
					transportStream.client = this;
					var vid:Video=new Video();
					addChild(vid);
					vid.attachNetStream(transportStream);
					
					if(Swidth)
					{
						meta.width=this.streamWidth;
						meta.height=this.streamHeight;
						meta.framerate=this.videoFramerate;					
						
					}
								
					transportStream.play(null);				
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);				
				}
				else
				{
					transportStream.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
				}
				
				volume=volume;
			}
		}		
			
		private function onClose(e:Event):void
		{
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));
		}
		
		public function onMetaData(e:Object):void
		{
			for(var s:String in e)
				trace(s,":",e[s]);
			
			dispatchEvent(new StreamEvent(StreamEvent.METADATA_CHANGED,e));
		}
		
		private function loaded(e:ProgressEvent):void
		{
			totalBytes = e.bytesLoaded;
			lastChunk= this.serverConnection.bytesAvailable;
			if(shutDown)
			{
				return;
			}
			
			var ba:ByteArray=new ByteArray();
			while(this.serverConnection.bytesAvailable)
				ba.writeByte(serverConnection.readByte());
			ba.position=0;
			
			transportStream.appendBytes(ba);	
		}
	
		public override function set volume(val:Number):void
		{
			val=(val>1?1:val);
			val=(val<0?0:val);
			if(transportStream!=null)
			{
				transportStream.soundTransform=new SoundTransform(val);
			}
			super.volume=val;
		}
		
		public override function stopStream():void
		{
			close();
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));
		}
		
		public override function get volume():Number
		{
			return super.volume;
		}
		
		public override function get type():String
		{
			return "IcecastFLV";
		}
		
		public override function get rawProgress():Number
		{
			return lastChunk/(1024 * 10 );
		}
		
		public override function get parsingProgress():Number
		{
			return transportStream.bufferLength / (bufferTime * 4 );
		}
		
		public override function get time():Number
		{
			return (transportStream != null)?transportStream.time:0;
		}
		
		public override function close():void
		{
			if(URLStream(serverConnection).connected)
			URLStream(serverConnection).close();
			shutDown=true;
			connected=false;
			if(!transportStream)
				return;
			
			transportStream.close();
			transport.close();			
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