//
// objcxx.mm: test Objective-C++ cases
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
#import <string>
#import <vector>
#import <map>

@interface Foo : NSObject
@property (assign) std::string *a;
@property (assign) std::string *b;
@property (assign) std::vector<std::string> *c;
@property (assign) std::map<Foo *, std::string> *d;
@property (retain) NSString *e;
@end

@implementation Foo
@synthesize a;
@synthesize b;
@synthesize c = _c;
@synthesize d = _d;
@synthesize e;

- (id)init
{
    self = [super init];
    if (self) {
        a = new std::string;
        b = new std::string;
        _c = new std::vector<std::string>;
        _d = new std::map<Foo *, std::string>;
    }
    return self;
}

- (void)dealloc
{
    if (a) {
        delete a;
    }

    if (b) {
        delete b;
    }

    if (_c) {
        delete _c;
    }

    if (_d) {
        delete _d;
    }

    [e release];
    [super dealloc];
}

- (void)test
{    
    *(self.a) = "hello";
    *(self->b) = "world";
    assert(*(self.a) != *(self.b));
    assert(*a != *b);
    assert(!(*self->b == *self->a));
    assert(*a < *b);
    assert(*b > *a);
    assert(!strcasecmp(self.b->c_str(), "world"));

    self.c->push_back(*(self.a));
    assert(*self->a == "hello");
    assert(self->_c->size() == 1);

    (*_d)[self] = "world";
    assert(self.d->size() == 1);
    assert((*self.d)[self] == "world");
    assert(self->_d->find(nil) == (*[self d]).end());

    self.e = [NSString stringWithUTF8String:[self a]->c_str()];
    assert(*self->a == [e UTF8String]);
}
@end

int main()
{
    @autoreleasepool {
        Foo *foo = [[[Foo alloc] init] autorelease];

        *(foo.a) = "foobar";
        foo.c->push_back(*foo.a);
        foo.c->push_back(*(foo.a));
        assert(*foo.a == "foobar");
        assert(foo.c->size() == 2);
        foo.c->clear();
        assert(foo.c->size() == 0);

        [foo test];
    }
}
