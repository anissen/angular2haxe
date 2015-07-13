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
package test;

import angular.Angular;
import angular.AngularElement;

/*
 * Reference:
 * https://angular.io/docs/js/latest/guide/displaying-data.html
 */

@Component({ 
	selector: 'display',
	appInjector: ["test.FriendsService"]
})
@View({ 
	directives: ["angular.NgFor", "angular.NgIf"],
	template: '<p>My name: {{ myName }}</p><p>Friends:</p><ul><li *ng-for="#name of names">{{ name }}</li></ul><p *ng-if="names.length > 3">You have many friends!</p>'
})
class DisplayComponent extends AngularElement
{
	private static var annotations : Array<Dynamic> = [];
	private static var parameters : Array<Dynamic> = [];
	private var myName : String;
	private var names : Array<String>;
	
    public function new(?friends : FriendsService)
    {
        super(annotations, parameters);
		myName = "Alice";
		
		if (friends != null)
		{
			names = friends.names;
		}
    }
}