
#import "NEOPromise.h"
#import "NEOError.h"

static NSOperationQueue * queue;

@implementation NEOPromise {
    id value;
    NEOError *error;
}

- (PROMISE_STATUS)status {
    if (error != nil) {
        return ERROR;
    }
    if (value == nil) {
        return WAITING;
    }

    return DONE;
}

- (void)setValue:(id)aValue {
    if (value != nil) {
        [NSException raise:@"Node is already set" format:nil];
    }
    value = aValue;
}

- (void)setError:(NEOError *)anError {
    error = anError;
}

-(NEOError*)error{
    return error;
}

-(BOOL)hasError{
    return error != nil;
}

- (NSString *)description {
    if ([self status] == WAITING) {
        return @"Waiting";
    }
    if ([self status] == ERROR) {
        return @"There was an error";
    }

    return [value description];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    while ([self status] == WAITING) {}
    [anInvocation invokeWithTarget:value];
}

-(id)wait{
    while ([self status] == WAITING) {}
    return self;
}

- (void)waitWithHandler:(void (^)(id value, NEOError *error))callback {
    __weak NEOPromise * promise = self;
    if (!queue){
        queue = [[NSOperationQueue alloc] init];
    }
    [queue addOperationWithBlock:^(){
        [promise wait];
        callback(promise->value, promise->error);
    }];
}


+ (void)waitForPromises:(NEOPromise*)promise, ...{
    NEOPromise *eachPromise;
    va_list argumentList;
    if (promise) 
    {                                   
        [promise wait];
        va_start(argumentList, promise); 
        while ((eachPromise = va_arg(argumentList, NEOPromise*))){ 
            [eachPromise wait];
        }
        va_end(argumentList);
    }
    
}

@end