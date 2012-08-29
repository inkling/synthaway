//
// linkedlist.m: test use of direct ivar access
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

@interface Node : NSObject
- (void)hairy;
@property (assign, nonatomic) Node *prev;
@property (assign, nonatomic) Node *next;
@end

@implementation Node
@synthesize next;
@synthesize prev = _prev;
- (void)hairy
{
    Node *n = nil;

    n = [[Node alloc] init];
    next = n;
    self.next.prev = self;

    n = [[Node alloc] init];
    next.next = n;
    n->_prev = next;

    n = [[Node alloc] init];
    next->next.next = n;
    n.prev = self.next.next;

    n = [[Node alloc] init];
    self.next->next->next.next = n;
    n.prev = next->next.next;

    assert(self != next);
    assert(next != next.next);
    assert(next.next != next.next.next);
    assert(next.next.next != next.next.next.next);
    assert(next.next.next.next.next == nil);

    assert(self != self->next);
    assert(next != next->next);
    assert(next.next != next->next.next);
    assert(next.next.next != next.next->next.next);
    assert(next->next.next->next.next == nil);

    assert(self == next.prev);
    assert(next == next.next->_prev);
    assert(next.next == next.next.next->_prev);
    assert(next.next.next == next.next.next.next.prev);
    assert(next.next.next.prev.next == next.next.next);

    assert(self == next.prev);
    assert(next == next.next.prev);
    assert(next.next == next.next.next.prev);
    assert(next.next.next == next.next.next.next.prev);    

    n = next;
    while (n) {
        id tmp = n;
        n = n.next;
        [tmp release];
    }
}
@end

int main()
{
    @autoreleasepool {
        Node *node = [[[Node alloc] init] autorelease];
        [node hairy];
    }
}
