#import <Foundation/Foundation.h>
#include "blocks_runtime.h"

//#import <Cocoa/Cocoa.h>
#if 1
typedef int (^intblock)(int);

@interface PBTest : NSObject
{
    intblock onRelease;
    int num;
}
@property (copy) intblock onRelease;
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
    onRelease(num);
    [super release];
}

- (void)dealloc
{
    [onRelease release];
    [super dealloc];
}
@end

int main (int argc, char const *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    PBTest *a = [[PBTest alloc] init];
    a.num = 3;
    a.onRelease = ^(int i){ printf("Returning 2 * %i", i); return 2*i; };
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

BLKI b = ^(int i){ NSLog(@"%d", i); };

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
    
    BLKI b3 = ^(int i){ NSLog(@"%d", i); };
    BLKI b4 = ^(int i){ NSLog(@"%d", i); };
    
    NSLog(@"%p, %p, %p, %p", (void *)b, b3, b4, main);
    
    NSLog(@"%@", ((id) ^(int i){ NSLog(@"%d", i); })->isa);
    obj.onRelease = ^(int i){ NSLog(@"test %d", i); };
    
    //[blk release];
    //
        
    [pool drain];
    return 0;
}
#endif