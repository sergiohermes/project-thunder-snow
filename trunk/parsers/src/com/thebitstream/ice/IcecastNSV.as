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
	import com.thebitstream.flv.codec.ASYN;
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.nsv.BitStream;
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.OOBHandler;
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
	public dynamic class IcecastNSV extends BaseProvider {
		
		public static const TYPE_VOID:uint=0;
		public static const TYPE_VIDEO:uint=1<<2;
		
		public var streamType:uint=0;
		
		public var serverConnection:IDataInput;		
		public var request:URLRequest
		public var inputStream:BitStream=new BitStream();
		public var transcoder :Transcoder;
		
		public var frames:Number=0;
		public var streamWidth:uint;
		public var streamHeight:uint;
		public var videoFramerate:Number=0;
		public var videoType:String;
		public var audioType:String;
				
		public var connected:Boolean=false;
		public var synchronized:Boolean=false;
		
		public var transport :NetConnection;
		public var transportStream :NetStream;
		public var transportVideo :Video;
		public var bufferTime:Number=1;
		public var backBufferTime:Number=0;
		
		public var shutDown:Boolean=false;
		public var serverNotice:String="";

		public var totalBytes:int=0;
		public var lastChunk:int=0;
		public var item:XML;
		
		
		public function IcecastNSV()
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

					
			var resource:String ="listen1";
			if(item.child("uri").length())
				resource=item.child("uri").toString();
			

					serverConnection=new URLStream();
					EventDispatcher(serverConnection).addEventListener(ProgressEvent.PROGRESS,loaded);
					URLStream(serverConnection).addEventListener(IOErrorEvent.IO_ERROR, onIo);					
					EventDispatcher(serverConnection).addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
					EventDispatcher(serverConnection).addEventListener(Event.CLOSE, onClose);
					request=new URLRequest(host+resource);
					
					request.requestHeaders=[new URLRequestHeader("GET",resource+" HTTP/1.0")];
					request.requestHeaders=[new URLRequestHeader("Icy-MetaData","1")];
					request.method=URLRequestMethod.GET;
					URLStream(serverConnection).load(request);					
									

			
		}
				
		private function onIo(pe:IOErrorEvent):void
		{
			
		}		

		
		private function onNoPolicy(se:SecurityErrorEvent):void
		{
			trace("onNoPolicy");
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
					
					if(Swidth)
					{
						meta.width=this.streamWidth;
						meta.height=this.streamHeight;
						meta.framerate=this.videoFramerate;					
						if(transportVideo)
						{
							removeChild(transportVideo);
							transportVideo.attachNetStream(null);
							transportVideo=null;
						}
						
						transportVideo= new Video(Swidth,Sheight);
						transportVideo.attachNetStream(transportStream);
						transportVideo.x =0;
						transportVideo.y = 0;					
						addChild(transportVideo);
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
			
			if(ce.codec.flag== CodecBase.FLAG_VIDEO)
			{

				if(ce.codec.flip)
				{
					transportVideo.y = transportVideo.height;
					transportVideo.scaleY = -1;
				}
			}
			
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
			totalBytes += ((e.bytesLoaded));
			lastChunk=serverConnection.bytesAvailable;
			
			
			
			if(shutDown)
			{
				return;
			}	
			
			if(!connected)
			{				
				connected=true;
				dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));				
			}
			
			var traceOut:String="";
			
			while(serverConnection.bytesAvailable)
			{
				var char:uint=serverConnection.readByte();
				inputStream.addByte(char);								
			}	
			
			while(inputStream.avail()/8 > 1024 * 10 )
			{	
				var start:int=inputStream.bitPosition;
				
				var data:uint=new uint(inputStream.read(8));
				
					if(String.fromCharCode(data)=="N")
					{
						
						var data2:uint=new uint(inputStream.read(8));
						
						if(String.fromCharCode(data2)=="S")
						{
							//start++;
							var data3:uint=new uint(inputStream.read(8));
							
							if(String.fromCharCode(data3)=="V")
							{
								// start++;
								var data4:uint=new uint(inputStream.read(8));
								
								if(String.fromCharCode(data4)=="s")
								{
									readKey();									
								}
								else
								{
									start++;									
									inputStream.bitPosition=start;
								}								
							}
							else
							{
								start++;								
								inputStream.bitPosition=start;
							}
						}
						else
						{
							start++;
							inputStream.bitPosition=start;
							
							
							
						}
					}
					else
					{
						if(synchronized && data == 0xef)
						{
							var t:Number=inputStream.bitPosition;
							var data5:uint=new uint(inputStream.read(8));
							if( data5 == 0xbe)
							{								
								readInter()	
							}
							else
							{
								inputStream.bitPosition=t;
							}
						}
						else
						{
							if(synchronized)
							{
								trace(String.fromCharCode(data));
							}
							start++;
							inputStream.bitPosition= start
						}

					}
					
								
			}
			
			
			
			
			
		}
		private function readInter():Boolean{
			
			var total_aux_used:int=0;
			var numAux:uint=inputStream.read(4);
			var vl:uint=inputStream.read(20); 
			
			var i:int=0;
			var al:uint=inputStream.read(16);
			frames++;
			
			var vd:ByteArray=new ByteArray();
			
			while(numAux)
			{
				numAux--;
				var sze:int=  inputStream.readByte() | inputStream.readByte() << 8;
				var tpe:int= inputStream.readByte() | inputStream.readByte() << 8 | inputStream.readByte() << 16 | inputStream.readByte() << 24;
				var auxType:String = String.fromCharCode(tpe & 0xff ,tpe>>8 & 0xff ,tpe>>16 & 0xff, tpe>>24 & 0xff  );
				
				
				
				if(auxType=="ASYN")
				{
					frames=0;
					synchronized=false;
					transcoder.initiate();
					var a:ASYN=new ASYN();
					dispatchEvent(new StreamEvent(StreamEvent.CUEPOINT,{name:a.scriptName,value:null}));
					return false;
				}
				
				total_aux_used+= sze+6;
				var auxData:ByteArray=new ByteArray();
				
				for(var u:int=0;u<sze;u++)
				{
					auxData.writeByte(inputStream.readByte());
				}
				
				transcoder.addRawData(auxData,Number(1000.0/videoFramerate) * frames ,auxType );
			}
			
			if(vl>0)
			{               
				for(i=0;i<vl-total_aux_used;i++)
				{
					vd.writeByte(inputStream.readByte());
				}
				
			}
			
			var ad:ByteArray=new ByteArray();
			if(al>0)
			{
				for(i=0;i<al;i++)
				{
					ad.writeByte(inputStream.readByte());
				}           
			}
			
			vd.position=0;
			ad.position=0;
			
			transcoder.addRawData(ad, Number(1000.0/videoFramerate) * frames ,audioType);
			transcoder.addRawData(vd, Number(1000.0/videoFramerate) * frames ,videoType);
			
			inputStream.gc();
			return true;
		}
		
		private function readKey():Boolean
		{			
			var total_aux_used:int=0;
			videoType=String.fromCharCode(inputStream.readByte(),inputStream.readByte(),inputStream.readByte(),inputStream.readByte());
			audioType=String.fromCharCode(inputStream.readByte(),inputStream.readByte(),inputStream.readByte(),inputStream.readByte());
			streamWidth=inputStream.read(16);
			streamHeight=inputStream.read(16);
			videoFramerate=  BitStream.decodeFramerate(inputStream.read(8));
			var offset:uint=inputStream.read(16);
			if(!synchronized)
			{				
				transcoder.loadCodec(videoType);
				transcoder.loadCodec(audioType);				
			}
			_metaData.name="";
			createStream(streamWidth,streamHeight,(audioType != "NONE"),_metaData);
			
			frames++;
			
			var numAux:uint=inputStream.read(4);
			var vl:uint=inputStream.read(20); 
			var al:uint=inputStream.read(16);
			
			var i:int=0;
			
			while(numAux)
			{				
				numAux--;
				var sze:int = inputStream.readByte() | inputStream.readByte() << 8;
				var tpe:int = inputStream.readByte() | inputStream.readByte() << 8 | inputStream.readByte() << 16 | inputStream.readByte() << 24;
				
				var auxType:String = String.fromCharCode(tpe & 0xff ,tpe>>8 & 0xff ,tpe>>16 & 0xff, tpe>>24 & 0xff  );
				
				if(auxType=="ASYN")
				{
					frames=0;
					synchronized=false;
					transcoder.initiate();
					var a:ASYN=new ASYN();
					dispatchEvent(new StreamEvent(StreamEvent.CUEPOINT,{name:a.scriptName,value:null}));
					return false;
				}
				total_aux_used+= sze+6;
				var auxData:ByteArray=new ByteArray();
				for(var u:int=0;u<sze;u++)
				{
					auxData.writeByte(inputStream.readByte());
				}
				transcoder.addRawData(auxData,Number(1000.0/videoFramerate) * frames ,auxType );
			}		
			
			var vd:ByteArray=new ByteArray();
			if(vl>0)
			{               
				for(i=0;i<vl-total_aux_used;i++)
				{
					vd.writeByte(inputStream.readByte());
				}
			}
			
			var ad:ByteArray=new ByteArray();
			if(al>0)
			{
				for(i=0;i<al;i++)
				{
					ad.writeByte(inputStream.readByte());
				}           
			}               			
			
			vd.position=0;
			ad.position=0;			
			
			transcoder.addRawData(ad, Number(1000.0/videoFramerate) * frames ,audioType);
			
			transcoder.addRawData(vd,  Number( 1000.0/ videoFramerate) *  frames  ,videoType);
			
			inputStream.gc();
			return true;
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
			return "IcecastNSV";
		}
		public override function get rawProgress():Number
		{
			
			return lastChunk/ 10000;
		}
		public override function get parsingProgress():Number
		{
			
			(inputStream.avail()/8 )// 1024 * 24
			
			return  ((inputStream.avail()/8)  /  (1024 * 24) >1)?1:(inputStream.avail()/8)  /  (1024 * 24);
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