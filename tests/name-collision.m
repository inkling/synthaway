//
// name-collision.m: test name collision with superclass' ivar
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
{
	NSString *_style;
}
@end

@implementation Parent
- (void)dealloc
{
	[_style release];
	[super dealloc];
}
@end

@interface Foo : Parent
@property (retain) NSString *a;
@property (retain) NSString *style;
@end

@implementation Foo
@synthesize a;
@synthesize style;
- (void)dealloc
{
	[a release];
	[style release];
	[super dealloc];
}

- (void)test
{
	id tmp = _style;
	_style = [@"a" retain];
	[tmp release];
	self.style = @"b";
	self.a = @"a";
	assert([_style isEqual:a]);
	assert([_style isEqual:self->a]);
	assert([_style isEqual:self.a]);
	assert([_style isEqual:[self a]]);
	assert(![_style isEqual:style]);
	assert(![_style isEqual:self.style]);
	assert(![self->_style isEqual:self->style]);
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        [foo test];
    }
}

