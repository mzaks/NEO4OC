
#import "NEORequestBuilder.h"


@implementation NEORequestBuilder {
    NSURL *url;
    NSTimeInterval timeout;
}

- (NSURL *)computeURLByAppendingParts:(NSArray *)parts {
    NSURL *result = [url copy];
    for (NSString *part in parts) {
        result = [result URLByAppendingPathComponent:part];
    }
    return result;
}

- (NSMutableURLRequest *)createRequestWithURLParts:(NSArray *)parts {
    NSURL *requestURL = [self computeURLByAppendingParts:parts];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    if (timeout) {
        [request setTimeoutInterval:timeout];
    }
    return request;
}

- (void)addGETParameters:(NSMutableURLRequest *)request {
    [request setHTTPMethod:@"GET"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}


- (void)addPOSTParameters:(NSMutableURLRequest *)request {
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)addPUTParameters:(NSMutableURLRequest *)request {
    [request setHTTPMethod:@"PUT"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)addDELETEParameters:(NSMutableURLRequest *)request {
    [request setHTTPMethod:@"DELETE"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
}

- (void)putData:(id)theData intoRequest:(NSMutableURLRequest *)request {
    if (theData) {
        NSError *jsonSerializeError;
        NSData *data = [NSJSONSerialization dataWithJSONObject:theData options:NSJSONWritingPrettyPrinted error:&jsonSerializeError];
        if (!jsonSerializeError) {
            [request setHTTPBody:data];
        } else {
            // TODO push error
        }
    }
}

NSString *getDirectionString(RELATIONSHIP_DIRECTION direction) {
    switch (direction) {
        case ALL:
            return @"all";
        case IN:
            return @"in";
        case OUT:
            return @"out";
    }
    return nil;
}

- (id)initWithBaseURL:(NSURL *)aUrl {
    self = [self init];
    if (self) {
        url = aUrl;
    }
    return self;

}

- (void)setTimeoutInSeconds:(NSTimeInterval)interval {
    timeout = interval;
}


- (NSURLRequest *)requestForGetInfo {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data", nil]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    return [request copy];
}

- (NSURLRequest *)requestForGetNodeById:(NSString *)nodeId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node", nodeId, nil]];
    [self addGETParameters:request];
    return [request copy];

}

- (NSURLRequest *)requestForGetDataForNodeById:(NSString *)nodeId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node", nodeId, @"properties", nil]];
    [self addGETParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForGetRelationshipById:(NSString *)relationshipId {

    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/relationship/", relationshipId, nil]];
    [self addGETParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForGetDataForRelationshipById:(NSString *)relId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/relationship", relId, @"properties", nil]];
    [self addGETParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForGetRelationships:(RELATIONSHIP_DIRECTION)direction forNodeId:(NSString *)nodeId andTypes:(NSArray *)types {
    NSString *directionString = getDirectionString(direction);
    NSMutableArray *parts = [NSMutableArray arrayWithObjects:@"db/data/node/", nodeId, @"relationships", directionString, nil];
    if (types && [types count] > 0) {
        [parts addObject:[types componentsJoinedByString:@"&"]];
    }

    NSMutableURLRequest *request = [self createRequestWithURLParts:parts];
    [self addGETParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForCreateNodeWithData:(NSDictionary *)data {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node", nil]];
    [self addPOSTParameters:request];
    [self putData:data intoRequest:request];
    return [request copy];
}

- (NSURLRequest *)requestForCreateRelationshipFromNodeId:(NSString *)nodeId withData:(NSDictionary *)data {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node/", nodeId, @"relationships", nil]];

    [self addPOSTParameters:request];
    [self putData:data intoRequest:request];
    return [request copy];
}

- (NSURLRequest *)requestForDeleteNodeById:(NSString *)nodeId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node/", nodeId, nil]];
    [self addDELETEParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForDeleteRelationshipById:(NSString *)relationshipId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/relationship/", relationshipId, nil]];
    [self addDELETEParameters:request];
    return [request copy];
}


- (NSURLRequest *)requestForQueryWithCypher:(NSString *)cypher andParameters:(NSDictionary *)params {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/cypher/", nil]];
    [self addPOSTParameters:request];

    NSMutableDictionary *theData = [[NSMutableDictionary alloc] init];
    [theData setObject:cypher forKey:@"query"];
    if (!params) {
        params = [[NSDictionary alloc] init];
    }
    [theData setObject:params forKey:@"params"];
    [self putData:theData intoRequest:request];
    return request;
}

- (NSURLRequest *)requestForSetData:(NSDictionary *)newData forNodeById:(NSString *)nodeId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/node", nodeId, @"properties", nil]];
    [self putData:newData intoRequest:request];
    [self addPUTParameters:request];
    return [request copy];
}

- (NSURLRequest *)requestForSetData:(NSDictionary *)newData forRelationshipById:(NSString *)nodeId {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/relationship", nodeId, @"properties", nil]];
    [self putData:newData intoRequest:request];
    [self addPUTParameters:request];
    return [request copy];
}

NSString* typeString(IndexType type){
    if (type == nodeIndex) {
        return @"node";
    }
    return @"relationship";
}

-(NSURLRequest *)requestForCreateIndexWithType:(IndexType)type name:(NSString*)name andConfig:(NSDictionary*)configOrNil {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), nil]];
    [self addPOSTParameters:request];
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObject:name forKey:@"name"];
    if (configOrNil) {
        [data setValue:configOrNil forKey:@"config"];
    }
    [self putData:data intoRequest:request];
    return [request copy];
}

-(NSURLRequest *)requestForDeleteIndexWithType:(IndexType)type name:(NSString*)name {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), name, nil]];
    [self addDELETEParameters:request];
    return [request copy];
}

