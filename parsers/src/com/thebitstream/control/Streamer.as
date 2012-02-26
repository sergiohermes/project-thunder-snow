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
package com.thebitstream.control
{
	import com.thebitstream.provider.BaseProvider;
	import com.thebitstream.provider.IProvide;
	import com.thebitstream.provider.ProviderLoader;
	import com.thebitstream.provider.StreamEvent;
	import com.thebitstream.provider.StreamFactory;
	import com.thebitstream.view.IProject;
	import com.thebitstream.view.ProjectorLoader;
	import com.thebitstream.view.ViewFactory;
	
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;

	/**
	 * Dispatched when an item has been opened.
	 */	
	[Event(type="flash.events.Event",name="open")]
	/**
	 * Dispatched when an item has closed.
	 */	
	[Event(type="flash.events.Event",name="close")]
	/**
	 * Dispatched at the end of the playlist.
	 */	
	[Event(type="flash.events.Event",name="complete")]
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class Streamer extends EventDispatcher implements ItemLoader
	{
		protected var ticker:uint=0;
		
		protected var loader:ProviderLoader;
		
		protected var provider:BaseProvider;
		
		protected var projector:IProject;
		
		protected var controler:IControl;		
		
		protected var providerType:String;
				
		protected var playlistLoader:URLLoader;
		
		protected var _list:XMLList;
		
		protected var _nextItem:int=0;
		
		protected var codecsToLoad:int=0;	
		
		protected var viewsToLoad:int=0;
		
		protected var currentItem:XML;
		
		protected var autoPlay:Boolean=false;
		
		public function Streamer()
		{
			super();			
		}
				
		public function loadPlaylist(file:String="playlist.xml"):void
		{
			playlistLoader=new URLLoader()
			playlistLoader.addEventListener(Event.COMPLETE,onPlaylist);
			playlistLoader.load(new URLRequest(file));	
		
		}
		
		private function onFrame(e:Event=null):void
		{
			if(provider && projector)
			{
				projector.position=provider.providerPosition;
				projector.time=provider.time;
				projector.parsingProgress=provider.parsingProgress;
				projector.rawProgress=provider.rawProgress;
				projector.time=provider.time;
			}
		}
		
		public function get nextItem():int
		{
			return _nextItem
		}
		
		public function set nextItem(val:int):void
		{
			_nextItem=val;
		}		
		/**
		 * Does not return the codec or projector elements. 
		 * @return The items to play in the list.
		 * 
		 */		
		public function get list():XMLList
		{
			return _list;
		}
		/**
		 * Manually set the contents of an xml playlist, including views and codecs. 
		 * @param val 
		 * 
		 */		
		public function set list(val:XMLList):void
		{
			processList(val);
		}
		
		private function onPlaylist(e:Event):void
		{
			list=XMLList(playlistLoader.data)
			
		}
		
		private function processList(items:XMLList):void
		{	
			var loadTime:String=new Date().time.toString();
			
			autoPlay = (items.descendants("autoPlay").length() && items.descendants("auto").toString() == true );
			
			_list=items.descendants("item");
			var isLoading:Boolean;
			var libLoader:LoaderQue=new LoaderQue();
			libLoader.addEventListener(Event.COMPLETE, onQueComplete);
			
			if(items.descendants("projector").length()>0)
			{
				for(var i:int=0; i<items.descendants("projector").length() ;i++)
				{
					isLoading=true;
					viewsToLoad++;					
					var xml:XML=items.descendants("projector")[i];
					var viewLoader:ProjectorLoader=new ProjectorLoader(xml);
					viewLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onViewLoaded);
					var externalView:ExternalLib=new ExternalLib(viewLoader,
						new URLRequest(xml.child("uri").toString()+"?"+loadTime));
					libLoader.addItem(externalView);	
				}				
			}
			
			if(items.descendants("codec").length()>0)
			{
				for(var j:int=0; j<items.descendants("codec").length() ;j++)
				{
					isLoading=true;
					codecsToLoad++;
					var xml2:XML=items.descendants("codec")[j];
					var codecLoader:Loader;
					codecLoader=new Loader();
					codecLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onCodecsLoaded);
					var externalCodec:ExternalLib=new ExternalLib(codecLoader,
						new URLRequest(xml.child("uri").toString()+"?"+loadTime));
					libLoader.addItem(externalCodec);
				}
			}
			
			if(!isLoading)
			{
				playNext();
			}else{
				libLoader.startLoad();
			}			
		}
		
		private function onQueComplete(e:Event):void
		{
			flash.utils.setTimeout(playNext,500);
		}
		
		private function onViewLoaded(e:Event):void
		{
			trace("onViewLoaded");
			
			ViewFactory.views.push(e.currentTarget.loader.view);
			e.currentTarget.loader.unload();	
		}		
		private function onCodecsLoaded(e:Event):void
		{
			
			if( (--codecsToLoad) == 0 && viewsToLoad==0)
			{
				
				//playNext();
			}
		}
		
		public function playItem(item:int):void
		{
			if( list.length() > item )
			{
				_nextItem=item;
				playNext();
			}
		}
		public function close():void
		{
			if(provider)
			{				
				
				provider.removeEventListener(StreamEvent.STATUS_CHANGED,onStream);
				provider.removeEventListener(StreamEvent.CONTENT_CHANGED, onStream);
				provider.removeEventListener(StreamEvent.METADATA_CHANGED, onStream);
				provider.removeEventListener(StreamEvent.CUEPOINT, onStream);
				provider.close();
				provider=null;
			}

		}
		
		public function playNext():void
		{
			
			if(provider)
			{				
				
				provider.removeEventListener(StreamEvent.STATUS_CHANGED,onStream);
				provider.removeEventListener(StreamEvent.CONTENT_CHANGED, onStream);
				provider.removeEventListener(StreamEvent.METADATA_CHANGED, onStream);				
				provider.removeEventListener(StreamEvent.CUEPOINT, onStream);
				provider.close();
				provider=null;
			}
			if(projector)
			{
				flash.utils.clearInterval(ticker);
				ticker=0;
				//EventDispatcher(projector).removeEventListener(Event.ENTER_FRAME, onFrame);
				dispatchEvent(new Event(Event.CLOSE));
				projector=null;
			}			

			
			if( list.length() > _nextItem )
			{
				trace("playing item "+_nextItem);
				currentItem=list[_nextItem++];
				providerType=currentItem.child("provider").toString();				
				var projectorType:String=currentItem.child("view").toString();				
				projector=ViewFactory.createProjector(projectorType);			
				projector.playListItem=currentItem;
				projector.playList=list;
				projector.position=0;
				projector.parsingProgress=0;
				
			}
			else
			{	
				trace("End of playlist");
				
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			
			provider = StreamFactory.createStreamer(providerType);	
			
			if(provider == null)
			{
				loader=new ProviderLoader(providerType);
				loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onProviderLoaded);
				loader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onProviderError);
				loader.load(new URLRequest(providerType+".swf"+"?"+new Date().time),new LoaderContext(false,ApplicationDomain.currentDomain));
			}
			else
			{
				configureProvider();
			}
		}
		
		private function onProviderError(e:Event):void
		{	
			trace("No provider");		
			if(autoPlay)
			playNext();
		}
		
		private function onProviderLoaded(e:Event):void
		{
			trace("Provider Loaded");
			StreamFactory.importStreamer(loader.type,loader.provider);
			
			loader.unload();
			
			provider = StreamFactory.createStreamer(loader.type);	
			
			configureProvider();
		}
		
		private function configureProvider():void
		{			
			if(provider)
			{				
				
				provider.addEventListener(StreamEvent.STATUS_CHANGED,onStream);
				provider.addEventListener(StreamEvent.CONTENT_CHANGED, onStream);
				provider.addEventListener(StreamEvent.METADATA_CHANGED, onStream);
				provider.addEventListener(StreamEvent.CUEPOINT, onStream);
				provider.initStream(currentItem);				

//				projector.providerWidth=
//				projector.providerHeight=
				projector.canSeek=provider.canSeek;
				projector.provider=provider;
			
				controler=new Control(this,provider);
				projector.controlClient=controler;
				ticker=flash.utils.setInterval(onFrame,1000);
				//EventDispatcher(projector).addEventListener(Event.ENTER_FRAME, onFrame);
				dispatchEvent(new Event(Event.OPEN));
			}			
		}
		
		private function onStream(se:StreamEvent):void
		{		
			switch(se.type)
			{
				case StreamEvent.STATUS_CHANGED:					
					if(!se.data)
					{
						if(autoPlay)
							playNext();
					}
					break;
				
				case StreamEvent.METADATA_CHANGED:
					if(projector)
					{
						projector.providerHeight=provider.providerHeight;
						projector.providerWidth=provider.providerWidth;					
						projector.metaData=se.data;
					}
					break;
				
				case StreamEvent.CUEPOINT:
					if(projector)
					{
						projector.onScriptData(se.data);
					}
					break;
				
			}
		}
		
		public function get itemProjector():IProject
		{
			return projector
		}
		
		public function get itemProvider():IProvide
		{
			return provider
		}
		
		public function get itemControler():IControl
		{
			return controler;
		}		
	}
}