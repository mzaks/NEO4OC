
#import "NEODataAccessor.h"

@implementation NEODataAccessor {
    NSDictionary *data;
}

- (id)initWithData:(NSDictionary*)theData {
    self = [super init];
    if (self) {
        data = [theData copy];
    }
    return self;
}

- (NSString *)description {    
    return [NSString stringWithFormat:@"Data accessor for: %@", data];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector{
    id	stringSelector = NSStringFromSelector(aSelector);
    if([data valueForKey:stringSelector]){
        return [data methodSignatureForSelector:@selector(valueForKey:)];
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    id	stringSelector = NSStringFromSelector([anInvocation selector]); 
    id value = [data valueForKey:stringSelector]; 
    [anInvocation setReturnValue:&value];     
}


@end
