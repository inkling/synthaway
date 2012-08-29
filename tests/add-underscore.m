//
// add-underscore.m: simple test cases expecting renames
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
@property (assign) int a;
@property (assign, nonatomic) int b;
@property (retain) NSString *c;
@property (retain, nonatomic) NSString *d;
@property (copy) NSString *e;
@property (copy, nonatomic) NSString *f;
@property (assign) NSString *g;
@property (assign, nonatomic) NSString *h;
- (int)sameA;
- (NSString *)sameC;
@end

@implementation Foo
@synthesize a;
@synthesize b;
@synthesize c;
@synthesize d;
@synthesize e;
@synthesize f;
@synthesize g;
@synthesize h;
- (void)dealloc {
    [c release];
    [d release];
    [e release];
    [f release];
    [g release];
    [h release];
    [super dealloc];
}

- (int)sameA
{
    return a;
}

- (NSString *)sameC
{
    return c;
}

- (BOOL)meaningless
{
    id tmp = self->g;
    g = [self->h retain];
    [h release];
    h = nil;
    [tmp release];

    return self->a == self->b || [self->c length] == [self.d length] || [self->e length] == [f length] || g == self->h;
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        foo.a = 1;
        foo.b = 2;
        foo.c = @"c";
        foo.d = @"d";
        foo.e = @"e";
        foo.f = @"f";
        foo.g = @"g";
        foo.h = @"h";
        assert([foo sameA]);
        assert(foo.b == 2);
        assert([[foo sameC] isEqual:foo.c]);
        assert([foo.d isEqual:@"d"]);   
        assert([foo.e isEqual:@"e"]);
        assert([foo.f isEqual:@"f"]);
        assert([foo.g isEqual:@"g"]);
        assert([foo.h isEqual:@"h"]);
    }
}
