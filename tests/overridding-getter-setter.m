//
// overridding-getter-setter.m: effect of manual getters and setters
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

@interface Foo : NSObject
@property (retain, nonatomic) NSString *a;
@property (retain, nonatomic) NSString *b;
@property (readonly, nonatomic) NSString *d;
@end

@interface Foo ()
@property (copy, nonatomic) NSString *c;
@end

@implementation Foo
// a, b, and c can be removed: b only has getter and c setter
// but d cannot be removed because it has both getter and setter
@synthesize a = _a;
@synthesize b;
@synthesize c = _c;
@synthesize d ;

- (void)dealloc
{
	[_a release], _a = nil;
	[b release], b = nil;
	[_c release], _c = nil;
	[d release], d = nil;
	[super dealloc];	
}

- (id)init
{
	self = [super init];
	if (self) {
		d = [@"world" copy];
	}
	return self;
}

- (void)test
{
	self.a = b;
	self.c = @"world";
	assert([self.a isEqual:self.b]);
	assert([self.d isEqual:self.c]);
}

- (NSString *)b
{
	return b;
}

- (void)setC:(NSString *)c
{
	id tmp = _c;
	_c = [c copy];
	[tmp release];
}

- (NSString *)d
{
	return [[d copy] autorelease];
}

@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
    }
}
