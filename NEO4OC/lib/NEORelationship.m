
#import "NEORelationship.h"
#import "NEOGraphDatabase_Internal.h"
#import "NEOError.h"

@implementation NEORelationship {
    NSString *relationshipURI;
    NEOGraphDatabase *graph;
    NSDictionary *data;
    NSString *startNodeId;
    NSString *endNodeId;
    NSString *type;
}

- (NEORelationship *)initWithGraph:(__weak NEOGraphDatabase *)database data:(NSDictionary *)theData type:(NSString*)theType start:(NSString*)startId end:(NSString*)endId andURI:(NSString *)theRelationshipURI{
    self = [super init];
    if (self) {
        graph = database;
        data = theData;
        relationshipURI = theRelationshipURI;
        startNodeId = startId;
        endNodeId = endId;
        type = theType;
    }
    return self;
}

- (NSString *)relationshipURI {
    return [relationshipURI copy];
}

- (NSString *)relationshipId {
    return [[NSURL URLWithString:relationshipURI] lastPathComponent];
}

- (NSDictionary *)data {
    return [data copy];
}

- (void)fetchData:(void(^)(NSDictionary* data, NEOError* error))callback{
    __weak NEORelationship * this = self;
    [graph fetchDataForRelationshipId:self.relationshipId withResultHandler:^(NSDictionary *fetchedData, NEOError *error) {
        if(data){
            this->data = [fetchedData copy];
        }
        callback(fetchedData, error);
    }];
}

- (void)setData:(NSDictionary*)newData withResultHandler:(void (^)(NEOError *))callback{
    __weak NEORelationship * this = self;
    [graph setData:newData forRelationshipId:self.relationshipId withResultHandler:^(NEOError *error) {
        if(!error){
            this->data = newData;
        }
        callback(error);
    }];
}


- (NSString *) type{
    return [type copy];
}
- (NSString *) startNodeId{
    return [startNodeId copy];
}

- (NEONodePromise *) startNode{
    return [graph getNodeById:startNodeId];
}

- (NSString *) endNodeId{
    return [endNodeId copy];
}

- (NEONodePromise *) endNode{
    return [graph getNodeById:endNodeId];
}

- (NSString *)description{
    return [NSString stringWithFormat:@"Realtionship %@: (%@)-[%@]->(%@) with data %@", [self relationshipId], startNodeId, type, endNodeId, data];
}

- (void)deleteWithResultHandler:(void (^)(NEOError *))callback {
    
    [graph deleteRelationshipById:[self relationshipId] withResultHandler:^(NEOError *error) {
        if (error == nil) {
            data = nil;
            relationshipURI = nil;
            startNodeId = nil;
            endNodeId = nil;
            type = nil;
        }
        callback(error);
    }];
}

@end

@implementation NEORelationshipPromise

-(void)waitForRelationshipWithHandler:(void (^)(id<NEORelationship> value, NEOError *error))callback{
    [self waitWithHandler:^(id value, NEOError *error) {
        callback(value, error); 
    }];
}

@end