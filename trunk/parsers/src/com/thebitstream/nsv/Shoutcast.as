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
package com.thebitstream.nsv {
	
	import com.thebitstream.flv.Transcoder;
	import com.thebitstream.flv.codec.ASYN;
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.OOBHandler;
	import com.thebitstream.provider.StreamEvent;
	
	import flash.errors.EOFError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.FileReference;
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
	public dynamic class Shoutcast extends BaseProvider {
		
		public static const TYPE_VOID:uint=0;
		public static const TYPE_AUDIO_AAC:uint=1;
		public static const TYPE_AUDIO_MPG:uint=1<<1;
		public static const TYPE_VIDEO:uint=1<<2;
	
		public var streamType:uint=0;
		
		public var serverConnection:IDataInput;		
		public var lastChunk:int=0;
		public var inputStream:BitStream=new BitStream();
		public var transcoder :Transcoder;
		
		public var frames:Number=0;
		public var streamWidth:uint;
		public var streamHeight:uint;
		public var videoFramerate:Number=15;
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
		
		public var metaInterval:int=0;
		public var metaCnt:int=0;
		public var metaSize:int=0;
		
		public var reportedBR:int=0;
		public var hasVid:Boolean;
		
		public var buffer:Array=[];
		
		public function Shoutcast():void
		{

			addEventListener(Event.ENTER_FRAME, onFrame);
		}
		private function onFrame(e:Event):void
		{

		}
		public override function initStream(item:XML):void
		{
			
			transcoder = new Transcoder();
			transcoder.addEventListener(CodecEvent.STREAM_READY,onChannelReady);
			transcoder.addEventListener(StreamDataEvent.DATA, onTag);
			transcoder.initiate();
			
			shutDown=false;
			
			var connection:String ="tcp";
			if(item.child("connection").length())
				connection=item.child("connection").toString();
			
			if(item.child("policy").length())
				Security.loadPolicyFile(item.child("policy").toString());
			
			var host:String ="";
			if(item.child("host").length())
				host=item.child("host").toString();
			
			var port:String ="8000";
			if(item.child("port").length())
				port=item.child("port").toString();
			
			var resource:String ="listen1";
			if(item.child("uri").length())
				resource=item.child("uri").toString();
			trace();
			switch(connection ){
				case "tcp":
					serverConnection=new URLStream();
					EventDispatcher(serverConnection).addEventListener(ProgressEvent.PROGRESS,loaded);
					URLStream(serverConnection).addEventListener(IOErrorEvent.IO_ERROR, onIo);
					EventDispatcher(serverConnection).addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
					EventDispatcher(serverConnection).addEventListener(Event.CLOSE, onClose);
					var request:URLRequest=new URLRequest(resource);
					request.method=URLRequestMethod.GET;
					request.requestHeaders=[new URLRequestHeader("Ultravox-transport-type","TCP")]
					URLStream(serverConnection).load(request);					
									
					break;
				
				case "socket":
					serverConnection=new SC2Connection(host,parseInt(port),resource);
					EventDispatcher(serverConnection).addEventListener(SecurityErrorEvent.SECURITY_ERROR, onNoPolicy);
					SC2Connection(serverConnection).addEventListener(IOErrorEvent.IO_ERROR, onIo);					
					EventDispatcher(serverConnection).addEventListener(ProgressEvent.SOCKET_DATA,loaded);
					EventDispatcher(serverConnection).addEventListener(Event.CLOSE, onClose);
					SC2Connection(serverConnection).connect(host,parseInt(port));					
					break;	
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
					else
					{
						videoFramerate=10;
						
					}
					
					transportStream.play(null);				
					transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
					
					var headerTag:ByteArray=transcoder.createHeader((Swidth==0),hasAud);
				
					transportStream.appendBytes(headerTag);				
					headerTag.clear();
					
					transcoder.readMetaObject(meta,0);
					if(buffer.length){
						while(buffer.length)
							transportStream.appendBytes(buffer.shift());
					}
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
			if(!transportStream){
				return;
			}
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
			trace("onMetaData -");
			//if(e.hasOwnProperty("metaint") && !e.hasOwnProperty("StreamTitle"))
			//	return;
			
			dispatchEvent(new StreamEvent(StreamEvent.METADATA_CHANGED,e));
		}

		private function loaded(e:ProgressEvent):void
		{			
			
			totalBytes += ((e.bytesLoaded));
			if(shutDown)
			{
				return;
			}
			
			lastChunk=serverConnection.bytesAvailable;
			
			if(!connected || streamType==0)
			{
				trace("_____________",connected,streamType);
				var char:String="";
				var head:String="";
				
				do{					
					try{
					char = String.fromCharCode(serverConnection.readByte());
					}catch(e:EOFError){
						trace(e.getStackTrace());
						dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));				
						return;
					}
					
					head=head.concat( char);					
					if(head.indexOf("\r\n\r\n")>-1)
					{	

						
						if(head.indexOf("content-type")>-1)
						{
							var contChunks:Array=[];
							var idx:int=0;
							var nm:String="";
							var vl:String="";
							
							if(head.indexOf("audio")>-1)
							{
								contChunks=head.split("\r\n");
								for(var t:int=0;t<contChunks.length;t++)
								{
									idx=String(contChunks[t]).indexOf(":");
									nm=String(contChunks[t]).substr(0,idx);
									if(nm.length){
										vl=String(contChunks[t]).substr(idx+1);
										
										
										nm=nm.replace("icy-","");
										
										if(nm=="metaint"){
											metaInterval=parseInt(vl);
											metaCnt=metaInterval;
										}
										_metaData[nm]=vl;
									}									
								}
								reportedBR=_metaData.br*1024/8;								
								
								trace("reportedBR ", reportedBR);
								
								streamType =( head.indexOf("aac") >-1 ) ? TYPE_AUDIO_AAC : TYPE_AUDIO_MPG ;
							
								audioType=(streamType == Shoutcast.TYPE_AUDIO_AAC ?"AAC":"MP3")
								transcoder.loadCodec(audioType);
								
								if(!connected )
								{
									trace("Response ok at tcp? :",head);											
									connected=(head.indexOf("OK") > -1)				
									dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));				
								}
								
								createStream(0,0,true,_metaData);	
								
								break;
							}
							else if(head.indexOf("video")>-1)
							{
								contChunks=head.split("\r\n");
								for( var j:int =0; j<contChunks.length; j++)
								{
									idx=String(contChunks[j]).indexOf(":");
									if(idx>-1)
									{
										nm=String(contChunks[j]).substr(0,idx);
										
										if(nm.length)
										{
											vl=String(contChunks[j]).substr(idx+1);
											nm=nm.replace("icy-","");
											if(nm=="metaint")
											{
												metaInterval=parseInt(vl);
												metaCnt=metaInterval;
											}
											_metaData[nm]=vl;
										}
									}									
								}
								reportedBR=_metaData.br*1024/8;									
								trace("reportedBR ", reportedBR);
								
								if(!connected )
								{
									trace("Response ok at tcp? :",head);		
									connected=(head.indexOf("OK") > -1)				
									dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));				
								}								
								streamType =TYPE_VIDEO ;
								
								break;								
							}							
						}						
					}					
				}while(serverConnection.bytesAvailable );				
			}
			
			if(!connected )
			{
				trace("Response ok @ socket? :",head);											
				connected=(head.indexOf("OK") > -1)				
				dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));
				
			}	
			
			if(!connected || streamType==0)
			{
				return;
			}
			
			while(serverConnection.bytesAvailable > 1024 * 10)
			{
				var byte:uint=0;
				
				if(! inMeta)
					 byte= serverConnection.readByte();
				
				
				
				if(metaInterval)
				metaCnt--;
				
				if( metaInterval>0 && metaCnt <= -1)
				{
					if(metaCnt==-1)
					{
						metaSize=byte*16;
					}
					
					if(metaSize==0){
						metaCnt=metaInterval;
						return
						
					}
					else if(metaSize> 0 &&  serverConnection.bytesAvailable >= metaSize  )
					{
						if(readMetaIntData())
						{
							metaSize=0;
							metaCnt=metaInterval;
						}
						
						return;
					}
					
					
				}
				else
				{
					inputStream.addByte(byte);
					
					//if(inputStream.avail()/8 > ((1024 * 1024)  + 24 )){
					//	break;
					//}
				}									
			}			
			
			var pos:int=0;
			while(inputStream.avail()/8 > 1024 )
			{
				if(!synchronized)
				{
					if(!pos)
					{					
						pos=inputStream.bitPosition;						
					}
					else
					{					
						pos++;
						inputStream.bitPosition=pos;
					}					
				}
				
				if(streamType==Shoutcast.TYPE_VIDEO)
				{
					var magicNumber:uint= 0x4e | 0x53<<8 | 0x56<<16 | 0x73<<24;
					var guess:uint=inputStream.read(32);	
					
					if( guess==magicNumber)
					{							
						var kRes:Boolean=readKey();
						if(!kRes)
							break;
						
						continue;
					}
					else
					{						
						if(synchronized)	
						{										
							inputStream.seek(-32)
						}
						else
						{
							inputStream.seek(-31)
						}
					}
					
					if(synchronized)
					{
						magicNumber= 0xef | 0xbe <<8 ;
					
						guess=inputStream.read(16);	
					
						if( guess == magicNumber)
						{							
							var res:Boolean=readInter();
							if(!res)
								break;
							continue;
						}
						else
						{					
							inputStream.seek(-15);
						}				
					}					
				}
				else if(streamType == Shoutcast.TYPE_AUDIO_AAC || streamType == Shoutcast.TYPE_AUDIO_MPG)
				{
					var chunk:ByteArray=new ByteArray();
					
					while(inputStream.avail())
					{
						chunk.writeByte(inputStream.readByte());
					}
					
					chunk.position=0;
					transcoder.addRawData(chunk, 0 ,(streamType == Shoutcast.TYPE_AUDIO_AAC ?"AAC":"MP3"));
					inputStream.clear();
				}
			}			
		}
		
		private function readInter():Boolean{
			
			var total_aux_used:int=0;
			var numAux:uint=inputStream.read(4);
			var vl:uint=inputStream.read(20); 
			var al:uint=inputStream.read(16);
			var i:int=0;
			if(inputStream.avail()/8 < vl+al)
			{
				inputStream.seek(( - 8 * 7));
				
				return false;
			}
			
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
					dispatchEvent(new StreamEvent(StreamEvent.CUEPOINT,{name:new ASYN().scriptName,value:null}));
					return true;
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
			var ct:String;
			var at:String;
			
			ct=String.fromCharCode(inputStream.readByte(),inputStream.readByte(),inputStream.readByte(),inputStream.readByte());
			at=String.fromCharCode(inputStream.readByte(),inputStream.readByte(),inputStream.readByte(),inputStream.readByte());
			
			if(!videoType && !audioType){
				videoType=ct;
				audioType=at;
			}
			else if(videoType != ct && audioType != at)
			{
				return true;//todo
			}
			
			streamWidth=inputStream.read(16);
			streamHeight=inputStream.read(16);
			videoFramerate=  BitStream.decodeFramerate(inputStream.read(8));
			var offset:uint=inputStream.read(16);
			
			
			if(!synchronized)
			{				
				transcoder.loadCodec(videoType);
				transcoder.loadCodec(audioType);				
				createStream(streamWidth,streamHeight,(audioType != "NONE"),_metaData);
			}
			frames++;
			
			var numAux:uint=inputStream.read(4);
			var vl:uint=inputStream.read(20); 
			var al:uint=inputStream.read(16);
			
			var i:int=0;
			if(inputStream.avail()/8 < vl+al)
			{
				
				inputStream.seek((-8 * 24));
				return false;
			}
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
					dispatchEvent(new StreamEvent(StreamEvent.CUEPOINT,{name:new ASYN().scriptName,value:null}));
					return true;
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
		
		private function readMetaIntData():Boolean
		{	
			
			
			if( metaSize > 0)
			{				
				trace("readMetaIntData size: "+(metaSize)+ " available: " +   serverConnection.bytesAvailable.toString());
				
				var changed:Boolean=false;
				var newMeta:String=""
				var tt:int=metaSize
				
				while(tt--)
				{ 
					var mm:uint=serverConnection.readByte()
					newMeta=newMeta+String.fromCharCode(mm);  
				}
				
				trace("meta read :\n\n\t"+newMeta+"\n\n");
				
				var newMetaChunks:Array=newMeta.split(";");
				while(newMetaChunks.length)
				{
					
					var newProp:String=newMetaChunks.shift();
					var nvp:Array=	newProp.split("=");
					//trace(decode(nvp[0]));
					//trace(decode(nvp[1]));
					//trace(nvp);
					if(nvp.length>1)
					{
						nvp[0]=nvp[0].replace("'","");
						nvp[1]=String(nvp[1]).substr(1,String(nvp[1]).length-2);
					//TODO
		//StreamUrl='&artist=Ludo&title=Girls%20on%20Trampolines&album=Ludo&duration=205296&songtype=S&overlay=NO&buycd=&website=&picture=';				
						if(nvp[0]=="StreamUrl"&& nvp[1].length)
						{
							
							var out2:String=decode(nvp[1].toString());
							
							var ss:Array=out2.split("&");
							
							for (var j:int=0;j<ss.length;j++){
								
								ss[j]=decode(ss[j]);
								
							}						
							
							nvp[1]=ss.toString();
						}								
						
						_metaData[nvp[0]]=nvp[1];
					}							
				}
					transcoder.readMetaObject(_metaData);
					reportedBR=_metaData.br*1024/8;		
					
			}			
			return true;
		}
		public function decode(s2:String):String
		{
			
			var out:String="";
			for(var i:int=0; i<s2.length; i++){
				if(s2.charAt(i)=="%"){
					
					var val:uint=new uint( String( "0x"+s2.charAt(++i)+ s2.charAt(++i)));
					
					out = out+ String.fromCharCode(val);
					
				}else{
					
					out = out+ s2.charAt(i);
				}
			}	
			return out;
			
		}
		private function onIo(pe:IOErrorEvent):void
		{			
		}
		
		private function onNoPolicy(se:SecurityErrorEvent):void
		{
			trace("No Policy");
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));
		}
		private function onError(io:IOErrorEvent):void
		{
			if(!connected)
			{
				dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,connected));
			}
		}
		private function get inMeta():Boolean{
			return ( metaCnt < -1 )&& (metaInterval>0) ;
		}
		
		public override function get providerWidth():int
		{
			return streamWidth;
		}
		
		public override function get providerHeight():int
		{
			return streamHeight;
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
			return "Shoutcast";
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
			if(transportVideo)
				transportVideo.clear();			
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