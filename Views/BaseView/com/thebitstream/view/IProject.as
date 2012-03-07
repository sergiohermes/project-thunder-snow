
package com.thebitstream.view
{
	import com.thebitstream.control.IControl;
	
	import flash.display.DisplayObject;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public interface IProject
	{
		/**
		 * Name of class.
		 * @return 
		 * 
		 */		
		function get type():String;
		/**
		 * Sets the provider object.
		 * <p> The projector should show the displayobject from Point(0,0) to Point(providerWidth,providerHeight)</p> 
		 * @param prov
		 * 
		 */		
		function set provider(prov:DisplayObject):void;
		/**
		 * Sets the width of the presentation visual data. 
		 * @param val
		 * 
		 */		
		function set providerWidth(val:Number):void;
		/**
		 * Sets the height of the presentation visual data. 
		 * @param val
		 * 
		 */			
		function set providerHeight(val:Number):void;
		/**
		 * Sets the current presentation play-head stream time in seconds. 
		 * @param val
		 * 
		 */		
		function set time(val:Number):void;
		
		/**
		 * Sets the progress of the data that has been read into flv format. 
		 * @param val 0 to 1;
		 * 
		 */		
		function set parsingProgress(val:Number):void;
		
		/**
		 * Sets the progress of the stream reading into the buffer for parsing. 
		 * @param val 0 to 1
		 * 
		 */		
		function set rawProgress(val:Number):void;
		
		/**
		 * Sets the current play back position in the stream.<p>Non-seekable live or file streams may not indicate a position</p> 
		 * @param val 0 to 1
		 * 
		 */		
		function set position(val:Number):void;
		
		/**
		 * Sets if the current presentation can seek. 
		 * @param val 
		 * 
		 */		
		function set canSeek(val:Boolean):void;
		
		/**
		 * Sets the controller client for current presentation play/pause/seek/next control. 
		 * @param val
		 * 
		 */		
		function set controlClient(val:IControl):void;
		
		/**
		 * Sets the metadata for the current presentation. 
		 * @param val
		 * 
		 */		
		function set metaData(val:Object):void;
		
		/**
		 * Sets the current playlist as loaded by the controller.<p>Basic playlist handling is not required by the projector.</p> 
		 * @param val
		 * 
		 */		
		function set playList(val:XMLList):void;
		
		/**
		 * Sets the current item being loaded by the controller. 
		 * @param val
		 * 
		 */		
		function set playListItem(val:XML):void;
		
		/**
		 * Called when a scriptdata event is called from the flv stream.
		 * <p>Subtitles from the nsv stream will arrive as cue points.</p> 
		 * 
		 * @param val Object with name and value properties of the cue point.
		 * 
		 */		
		function onScriptData(val:Object):void;
	}
	
}