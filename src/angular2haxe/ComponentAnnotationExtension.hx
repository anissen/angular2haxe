/*
Copyright 2015 Niall Frederick Weedon

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
package angular2haxe;

class ComponentAnnotationExtension extends AnnotationExtension
{
	public function new() 
	{
		super();
	}
	
	public static function transform(input : Dynamic, annotations : Array<Dynamic>, parameters : Array<Dynamic>) : Dynamic
	{
		// Transform appInjector to resolve to the
		// correct JavaScript classes.
		if (parameters != null && input.appInjector != null)
		{
			var serviceParams : Array<Dynamic> = [];
			
			for (app in Reflect.fields(input.appInjector))
			{
				var appName : String = Reflect.field(input.appInjector, app);
				
				if (appName != null && appName.length > 0)
				{
					var cl = Type.resolveClass(appName);
					serviceParams.push(cl);
					Reflect.setField(input.appInjector, app, cl);
				}
			}
			
			if (serviceParams.length > 0)
			{
				parameters.push(serviceParams);
			}
		}
		
		return input;
	}
}