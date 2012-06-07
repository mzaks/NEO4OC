
#import "NEODataAccessorTests.h"

@implementation FooAccessor

@dynamic foo, number;

@end

@implementation NEODataAccessorTests

-(void)testDataAccessor{
    NSMutableDictionary * data = [NSMutableDictionary dictionaryWithObject:@"My Name is" forKey:@"foo"];
    [data setValue:[NSNumber numberWithInt:13] forKey:@"number"];
    FooAccessor *ac = [[FooAccessor alloc]initWithData:data];
    NSLog(@"%@", ac);
    NSString *value = ac.foo;
    STAssertEqualObjects(value, @"My Name is", @"should be accessable");
    NSNumber *value2 = ac.number;
    STAssertEqualObjects(value2, [NSNumber numberWithInt:13], @"should be accessabel");
}

@end
