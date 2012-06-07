
#import "NEOError.h"


@implementation NEOError {
    NSMutableArray *messages;
}

- (id)init {
    self = [super init];
    if (self) {
        messages = [NSMutableArray array];
    }

    return self;
}

- (void)addMessage:(NSString *)message {
    [messages addObject:message];
}

- (NSArray *)messages {
    return [NSArray arrayWithArray:messages];
}

-(NSString *)description{
    return [messages description];
}

@end