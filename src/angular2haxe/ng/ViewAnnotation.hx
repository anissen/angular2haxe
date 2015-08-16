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
package angular2haxe.ng;
import angular2haxe.Annotation;
import angular2haxe.ng.ViewConstructorData;

@:native('ng.ViewAnnotation')
extern class ViewAnnotation extends Annotation
{
	function new(data : ViewConstructorData);
}