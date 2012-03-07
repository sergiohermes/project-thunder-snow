
package com.thebitstream.control
{
	import com.thebitstream.provider.IProvide;
	import com.thebitstream.view.IProject;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public interface ItemLoader
	{
		function loadPlaylist(file:String="playlist.xml"):void
		function playItem(item:int):void;
		function playNext():void;
		function close():void;
		function set list(val:XMLList):void;
		function get list():XMLList;
		function get nextItem():int;
		function set nextItem(val:int):void;
		function get itemProjector():IProject;
		function get itemProvider():IProvide;
		function get itemControler():IControl;
	}
}