//
// type-divergence: test inherited properties of different types
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

@interface Parent : NSObject
@property (readonly, nonatomic) id name;
@end

@implementation Parent
- (id)name
{
	return @"a";
}
@end

@interface Foo : Parent
@property (retain, nonatomic) NSString *a;
@property (retain, nonatomic) NSString *name;
@end

@implementation Foo
@synthesize a;
@synthesize name;
- (void)dealloc
{
	[a release];
	[name release];
	[super dealloc];
}

- (void)test
{
	self.a = @"b";
	self.name = @"b";	
	assert(![self.name isEqual:@"a"]);
	assert([name isEqual:a]);
	assert([self.name isEqual:self.a]);
	assert([self->name isEqual:self->a]);
	assert([[self name] isEqual:[self a]]);
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        [foo test];
    }
}
