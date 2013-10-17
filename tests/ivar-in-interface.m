#import <Foundation/Foundation.h>

@interface Foo : NSObject {
@public
	NSString * a;
}
@property (retain) NSString *a;
@property (retain) NSString *b;
@end

@implementation Foo
@synthesize a;
@synthesize b;
- (id)test {
	if (a == b) {
		return b;
	}

	return a;
}
@end

int main() {

	// This explains why ivar-in-interface cannot be easily removed, as
	// this idiom assumes f->a is @public (which is so by default), but
	// once property a is backed by the synthesized _a, _a is no longer
	// public.
	/*
	Foo *f = [Foo new];
	f->a = @"hello";
	*/
	return 0;
}
