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

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Type in MType;
import haxe.macro.Type.ClassType;

class AnnotationExtension
{
	private function new() { }
	
	// Intended to be overridden in child class
	public static function transform(input : Dynamic, annotations : Array<Dynamic>, parameters : Array<Dynamic>) : Dynamic 
	{ 
		return input; 
	}
	
	/**
	 * Resolve Haxe metadata input to the form Angular
	 * expects, checking that the fields are of the 
	 * correct type.
	 */
	public static function resolveInputAnnotation<T>(input : Dynamic, outputType : Class<T>) : T
	{
		var output : T;
		
		output = Type.createInstance(outputType, []);
		
		for (field in Reflect.fields(input))
		{
			if (Reflect.hasField(output, field))
			{
				var inputField = Reflect.field(input, field);
				var outputClass = Type.getClass(Reflect.field(output, field));
				
				// If outputClass is null, the output class is most likely Dynamic
				if (Std.is(inputField, outputClass) || outputClass == null)
				{
					Reflect.setField(output, field, Reflect.field(input, field));
				} 
				else 
				{
					var inputClassName : String = Type.getClassName(Type.getClass(inputField));
					var outputClassName : String = Type.getClassName(outputClass);
					Trace.error('Input type of field "${field}" (${inputClassName}) does not match type of output field (${outputClassName}).');
				}
			}
			else 
			{
				Trace.error('${Type.getClassName(outputType)} does not have field "${field}" and as such this field will be ignored.');
			}
		}
		
		return output;
	}
	
	/**
	 * Compile data at build-time rather than run-time.
	 * @return
	 */
	macro static public function compile() : Array<Field>
	{
		var attachedClass : ClassType = Context.getLocalClass().get();
		var attachedMetadata : Metadata = attachedClass.meta.get();
		var fields : Array<Field> = Context.getBuildFields();
		var validAnnotations : Map<String, AnnotationPair> = [
			"Component" => { annotation: ComponentAnnotation, extension: ComponentAnnotationExtension },
			"Directive" => { annotation: DirectiveAnnotation, extension: DirectiveAnnotationExtension },
			"View" 		=> { annotation: ViewAnnotation, extension: ViewAnnotationExtension },
		];
		
		//trace(Context.getType("test.Greeter"));
		
		// Set default values for annotations and parameters fields.
		var annotations : Array<Dynamic> = [];
		var parameters : Array<Dynamic> = [];
		
		for (meta in attachedMetadata) 
		{
			if (["Component", "Directive", "View"].indexOf(meta.name) > -1)
			{
				var data : Dynamic = { };
				var annotationName : String = meta.name;
				
				for (param in meta.params)
				{
					var params : Array<Dynamic> = param.expr.getParameters()[0];
					var i : Int = 0;
					
					// Cast all annotation values at build-time into values
					// we can work with.
					for (paramNames in params)
					{
						var e : Expr = params[i].expr;
						var fieldValue : Dynamic;
						//trace(e);
						// { expr => EConst(CString(greet)), pos => #pos(src/test/HelloWorld.hx:55: characters 11-18) }

						// Cast field values into values that can be worked with.
						fieldValue = switch(e.expr) 
						{
							case EConst(CString(s)): s;
							case EArrayDecl(a) : a;
							case _: e.expr;
						}
						
						// If the field value is an array, all values inside
						// the array must also be converted.
						if (Std.is(fieldValue, Array))
						{
							var array : Array<Dynamic> = fieldValue;
							var j : Int = 0;
							
							for (value in array)
							{
								value = switch(value.expr)
								{
									case EConst(CString(s)): s;
									case _: e.expr;
								}
								
								array[j] = value;
								j++;
							}
							
							fieldValue = array;
						}
						
						Reflect.setField(data, paramNames.field, fieldValue);
						i++;
					}
				}
				
				trace('@${annotationName}(${data})');
				//trace(fields);
				
				Reflect.callMethod(validAnnotations[annotationName].extension, 
									Reflect.field(validAnnotations[annotationName].extension, "transform"), 
									[data, annotations, parameters]);
												
				// annotations.push(Type.createInstance(validAnnotations[name].annotation, [field[0]]));
				
				trace('annotations => ${annotations}');
				trace('parameters => ${parameters}');
			}
		}
		
		// Create annotations and parameters fields
		fields.push({
			name: 'annotations',
			doc: null,
			meta: [],
			access: [AStatic, APublic],
			//kind: FVar(macro : Array<Dynamic>, macro [new angular2haxe.ComponentAnnotation(new angular2haxe.ComponentConstructorData())]),
			kind: FVar(macro : Array<Dynamic>, Context.makeExpr(annotations, Context.currentPos())),
			pos: Context.currentPos()
		});
		
		fields.push({
			name: 'parameters',
			doc: null,
			meta: [],
			access: [AStatic, APublic],
			kind: FVar(macro : Array<Dynamic>, Context.makeExpr(parameters, Context.currentPos())),
			pos: Context.currentPos()
		});
		
		// Create field to note that the class has been
		// constructed at build-time.
		fields.push({
			name: '__alreadyConstructed',
			doc: null,
			meta: [],
			access: [AStatic, APublic],
			kind: FVar(macro : Bool, macro true),
			pos: Context.currentPos()
		});
		
		return fields;
	}
	
	/**
	 * Parse annotation injectors to be used in the Angular, resolving
	 * strings to their respective class/type.
	 * service parameters.
	 * @param	injector	Annotation injector variable (i.e. hostInjector).
	 * @return
	 */
	private static function parseServiceParameters(injector : Array<Dynamic>) : Array<Dynamic>
	{
		var serviceParams : Array<Dynamic> = [];
		var index : Int = 0;
		
		for (app in injector)
		{
			if (app != null && app.length > 0)
			{
				// Resolves to null in macro
				#if !macro
					var cl = Type.resolveClass(app);
				#else
					var cl = Context.toComplexType(Context.getType(app));
				#end
				
				serviceParams.push(cl);
				injector[index] = cl;
			}
			
			index++;
		}
		return serviceParams;
	}
	
	/**
	 * Parses an annotation injector variable. Most of the work in this instance is
	 * deferred to AnnotationExtension.parseServiceParameters.
	 * @param	parameters	Static variable of the same name located in an Angular class.
	 * @param	injector 	The injector variable to parse.
	 */
	private static function parseInjector(parameters : Array<Dynamic>, injector : Array<Dynamic>)
	{
		var serviceParameter : Array<Dynamic> = parseServiceParameters(injector);
		
		if (serviceParameter != null && serviceParameter.length > 0)
		{
			parameters.push(serviceParameter);
		}
	}
	
	/**
	 * Transform lifecycle variable names (String) to Angular
	 * lifecycle variables (JS Object).
	 * @param	lifecycle
	 */
	private static function transformLifecycle(lifecycle : Array<Dynamic>)
	{
		// Transform lifecycle values
		var index : Int = 0;
		
		while (index < lifecycle.length)
		{
			lifecycle[index] = LifecycleEventExtension.toAngular(cast(lifecycle[index], String));
			index++;
		}
	}
}