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
	import com.thebitstream.flv.codec.CodecBase;
	import com.thebitstream.flv.codec.CodecEvent;
	import com.thebitstream.flv.codec.StreamDataEvent;
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.OOBHandler;
	import com.thebitstream.provider.StreamEvent;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLRequest;
	import flash.net.URLStream;
	import flash.utils.ByteArray;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public dynamic class ShoutcastFile extends BaseProvider {
		
		private static const TYPE_VOID:uint=0;
		private static const TYPE_VIDEO:uint=1<<2;
		private var _pump:uint;
		private var streamType:uint=0;
		private var serverConnection:URLStream=new URLStream();
		private var inputStream:BitStream=new BitStream();
		private var transcoder :Transcoder;
		private var frames:Number=-1;
		private var streamWidth:uint;
		private var streamHeight:uint;
		private var videoFramerate:Number=0;
		private var videoType:String;
		private var audioType:String;	
		private var synchronized:Boolean=false;		
		private var transport :NetConnection;
		private var transportStream :NetStream;
		private var transportVideo :Video;
		private var bufferTime:Number=1;
		private var bufferTimeLarge:Number=8;
		
		private var percentLoaded:Number=0;
		private var totalLoaded:Number=0;
		private var lastTagTime:int=0;		
		private var calculatedDuration:Number=0;
		private var _item:XML
		
		public function ShoutcastFile():void
		{			


			addEventListener(Event.ENTER_FRAME, onFrame);

		}
		
		public override function get parsingProgress():Number
		{
			if(transportStream)
			return this.transportStream.bufferLength/(bufferTime*4);
			else
				return 0;
		}
		
		public override function get rawProgress():Number
		{
			return percentLoaded;
		}
		
		public override function get providerPosition():Number//inputStream.avail()/8
		{
			var pcnt:Number = (totalLoaded - (inputStream.avail()/8)) / totalLoaded;
			
			if(pcnt.toString()=="NaN"|| pcnt.toString()=="Infinity")
				pcnt=0;
			if(calculatedDuration.toString()=="NaN" || calculatedDuration.toString()=="Infinity")
				calculatedDuration=0;		
						
			calculatedDuration= (calculatedDuration +  (lastTagTime/pcnt))/2;
			
			var pos:Number=( percentLoaded *  ((transportStream)? transportStream.time:0)/ calculatedDuration) ;
			
			return pos;
		}
		
		public function onFrame(e:Event):void
		{
			pump();
			if(transportStream)
			{				
				if(percentLoaded==1 && (inputStream.avail()/8)< 1024 )
				{					
					if(lastTagTime - transportStream.time <  .9/videoFramerate )
					{						
						removeEventListener(Event.ENTER_FRAME, onFrame);
						dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));
						return;					
					}
				}
			}
		}
		
		public override function initStream(item:XML):void
		{
			this._item=item;
			var uri:String =item.child("uri").toString();
			
			transcoder = new Transcoder();
			transcoder.addEventListener(CodecEvent.STREAM_READY,onChannelReady);
			transcoder.addEventListener(StreamDataEvent.DATA, onTag);
			transcoder.initiate();
			
			serverConnection.addEventListener(ProgressEvent.PROGRESS,loaded);
			serverConnection.addEventListener(Event.CLOSE, onClose);
			serverConnection.addEventListener(IOErrorEvent.IO_ERROR, onError);
			
			serverConnection.load(new URLRequest(uri));
			
		}

		
		private function createStream(Swidth:int=320,Sheight:int=240,hasAud:Boolean=true, meta:Object=null):void{
			
			if(! synchronized )
			{	
				trace("Create stream");
				//removeChild(logo);
				synchronized=true;
				transport = new NetConnection();
				transport.connect(null);
				
				transportStream = new NetStream(transport);
				
				transportStream.bufferTime=bufferTime;
				transportStream.client = this;
				var uri:String =_item.child("uri").toString();
				var chnks:Array=uri.split("/");
				for each(var piece:String in chnks)
				{
					if(piece.indexOf(".nsv")> -1 || piece.indexOf(".NSV")> -1)
					{
						meta.StreamTitle= piece.substr(0,piece.indexOf("."))
					}
				}
					
				if(Swidth)
				{
					meta.canSeekToEnd=true;
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
					transportVideo.x = 0;
					transportVideo.y = 0;					
					addChild(transportVideo);
				}
				
				
				
				transportStream.play(null);			
				
				transportStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
				
				var headerTag:ByteArray=transcoder.createHeader((Swidth==0),hasAud);
				transportStream.appendBytes(headerTag);				
				headerTag.clear();
				
				transcoder.readMetaObject(meta,0);
				
				volume=volume;
			}
		}
		
		private function onTag(sde:StreamDataEvent):void
		{
			if(lastTagTime<sde.timeCode/1000)	
				lastTagTime=sde.timeCode/1000;		
			
			sde.tag.position=0;
			transportStream.appendBytes(sde.tag);
		}
		
		private function onChannelReady(ce:CodecEvent):void
		{
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
			totalLoaded = e.bytesTotal;
			percentLoaded=e.bytesLoaded/e.bytesTotal;


			
			while(serverConnection.bytesAvailable)
			{
				inputStream.addByte(serverConnection.readByte());									
			}			
			
			if(streamType != ShoutcastFile.TYPE_VIDEO)
			{
				streamType=ShoutcastFile.TYPE_VIDEO;			
				dispatchEvent(new StreamEvent(StreamEvent.CONTENT_CHANGED,streamType));	
			}			
		}
		
		private function pump():void
		{
			var def:Number=0;
			var tpf:Number=1 / videoFramerate;
			if((transportStream &&  transportStream.bufferLength > bufferTimeLarge ))
			{				
				def= transportStream.bufferLength - bufferTimeLarge ;
			}
			
			while(( (percentLoaded<1)?( inputStream.avail()/8 >= (1024 * 1024)+ 24 ):(inputStream.avail()/8>1 )   )  &&  !(transportStream &&  transportStream.bufferLength > bufferTimeLarge ))
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
			var al:uint=inputStream.read(16);
			
			if(inputStream.avail()/8 < (vl+al))
				return false;
			
			frames++;
			var i:int=0;
			
			
			while(numAux)
			{
				numAux--;
				var sze:int=  inputStream.readByte() | inputStream.readByte() << 8;
				var tpe:int= inputStream.readByte() | inputStream.readByte() << 8 | inputStream.readByte() << 16 | inputStream.readByte() << 24;
				var auxType:String = String.fromCharCode(tpe & 0xff ,tpe>>8 & 0xff ,tpe>>16 & 0xff, tpe>>24 & 0xff  );
				
				trace("aux :" + auxType)
				total_aux_used+= sze+6;
				var auxData:ByteArray=new ByteArray();
				if(auxType=="ASYN")
				{
					frames=0;
					synchronized=false;
					transcoder.initiate();
					return false;
				}
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
			createStream(streamWidth,streamHeight,(audioType != "NONE"),_metaData);
			
			frames++;
			
			var numAux:uint=inputStream.read(4);
			var vl:uint=inputStream.read(20); 
			var al:uint=inputStream.read(16);
			
			if(inputStream.avail()/8 < (vl+al))
				return false;
			
			
			var i:int=0;
			
			while(numAux)
			{				
				numAux--;
				var sze:int = inputStream.readByte() | inputStream.readByte() << 8;
				var tpe:int = inputStream.readByte() | inputStream.readByte() << 8 | inputStream.readByte() << 16 | inputStream.readByte() << 24;
				
				var auxType:String = String.fromCharCode(tpe & 0xff ,tpe>>8 & 0xff ,tpe>>16 & 0xff, tpe>>24 & 0xff  );
				trace("aux :" + auxType);
				if(auxType=="ASYN")
				{
					frames=0;
					synchronized=false;
					transcoder.initiate();
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
		

				
		public override function get type():String
		{
			return "ShoutcastFile";
		}
		
		public override function get time():Number
		{
			return (transportStream)?transportStream.time:0;
		}
		
		public override function get duration():Number
		{
			return lastTagTime;
		}		
		
		public override function get canSeek():Boolean
		{
			return true;
		}
		
		public override function get providerWidth():int
		{
			return streamWidth;
		}
		
		public override function get providerHeight():int
		{
			return streamHeight;
		}
		
		private function onError(io:IOErrorEvent):void{
			
			dispatchEvent(new StreamEvent(StreamEvent.STATUS_CHANGED,false));		
		}
		
		public override function close():void
		{
		
			if(serverConnection && serverConnection.connected)
			serverConnection.close();
			
			if(!transportStream)
				return;
			
			
			transportStream.close();
			transport.close();
			transportVideo.clear();
			
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
		public override function pauseStream():void
		{
			if(transportStream)
			{
				transportStream.togglePause();
			}
		}		
	}
}