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
	import flash.display.Loader;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	internal class ExternalLib
	{
		private var _loader:Loader;
		
		private var _req:URLRequest;
		
		public function ExternalLib(loader:Loader, req:URLRequest)
		{
			_loader=loader;
			_req=req			
		}
		
		internal function load():void
		{
			_loader.load(_req,new LoaderContext(false,ApplicationDomain.currentDomain))
		}

		internal function get loader():Loader
		{
			return _loader;
		}

	}
}