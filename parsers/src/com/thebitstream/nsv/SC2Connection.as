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
package com.thebitstream.nsv
{
	
import flash.errors.*;
import flash.events.*;
import flash.net.Socket;

	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */	
	public class SC2Connection extends Socket 
	{
		public var context:Object={};
		
		public function SC2Connection(host:String = null, port:uint = 8000,resource:String="listen1") 
		{
			context.host=host;
			context.port=port;
			context.resource=resource;
			super(host, port);
			
			addEventListener(Event.CONNECT, connectHandler);
		}
		
		public override function connect(host:String, port:int):void
		{
			context.host=host;
			context.port=port;			
			super.connect(host,port);
		}		
		private function writeln(str:String):void 
		{			
			try 
			{
				writeUTFBytes(str);
			}
			catch(e:IOError) 
			{
				trace(e);
			}
		}
		
		private function sendRequest():void 
		{
			writeln("GET "+context.resource+" HTTP/1.0\r\n"+
				"User-Agent: Thunder Snow/1.1\r\n"+				
				"Ultravox-transport-type: TCP\r\n"+
				"Accept: */*\r\n"+
				"Icy-MetaData:1\r\n"+
				"\r\n"
				
			);
			
			flush();
		}
		
		private function connectHandler(event:Event):void 
		{
			sendRequest();
		}
	}
}