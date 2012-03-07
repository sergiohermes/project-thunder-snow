
package com.thebitstream.provider
{
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public interface IProvide
	{
		
		function initStream(item:XML):void;
		function close():void;
		function set volume(val:Number):void
		function get volume():Number;
		function get metaData():Object;
		function get content():String;
		function get type():String;
		function get providerWidth():int;
		function get providerHeight():int;
		function get time():Number;
		function get rawProgress():Number;
		function get parsingProgress():Number;
		function get providerPosition():Number;
		function get duration():Number;
		function get canSeek():Boolean;
		function seekStream(position:Number):void;
		function playStream(position:Number=0):void;
		function stopStream():void;
		function pauseStream():void;
	}
}