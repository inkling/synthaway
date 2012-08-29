//
// mixed.m: a mixed bag of tests
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

@interface Bar : NSObject
{
    NSUInteger i;
}
@property (assign) NSUInteger i;
@property (assign) NSUInteger j;
@property (assign) NSRange k;
@end

@implementation Bar
@synthesize i;
@synthesize j;
@synthesize k;
@end



@protocol Blah <NSObject>
@property (retain) NSString *p;
@end

@interface Parent : NSObject
{
  NSString *_style;
}
@end

@implementation Parent
@end

@interface Foo : Parent <Blah>
{
@public
    NSString *a;
}
@property (retain) NSString *a;
@property (retain) NSString *b;
@property (retain) NSString *c;
@property (retain, nonatomic) NSString *d;
@property (copy, nonatomic) NSString *e;
@property (retain) Bar *f;
@property (retain) NSString *oddlyNamed;
@property (retain) NSNumber *style;
@end

@interface Foo ()
{
    NSString *g;
}
@property (retain) NSString *g;
@property (retain) NSString *h;
@end


@implementation Foo
@synthesize a;
@synthesize b;
@synthesize c = _c;
@synthesize d;
@synthesize e = _e;
@synthesize f;
@synthesize p;
@synthesize g;
@synthesize h;
@synthesize oddlyNamed = _evenlyNamed;
@synthesize style;
- (void)dealloc
{
    [a release];
    [b release];
    [_c release];
    [d release];
    [_e release];
    [f release];
    [p release];
    [g release];
    [h release];
    [_evenlyNamed release];
    [style release];
    [super dealloc];
}

- (void)test:(NSString *)c
{
    self.a = c;
    if (![b isEqual:c]) {
        id tmp = b;
        b = [c retain];
        [tmp autorelease];
    }
    self.c = c;
    self.d = d;
    self.e = b;
    
    f.i = [c length];
    f.j = [c length];
    
    NSUInteger loc = f.k.location;
    NSUInteger len = f.k.length;
    if (loc == 0 && len > 0) {
        NSLog(@"f.k has a non-zero range");
    }
}

- (NSString *)d
{
    return [[d retain] autorelease];
}

- (void)setE:(NSString *)e
{
    id tmp = _e;
    _e = [e copy];
    [tmp autorelease];
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        foo.a = @"a";
        foo.b = @"a";
        assert([foo.a isEqual:foo.b]);   
    }
}

