
package com.thebitstream.control
{
	import com.thebitstream.provider.IProvide;

	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public interface IControl
	{
		function playItem(item:int):void;
		function playNext():void;
		function playStream(position:Number=0):void;
		function seekStream(position:Number):void;
		function stopStream():void;
		function pauseStream():void;
		function set volume(val:Number):void;
		function get volume():Number;
		function get itemLoader():ItemLoader;
	}
}