#import "NEOBatchOperationBuilder.h"
#import "NEOGraphDatabase_Internal.h"

@implementation NEOBatchOperationBuilder{
    __weak NEOGraphDatabase *graph;
    NSUInteger operationId;
    NSMutableArray *operations;
}

- (id)initWithGraph:(__weak NEOGraphDatabase *)database
{
    self = [super init];
    if (self) {
        operationId = 0;
        operations = [NSMutableArray array];
        graph = database;
    }
    return self;
}

-(NSString *)addOperationAndReturnIdForMethod:(NSString*)method to:(NSString*)to andBody:(NSDictionary*)body{
    NSMutableDictionary *operation = [NSMutableDictionary dictionary];
    [operation setObject:method forKey:@"method"];
    [operation setObject:to forKey:@"to"];
    [operation setObject:[NSNumber numberWithInt:operationId] forKey:@"id"];
    if (body) {
        [operation setObject:body forKey:@"body"];
    }
    [operations addObject:operation];
    NSString *operationIdString = [NSString stringWithFormat:@"{%i}", operationId];
    operationId ++;
    return operationIdString;
}

-(NSString *)createNodeWithData:(NSDictionary *)dataOrNil{    
    return [self addOperationAndReturnIdForMethod:@"POST" to:@"/node" andBody:dataOrNil];
}

-(NSString *)createRelationshipOfType:(NSString*)type fromNodeId:(NSString *)nodeId toNode:(NSString*)targetNodeId withData:(NSDictionary *)dataOrNil{
    
    NSString * toString = [NSString stringWithFormat:@"%@/relationships", nodeId];
    
    NSMutableDictionary *body = [NSMutableDictionary dictionary];
    [body setObject:targetNodeId forKey:@"to"];
    [body setObject:type forKey:@"type"];
    if(dataOrNil){
        [body setObject:dataOrNil forKey:@"data"];
    }
    
    return [self addOperationAndReturnIdForMethod:@"POST" to:toString andBody:body];
}

-(void)executeWithResultHandler:(void (^)(NEOError *error))callback{
    [graph executeBatchOperations:operations withResultHandler:callback];
}

@end
