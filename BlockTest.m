#import <Foundation/Foundation.h>
#include "blocks_runtime.h"

//#import <Cocoa/Cocoa.h>
#if 0
typedef int (^intblock)(int in);

@interface PBTest : NSObject
{
    intblock onRelease;
    int num;
}
@property (retain) intblock onRelease;
@property (assign) int num;
@end

@implementation PBTest
@synthesize onRelease, num;
- (id)init
{
    if((self = [super init]))
    {
    }
    return self;
}

- (void)release
{
    intblock(num);
    [super release];
}
@end

void func(void)
{
    int (^blk)(int i) = ^(int i){ printf("Returning 2 * %i", i); return 2*i; };
    NSLog(@"%@", ((id)blk)->isa);
}

int main (int argc, char const *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PBTest *a = [[PBTest alloc] init];
    a.num = 3;
    int (^blk)(int i) = ^(int i){ printf("Returning 2 * %i", i); return 2*i; };
    int (^blk2)(int i);
    NSLog(@"%@", ((id)blk)->isa);
    func();
    
    [a release];
    [pool drain];
    return 0;
}

#else

typedef void (^BLK)(void);
typedef void (^BLKI)(int);

void testBlock(BLK *ret1, BLK *ret2)
{
    __block int i = 0;
    BLK b1 = ^{ i++; };
    BLK b2 = ^{ printf("print: %d\n", i); };
    
    *ret1 = (BLK)__Block_copy(b1);
    *ret2 = (BLK)__Block_copy(b2);
}

void tryBlock(BLK b1, BLK b2)
{
    b1();
    b2();
    b1();
    b2();
}

@interface Test : NSObject
{
    BLKI onRelease;
}
@property(copy, nonatomic) BLKI onRelease;
- (BLKI)selfBlock;
- (BLKI)superBlock;
@end

@implementation Test
@synthesize onRelease;
- (BLKI)selfBlock
{
    return [[^(int i){ NSLog(@"%@ %d", [self description], i); } copy] autorelease];
}
- (BLKI)superBlock
{
    return [[^(int i){ NSLog(@"%@ %d", [super description], i); } copy] autorelease];
}
- (void) dealloc
{
    onRelease(42);
    [onRelease release];
    [super dealloc];
}

@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    // Pure C compatible part
    BLK b1, b2;
    testBlock(&b1, &b2);
    
    tryBlock(b1, b2);
    
    __Block_release(b1);
    __Block_release(b2);
    
    // ObjC part
    Test *obj = [[Test new] autorelease];
    
    BLKI blk = [obj selfBlock];
    blk(10);
    [obj superBlock](42);
    NSLog(@"%@", ((id)blk)->isa);
    [obj setOnRelease:^(int i){ NSLog(@"%d", i); }];
    
    //[blk release];
    //
        
    [pool drain];
    return 0;
}
#endif