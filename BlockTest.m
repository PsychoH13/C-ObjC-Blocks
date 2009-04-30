#import <Foundation/Foundation.h>
#include "blocks_runtime.h"

typedef void (^BLK)(void);

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
- (BLK)selfBlock;
- (BLK)superBlock;
@end

@implementation Test

- (BLK)selfBlock
{
    return __Block_copy(^{ NSLog(@"%@", [self description]); });
}
- (BLK)superBlock
{
    return [(id)__Block_copy(^{ NSLog(@"%@", [super description]); }) autorelease];
}

@end

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    // Pure C compatible part
    BLK b1, b2;
    testBlock(&b1, &b2),
    
    tryBlock(b1, b2);
    
    __Block_release(b1);
    __Block_release(b2);
    
    // ObjC part
    Test *obj = [[Test new] autorelease];
    
    BLK blk = [obj selfBlock];
    blk();
    [blk release];
    [obj superBlock]();
        
    [pool drain];
    return 0;
}