-(NSURLRequest *)requestForGetIndexWithType:(IndexType)type name:(NSString*)name{
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), name, nil]];
    [self addGETParameters:request];
    return [request copy];
}

-(NSURLRequest *)requestForAddByURI:(NSString *)nodeURI indexType:(IndexType)type name:(NSString *)indexName key:(NSString *)key andValue:(NSString *)value {
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), indexName, nil]];
    [self addPOSTParameters:request];
    NSDictionary *data = [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:nodeURI, key, value, nil]
            forKeys:[NSArray arrayWithObjects:@"uri", @"key", @"value", nil] ];
    [self putData:data intoRequest:request];
    return [request copy];
}

-(NSURLRequest *)requestForRemoveById:(NSString *)nodeId indexType:(IndexType)type name:(NSString *)indexName key:(NSString *)keyOrNil andValue:(NSString *)valueOrNil {
    NSMutableArray *path = [NSMutableArray arrayWithObjects:@"db/data/index", typeString(type), indexName, nil];
    if (keyOrNil) {
        [path addObject:keyOrNil];
    }
    if (valueOrNil) {
        [path addObject:valueOrNil];
    }
    [path addObject:nodeId];
    
    NSMutableURLRequest *request = [self createRequestWithURLParts:path];
    [self addDELETEParameters:request];
    return [request copy];
}

-(NSURLRequest *)requestForFindByExactMatchForIndexType:(IndexType)type name:(NSString *)indexName key:(NSString *)key andValue:(NSString *)value{
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), indexName, key, value, nil]];
    [self addGETParameters:request];
    return [request copy];
}

-(NSURLRequest *)requestForGetAllIndexesOfType:(IndexType)type{
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/index", typeString(type), nil]];
    [self addGETParameters:request];
    return [request copy];
}

-(NSURLRequest *)requestForExecuteBatchOperations:(NSArray*)operations{
    NSMutableURLRequest *request = [self createRequestWithURLParts:[NSArray arrayWithObjects:@"db/data/batch", nil]];
    [self addPOSTParameters:request];
    [self putData:operations intoRequest:request];
    return [request copy];
}

@end