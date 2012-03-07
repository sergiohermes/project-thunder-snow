
package com.thebitstream.control
{
	import com.thebitstream.provider.IProvide;
	
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public class Control implements IControl
	{
		private var _provider:IProvide;
		
		private var loader:ItemLoader;
		
		public function Control(load:ItemLoader,prov:IProvide)
		{
			loader=load;
			_provider=prov;
		}

		public function playItem(item:int):void
		{
			_provider.close();
			loader.playItem(item);
		}
		
		public function playNext():void
		{
			_provider.close();
			loader.playNext();			
		}
		
		public function playStream(position:Number=0):void
		{
			_provider.playStream(position);			
		}
		
		public function seekStream(position:Number):void
		{
			_provider.seekStream(position);
		}
		
		public function stopStream():void
		{
			_provider.stopStream();
		}
		
		public function pauseStream():void
		{
			_provider.pauseStream();
		}
		
		public function set volume(val:Number):void
		{
			_provider.volume=val;
		}
		
		public function get volume():Number
		{
			return _provider.volume;
		}
	}
}