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
	import com.thebitstream.flv.Transcoder;
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.OOBHandler;
	import com.thebitstream.provider.StreamEvent;
	
	import flash.display.MovieClip;
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
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	import flash.system.Security;
	import flash.utils.ByteArray;
	import flash.utils.IDataInput;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public dynamic class IcecastSocket extends BaseProvider {
		
		public static const TYPE_VOID:uint=0;
		public static const TYPE_AUDIO_AAC:uint=1;
		public static const TYPE_AUDIO_MPG:uint=1<<1;
		public static const TYPE_VIDEO_FLV:uint=1<<2;
		
		public var streamType:uint=0;
		
		public var serverConnection:IDataInput;		
		
		public var transcoder :Transcoder;
		
		public var frames:Number=0;
		public var streamWidth:uint;
		public var streamHeight:uint;
		public var videoFramerate:Number=15;
		public var video:Video;
		public var videoType:String;
		public var audioType:String;
		
		public var connected:Boolean=false;
		public var synchronized:Boolean=false;
		public var foundHead:Boolean=false;
		public var transport :NetConnection;
		public var transportStream :NetStream;
		
		public var bufferTime:Number=1;
		public var backBufferTime:Number=0;
		
		public var shutDown:Boolean=false;
		public var serverNotice:String="";

		public var totalBytes:int=0;
		public var item:XML;
		
		public var metaInterval:int=0;
		public var metaCnt:int=0;
		public var reportedBR:int=0;		
		public var lastChunk:int=0;
		
		public function IcecastSocket():void
		{

			
		}
		
		public override function initStream(item:XML):void
		{
			
			transcoder = new Transcoder();
			transcoder.addEventListener(CodecEvent.STREAM_READY,onChannelReady);
			transcoder.addEventListener(StreamDataEvent.DATA, onTag);
			transcoder.initiate();
			
			shutDown=false;
			this.item=item;
			
			
			if(item.child("policy").length())
				Security.loadPolicyFile(item.child("policy").toString());
			
			var host:String ="";
			if(item.child("host").length())
				host=item.child("host").toString();
			
			var port:int=80;
			if(item.child("port").length())
				port=parseInt(item.child("port").toString());
			
			var resource:String ="listen1";
			if(item.child("uri").length())
				resource=item.child("uri").toString();
			
			
			serverConnection=new SC2Connection(host,port,resource);
			EventDispatcher(serverConnection).addEventListener(ProgressEvent.SOCKET_DATA,loaded);
			SC2Connection(serverConnection).addEventListener(IOErrorEvent.IO_ERROR, onIo);					
			EventDispatcher(serverConnection).addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
			EventDispatcher(serverConnection).addEventListener(Event.CLOSE, onClose);
			
			SC2Connection(serverConnection).connect(host,port);
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
		private function createFLVStream(Swidth:int=320,Sheight:int=240,hasAud:Boolean=true, meta:Object=null):void{
			
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
					
					if(Swidth)
					{
						streamWidth=Swidth;
						streamHeight=Sheight;
						video=new Video(320,240);
						if(item.child("width").length())
						video.width=parseInt(item.child("width").toString());
						meta.width=this.streamWidth;
						meta.height=this.streamHeight;
						meta.framerate=this.videoFramerate;					
						addChild(video);
						video.attachNetStream(transportStream);
					}
					
					
					transportStream.play(null);				
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);					
				}
				else
				{
					transportStream.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
					var renew:ByteArray=transcoder.createHeader((Swidth==0),hasAud);
					transportStream.appendBytes(renew);				
					renew.clear();
					transcoder.readMetaObject(meta,0);
				}
				
				volume=volume;
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
					
					if(Swidth)
					{
						meta.width=this.streamWidth;
						meta.height=this.streamHeight;
						meta.framerate=this.videoFramerate;					
						
					}
					else
					{
						
					}
					
					transportStream.play(null);				
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
					
					var headerTag:ByteArray=transcoder.createHeader((Swidth==0),hasAud);
					transportStream.appendBytes(headerTag);				
					headerTag.clear();
					
					transcoder.readMetaObject(meta,0);
					
				}
				else
				{
					transportStream.appendBytesAction(NetStreamAppendBytesAction.END_SEQUENCE);
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
					var renew:ByteArray=transcoder.createHeader((Swidth==0),hasAud);
					transportStream.appendBytes(renew);				
					renew.clear();
					transcoder.readMetaObject(meta,0);
				}
				
				volume=volume;
			}
		}
		
		private function onTag(sde:StreamDataEvent):void
		{
			sde.tag.position=0;
			transportStream.appendBytes(sde.tag);
		}
		
		private function onChannelReady(ce:CodecEvent):void
		{	
			trace('onChannelReady :',ce.codec.type);
			
			if(ce.codec.flag == CodecBase.FLAG_SCRIPT)
			{
				if(! hasOwnProperty( ce.codec.scriptName))
				{
					var handler:OOBHandler=new OOBHandler(this,ce.codec.scriptName);
					this[ce.codec.scriptName]=handler.handle;
				}
			}			
		}
		
		private function onClose(e:Event):void
		{
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));
		}
		
		public function onMetaData(e:Object):void
		{
			dispatchEvent(new StreamEvent(StreamEvent.METADATA_CHANGED,e));
		}
		
		private function loaded(e:ProgressEvent):void
		{		
			lastChunk=e.bytesLoaded;
			totalBytes += ((e.bytesLoaded));
			if(shutDown)
			{
				return;
			}	
			var char:String="";
			var head:String="";
			
			if(!connected )
			{			
				do{					
					char = String.fromCharCode(serverConnection.readByte());
					head=head.concat( char);					
					if(head.indexOf("\r\n\r\n")>-1)
					{	
						
						if(!connected )
						{
																	
							connected=(head.indexOf("OK") > -1)	;
							trace("Response ok at tcp? :",head,connected.toString());		
							dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));				
						}
						
						if(head.indexOf("Content-Type")>-1)
						{
							var contChunks:Array=[];
							var idx:int=0;
							var nm:String="";
							var vl:String="";
							if(head.indexOf("video")>-1)
							{
							 	if(head.indexOf("x-flv")>-1)
								{
								 	streamType= IcecastSocket.TYPE_VIDEO_FLV;
									createFLVStream(320,240,true,_metaData);
								}											
							}
							else if(head.indexOf("audio")>-1)
							{
								contChunks=head.split("\r\n");
								for(var t:int=0;t<contChunks.length;t++)
								{
									idx=String(contChunks[t]).indexOf(":");
									nm=String(contChunks[t]).substr(0,idx);
									if(nm.length){
										vl=String(contChunks[t]).substr(idx+1);										
										
										nm=nm.replace("icy-","");
										if(nm.indexOf("HTTP/1.0")>-1)
											continue;
										if(nm=="metaint"){
											metaInterval=parseInt(vl);
											metaCnt=metaInterval;
										}
										_metaData[nm]=vl;
									}									
								}
								if(_metaData.br)
								reportedBR=_metaData.br*1024/8;								
								else
									reportedBR=128*1024/8;
								
								trace("reportedBR ", reportedBR);
								
								streamType =( head.indexOf("aac") >-1 ) ? TYPE_AUDIO_AAC : TYPE_AUDIO_MPG ;
								
								audioType=(streamType == IcecastSocket.TYPE_AUDIO_AAC ?"AAC":"MP3")
								
								transcoder.loadCodec(audioType);								
								
								createStream(0,0,true,_metaData);													
							}					
						}
						break;
					}					
				}while(serverConnection.bytesAvailable );
				
			}
			
			if(!connected){
				return;
			}
						
			var chunk:ByteArray=new ByteArray();
			
			while(serverConnection.bytesAvailable)
			{
				var fill2:uint=new uint(serverConnection.readByte());
				if(metaInterval)
					metaCnt--;
				
				if( metaInterval>0 && metaCnt == -1)
				{
					readMetaIntData(fill2);
					metaCnt=metaInterval;					
				}
				else
				{
					
					chunk.writeByte(fill2);
					
					if(streamType == IcecastSocket.TYPE_VIDEO_FLV)
					{
						if(chunk.length==4 && !foundHead)
						{
							var n:int=chunk.position-1;
							var guess:uint=chunk[n-3]<<24 | chunk[n-2]<<16 | chunk[n-1]<<8 | chunk[n];
							if(guess == Transcoder.MAGIC_NUMBER )
							{
								foundHead=true;
							}
							else
							{
								trace(n,".");
								var nc:ByteArray=new ByteArray();
								nc.writeBytes(chunk,1);
								chunk.clear();
								chunk=nc;
							}
						}
					}
				}									
			}
			
			if(streamType == IcecastSocket.TYPE_VIDEO_FLV)
			{
				if(!foundHead)
					return;
				chunk.position=0;
				transportStream.appendBytes(chunk);
			}
			
			if(streamType == IcecastSocket.TYPE_AUDIO_AAC || streamType == IcecastSocket.TYPE_AUDIO_MPG)
			{
				
				chunk.position=0;
				
				transcoder.addRawData(chunk, 0 ,audioType);					
			}			
			
		}
		
		
		private function readMetaIntData(fill2:int):void
		{
			if( fill2*16 > 0)
			{						
				var changed:Boolean=false;
				var newMeta:String=""
				var tt:uint=fill2 * 16
				while(tt--)
				{ 
					var mm:uint=serverConnection.readByte()
					newMeta=newMeta+String.fromCharCode(mm);  
				}
				var newMetaChunks:Array=newMeta.split(";");
				while(newMetaChunks.length)
				{
					
					var newProp:String=newMetaChunks.shift();
					var nvp:Array=	newProp.split("=");
					
					if(nvp.length>1)
					{
						if(!_metaData.hasOwnProperty(nvp[0]))
						{
							changed=true;
						}
						else if(_metaData[nvp[0]] != nvp[1])
						{
							changed=true;
						}
						_metaData[nvp[0]]=nvp[1];
					}							
				}
				if(changed)
				{
					reportedBR=_metaData.br*1024/8;
					dispatchEvent(new StreamEvent(StreamEvent.METADATA_CHANGED, _metaData ))
				}
				else
				{
					if(fill2)
						trace(".");
				}
			}			
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
			return "IcecastSocket";
		}
		
		public override function get rawProgress():Number
		{
			return lastChunk / (1024 * 10 );
		}
		
		public override function get parsingProgress():Number
		{
			if(transportStream)
				return transportStream.bufferLength / (bufferTime * 4 );
			else 
				return 0;
		}
		
		public override function get time():Number
		{
			return (transportStream != null)?transportStream.time:0;
		}
		
		public override function close():void
		{
			if(Object(serverConnection).connected)
				Object(serverConnection).close();
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