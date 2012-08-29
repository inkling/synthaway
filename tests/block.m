//
// block.m: test ivar usage inside blocks
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
@property (retain) NSString *b;
@property (retain) NSString *foobar;
@end

@implementation Foo
@synthesize a;
@synthesize b;
@synthesize foobar;
- (void)dealloc {
    [b release];
    [foobar release];
    [super dealloc];
}

- (void)run:(void (^)(void))t
{
    t();
}

- (void)test
{
    void (^t)(void) = ^{
        a = 10;
        [b release];
        b = [@"hello" copy];
        assert(self.a == 10);
        assert([self.b isEqual:@"hello"]);
    };

    [self run:t];

    [self run:^{
        a = 10;
        [b release];
        b = [@"hello" copy];
        assert(self.a == 10);
        assert([self.b isEqual:@"hello"]);

        [foobar release];
        foobar = [@"hello" copy];
        assert([self.foobar isEqual:@"hello"]);
    }];


    t();
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];
        [foo test];
    }
}
