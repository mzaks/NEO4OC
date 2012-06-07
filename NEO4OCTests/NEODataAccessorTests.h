
#import <SenTestingKit/SenTestingKit.h>
#import "NEODataAccessor.h"

@interface FooAccessor : NEODataAccessor

@property (copy, readonly)NSString *foo;
@property (readonly)NSNumber *number;

@end

@interface NEODataAccessorTests : SenTestCase

@end
