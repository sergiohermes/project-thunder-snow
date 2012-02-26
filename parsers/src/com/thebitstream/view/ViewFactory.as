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
package com.thebitstream.view
{

	import flash.utils.getDefinitionByName;
	/**
	 * 
	 * @author Andy Shaules
	 * 
	 */
	public class ViewFactory
	{
		public static var views:Array=[];

		public static function createProjector(name:String):IProject{
			var pth:String="com.thebitstream.view."+name;			
			var cls:Class=flash.utils.getDefinitionByName(pth) as Class;
			var ret:IProject=new cls();
			return ret;
		}
	}
}