//
// auto-synthesis-disallowed.m: test objc_requires_property_definitions
// synthaway
//
// Copyright (c) 2012 Inkling Systems, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <Foundation/Foundation.h>

// if a class (e.g. NSManagedObject) is annotated with the attribute
// objc_requires_property_definitions, auto property synthesis is disabled
// for it and its subclasses
#if __has_attribute(objc_requires_property_definitions)
__attribute__((objc_requires_property_definitions))
#else
#endif
@interface Foo : NSObject
@property (retain) NSString *a;
@end

@implementation Foo
@synthesize a = _a;
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        foo.a = @"hello";
        assert([foo.a isEqualToString:@"hello"]);
    }
}
