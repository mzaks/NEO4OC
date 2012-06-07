
#import "NEONode.h"
#import "NEOGraphDatabase.h"
#import "NEOError.h"


@implementation NEONode {
    NSString *nodeURI;
    NEOGraphDatabase *graph;
    NSDictionary *data;
}

- (NEONode *)initWithGraph:(__weak NEOGraphDatabase *)database data:(NSDictionary *)theData andURI:(NSString *)theNodeURI {
    self = [super init];
    if (self) {
        graph = database;
        data = theData;
        nodeURI = theNodeURI;
    }
    return self;
}

- (NSString *)nodeURI {
    return [nodeURI copy];
}

- (NSString *)nodeId {
    return [[NSURL URLWithString:nodeURI] lastPathComponent];
}

- (NSDictionary *)data {
    return [data copy];
}

- (void)fetchData:(void(^)(NSDictionary* data, NEOError* error))callback{
    __weak NEONode * this = self;
    [graph fetchDataForNodeId:self.nodeId withResultHandler:^(NSDictionary *fetchedData, NEOError *error) {
        if(data){
            this->data = [fetchedData copy];
        }
        callback(fetchedData, error);
    }];
}

- (void)setData:(NSDictionary*)newData withResultHandler:(void (^)(NEOError *))callback{
    __weak NEONode * this = self;
    [graph setData:newData forNodeId:self.nodeId withResultHandler:^(NEOError *error) {
        if(!error){
            this->data = newData;
        }
        callback(error);
    }];
}

- (void)deleteWithResultHandler:(void (^)(NEOError *))callback {

    [graph deleteNodeById:[self nodeId] withResultHandler:^(NEOError *error) {
        if (error == nil) {
            data = nil;
            nodeURI = nil;
        }
        callback(error);
    }];
}

- (NEORelationshipPromise*)createRelationshipToNode:(id<NEONode>)endNode ofType:(NSString*)theType andData:(NSDictionary*)theData{
    return [graph createRelationshipOfType:theType fromNode:self toNode:endNode withData:theData];
}

- (void)getAllRelationshipsOfTypes:(NSArray*)types withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback{
    [graph getRelationships:ALL forNodeId:[self nodeId] andTypes:types withResultHandler:callback];
}

- (void)getOutgoingRelationshipsOfTypes:(NSArray*)types withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback{
    [graph getRelationships:OUT forNodeId:[self nodeId] andTypes:types withResultHandler:callback];
}

- (void)getIncomingRelationshipsOfTypes:(NSArray*)types withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback{
    [graph getRelationships:IN forNodeId:[self nodeId] andTypes:types withResultHandler:callback];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Node with id: %@ and data: %@", self.nodeId, data];
}

@end

#pragma mark - Promise

@implementation NEONodePromise

-(void)waitForNodeWithHandler:(void (^)(id<NEONode> value, NEOError *error))callback{
    [self waitWithHandler:^(id value, NEOError *error) {
        callback(value, error); 
    }];
}

@end