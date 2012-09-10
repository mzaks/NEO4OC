
#import "NEOGraphDatabase.h"
#import "NEOError.h"
#import "NEORequestBuilder.h"
#import "NEOPath.h"

NSString *idOfURI(NSString *uri) {
    NSURL *url = [NSURL URLWithString:uri];
    return [url lastPathComponent];
}

@implementation NEOGraphDatabase {
    NSURL *url;
    NSOperationQueue *queue;
}
@synthesize requestBuilder = _requestBuilder;


#pragma mark - private methods and functions


- (NEORelationship *)createRelationshipFromResult:(NSDictionary *)dict {
    NSString *uri = [dict objectForKey:@"self"];
    NSDictionary *relData = [dict objectForKey:@"data"];
    NSString *relType = [dict objectForKey:@"type"];
    NSString *startId = idOfURI([dict objectForKey:@"start"]);
    NSString *endId = idOfURI([dict objectForKey:@"end"]);
    if (!relType || !startId || !endId) {
        return nil;
    }
    return [[NEORelationship alloc] initWithGraph:self data:relData type:relType start:startId end:endId andURI:uri];
}

- (NEONode *)createNodeFromResult:(NSDictionary *)dict {
    if (![dict objectForKey:@"all_relationships"]) {
        return nil;
    }
    NSString *nodeURI = [dict valueForKey:@"self"];

    return [[NEONode alloc] initWithGraph:self data:[dict valueForKey:@"data"] andURI:nodeURI];
}

NSArray *convertArrayOfURIsToArrayOfIds(NSArray *uris) {
    if (!uris) {
        return nil;
    }
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[uris count]];
    for (NSString *uri in uris) {
        [result addObject:idOfURI(uri)];
    }
    return result;
}

- (NEOPath *)createPathFromResult:(NSDictionary *)dict {
    NSString *startId = idOfURI([dict objectForKey:@"start"]);
    NSString *endId = idOfURI([dict objectForKey:@"end"]);
    NSUInteger length = (NSUInteger) [[dict objectForKey:@"length"] integerValue];
    NSArray *nodes = convertArrayOfURIsToArrayOfIds([dict objectForKey:@"nodes"]);
    NSArray *relationships = convertArrayOfURIsToArrayOfIds([dict objectForKey:@"relationships"]);
    if (startId && endId && length && nodes && relationships) {
        return [[NEOPath alloc] initWithGraph:self startId:startId endId:endId length:length nodes:nodes relationships:relationships];
    }
    return nil;
}

BOOL foundUnexpectedHTTPError(NSURLResponse *httpResponse, NSError *httpError, int positiveCode, NSData *data, NEOError *dbError) {
    if (httpError) {
        [dbError addMessage:[NSString stringWithFormat:@"Technical Error on URL Connection. %@", httpError.userInfo]];
        return YES;
    }
    const NSInteger statusCode = ((NSHTTPURLResponse *) httpResponse).statusCode;
    if (statusCode != positiveCode) {
        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&jsonParseError];
        if (jsonParseError) {
            NSString *dataAsText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@ \n\rRaw data is: %@", jsonParseError.userInfo, dataAsText]];
        }

        NSString *message = [dict valueForKey:@"message"];
        if (message) {
            [dbError addMessage:message];
        } else {
            [dbError addMessage:[NSString stringWithFormat:@"Unexpected HTTP status code: %i for URL: %@", statusCode, httpResponse.URL]];
        }


        return YES;

    }
    return NO;
}

- (void)performDeleteWithRequest:(NSURLRequest *)request andHandler:(void (^)(NEOError *error))callback {
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 204, data, dbError)) {
            callback(dbError);
            return;
        }
        callback(nil);

    }];
}

#pragma mark - public methods

- (id)initWithURL:(NSURL *)aURL {
    self = [self init];
    if (self) {
        url = aURL;
        queue = [[NSOperationQueue alloc] init];
        self.requestBuilder = [[NEORequestBuilder alloc] initWithBaseURL:aURL];
    }
    return self;
}

- (void)getInfo:(void (^)(NSDictionary *info, NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForGetInfo];

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];
        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(nil, dbError);
            return;
        }
        NSError *error1;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&error1];
        callback(dict, nil);
    }];
}

- (NEONodePromise *)createNodeWithData:(NSDictionary *)theData {
    NEONodePromise *promise = [[NEONodePromise alloc] init];

    NSURLRequest *request = [self.requestBuilder requestForCreateNodeWithData:theData];

    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 201, data, dbError)) {
            [promise setError:dbError];
            return;
        }

        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            [promise setError:dbError];
            return;
        }
        NSString *nodeURI = [dict valueForKey:@"self"];

        NEONode *node = [[NEONode alloc] initWithGraph:graph data:[dict valueForKey:@"data"] andURI:nodeURI];
        [promise setValue:node];
    }];

    return promise;
}

- (void)deleteNodeById:(NSString *)nodeId withResultHandler:(void (^)(NEOError *))callback {
    NSURLRequest *request = [self.requestBuilder requestForDeleteNodeById:nodeId];

    [self performDeleteWithRequest:request andHandler:callback];

}

- (NEONodePromise *)getNodeById:(NSString *)nodeId {
    NEONodePromise *promise = [[NEONodePromise alloc] init];

    NSURLRequest *request = [self.requestBuilder requestForGetNodeById:nodeId];

    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            [promise setError:dbError];
            return;
        }

        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            [promise setError:dbError];
            return;
        }
        NEONode *node = [graph createNodeFromResult:dict];
        [promise setValue:node];
    }];

    return promise;
}

- (void)fetchDataForNodeId:(NSString *)nodeId withResultHandler:(void (^)(NSDictionary *data, NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForGetDataForNodeById:nodeId];

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            if (foundUnexpectedHTTPError(res, error, 204, data, dbError)) {
                callback(nil, dbError);
                return;
            }else{
                callback(nil, nil);
                return;
            }
        }
        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }
        callback(dict, nil);
    }];
}

- (void)fetchDataForRelationshipId:(NSString *)relId withResultHandler:(void (^)(NSDictionary *data, NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForGetDataForRelationshipById:relId];

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            if (foundUnexpectedHTTPError(res, error, 204, data, dbError)) {
                callback(nil, dbError);
                return;
            }else{
                callback(nil, nil);
                return;
            }
        }
        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }
        callback(dict, nil);
    }];
}

- (void)setData:(NSDictionary *)newData forNodeId:(NSString *)nodeId withResultHandler:(void (^)(NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForSetData:newData forNodeById:nodeId];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (void)setData:(NSDictionary *)newData forRelationshipId:(NSString *)relId withResultHandler:(void (^)(NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForSetData:newData forRelationshipById:relId];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (NEORelationshipPromise *)createRelationshipOfType:(NSString *)type fromNode:(id <NEONode>)node1 toNode:(id <NEONode>)node2 withData:(NSDictionary *)theData {
    NSParameterAssert(type);
    NSParameterAssert(node1);
    NSParameterAssert(node2);
    NEORelationshipPromise *promise = [[NEORelationshipPromise alloc] init];
    __weak NEOGraphDatabase *graph = self;
    [queue addOperationWithBlock:^{
        NEOGraphDatabase *_graph = graph;
        NSString *fromId = node1.nodeId;
        NSString *toURI = node2.nodeURI;
        NEOError *dbError = [[NEOError alloc] init];

        if (!fromId) {
            [dbError addMessage:@"The ID of from node could not be determined"];
            [promise setError:dbError];
            return;
        }

        if (!toURI) {
            [dbError addMessage:@"The URI of to node could not be determined"];
            [promise setError:dbError];
            return;
        }

        NSMutableDictionary *requestParameter = [NSMutableDictionary dictionary];
        [requestParameter setObject:toURI forKey:@"to"];
        [requestParameter setObject:type forKey:@"type"];
        if (theData) {
            [requestParameter setObject:theData forKey:@"data"];
        }

        NSURLRequest *request = [self.requestBuilder requestForCreateRelationshipFromNodeId:fromId withData:requestParameter];

        [NSURLConnection sendAsynchronousRequest:request queue:_graph->queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {

            if (foundUnexpectedHTTPError(res, error, 201, data, dbError)) {
                [promise setError:dbError];
                return;
            }

            NSError *jsonParseError;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
            if (jsonParseError) {
                [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
                [promise setError:dbError];
                return;
            }
            NEORelationship *relationship = [graph createRelationshipFromResult:dict];
            [promise setValue:relationship];
        }];

    }];

    return promise;
}

- (NEORelationshipPromise *)getRelationshipById:(NSString *)relationshipId {
    NEORelationshipPromise *promise = [[NEORelationshipPromise alloc] init];

    NSURLRequest *request = [self.requestBuilder requestForGetRelationshipById:relationshipId];

    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            [promise setError:dbError];
            return;
        }

        NSError *jsonParseError;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            [promise setError:dbError];
            return;
        }
        NEORelationship *relationship = [graph createRelationshipFromResult:dict];
        [promise setValue:relationship];

    }];
    return promise;
}

- (void)deleteRelationshipById:(NSString *)relationshipId withResultHandler:(void (^)(NEOError *))callback {

    NSURLRequest *request = [self.requestBuilder requestForDeleteRelationshipById:relationshipId];
    [self performDeleteWithRequest:request andHandler:callback];
}


- (void)getRelationships:(RELATIONSHIP_DIRECTION)direction forNodeId:(NSString *)nodeId andTypes:(NSArray *)types withResultHandler:(void (^)(NSArray *relationships, NEOError *error))callback {

    NSURLRequest *request = [self.requestBuilder requestForGetRelationships:direction forNodeId:nodeId andTypes:types];

    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(nil, dbError);
            return;
        }

        NSError *jsonParseError;
        NSArray *arrayOfRelationships = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }
        NSMutableArray *relationships = [NSMutableArray arrayWithCapacity:[arrayOfRelationships count]];
        for (NSDictionary *dict in arrayOfRelationships) {
            NEORelationship *relationship = [graph createRelationshipFromResult:dict];
            [relationships addObject:relationship];
        }

        callback([relationships copy], nil);
    }];
}

- (void)queryCypher:(NSString *)cypher withParameters:(NSDictionary *)paramsOrNil andResultHandler:(void (^)(NSDictionary *result, NEOError *error))callback {

    NSURLRequest *request = [self.requestBuilder requestForQueryWithCypher:cypher andParameters:paramsOrNil];

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(nil, dbError);
            return;
        }

        NSError *jsonParseError;
        NSDictionary *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }
        callback(result, nil);
    }];
}

- (id)convertToRightType:(id)dataObject {

    if ([dataObject isKindOfClass:[NSArray class]]) {
        NSArray *arrayObject = (NSArray *) dataObject;
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:arrayObject.count];
        for (id object in arrayObject) {
            id convertedObject = [self convertToRightType:object];
            [result addObject:convertedObject];
        }
        return [result copy];
    }

    if ([dataObject isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictObject = (NSDictionary *) dataObject;
        id object = [self createRelationshipFromResult:dictObject];
        if (object) {
            return object;
        }
        object = [self createNodeFromResult:dictObject];
        if (object) {
            return object;
        }
        object = [self createPathFromResult:dictObject];
        if (object) {
            return object;
        }
    }
    return dataObject;
}

- (void)queryCypher:(NSString *)cypher withParameters:(NSDictionary *)params andTypedResultHandler:(void (^)(NSArray *result, NEOError *error))callback {
    [self queryCypher:cypher withParameters:params andResultHandler:^(NSDictionary *result, NEOError *error) {
        if (error) {
            callback(nil, error);
            return;
        }
        NSArray *columns = [result objectForKey:@"columns"];
        NSArray *data = [result objectForKey:@"data"];
        NSMutableArray *typedResult = [NSMutableArray array];

        for (NSArray *row in data) {
            NSMutableDictionary *rowResult = [NSMutableDictionary dictionaryWithCapacity:[columns count]];
            NSUInteger index = 0;
            for (NSString *column in columns) {
                id dataObject = [row objectAtIndex:index];
                id typedObject = [self convertToRightType:dataObject];
                [rowResult setObject:typedObject forKey:column];
                index++;
            }
            [typedResult addObject:[rowResult copy]];
        }

        callback([typedResult copy], error);
    }];
}

- (void)createIndexWithName:(NSString *)name indexType:(IndexType)type configOrNil:(NSDictionary *)configOrNil promise:(NEOPromise *)promise {
    NSURLRequest *request = [self.requestBuilder requestForCreateIndexWithType:type name:name andConfig:configOrNil];
    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 201, data, dbError)) {
            [promise setError:dbError];
            return;
        }

        NEOIndex *index = [[NEOIndex alloc] initWithGraph:graph type:type andName:name];
        [promise setValue:index];

    }];
}

- (NEONodeIndexPromise *)createNodeIndexWithName:(NSString *)name andConfig:(NSDictionary *)configOrNil {
    NEONodeIndexPromise *promise = [[NEONodeIndexPromise alloc] init];
    [self createIndexWithName:name indexType:nodeIndex configOrNil:configOrNil promise:promise];
    return promise;
}

- (NEORelationshipIndexPromise *)createRelationshipIndexWithName:(NSString *)name andConfig:(NSDictionary *)configOrNil {
    NEORelationshipIndexPromise *promise = [[NEORelationshipIndexPromise alloc] init];
    [self createIndexWithName:name indexType:relationshipIndex configOrNil:configOrNil promise:promise];
    return promise;
}

- (void)deleteNodeIndexByName:(NSString *)name withResultHandler:(void (^)(NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForDeleteIndexWithType:nodeIndex name:name];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (void)deleteRelationshipIndexByName:(NSString *)name withResultHandler:(void (^)(NEOError *error))callback {
    NSURLRequest *request = [self.requestBuilder requestForDeleteIndexWithType:relationshipIndex name:name];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (void)getIndexWithName:(NSString *)name promise:(NEOPromise *)promise type:(IndexType)type {
    NSURLRequest *request = [self.requestBuilder requestForGetIndexWithType:type name:name];
    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];

        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            [promise setError:dbError];
            return;
        }

        NEOIndex *index = [[NEOIndex alloc] initWithGraph:graph type:type andName:name];
        [promise setValue:index];
    }];
}

- (NEONodeIndexPromise *)getNodeIndexWithName:(NSString *)name {
    NEONodeIndexPromise *promise = [[NEONodeIndexPromise alloc] init];
    [self getIndexWithName:name promise:promise type:nodeIndex];
    return promise;
}

- (NEORelationshipIndexPromise *)getRelationshipIndexWithName:(NSString *)name {
    NEORelationshipIndexPromise *promise = [[NEORelationshipIndexPromise alloc] init];
    [self getIndexWithName:name promise:promise type:relationshipIndex];
    return promise;
}

- (void)getAllIndexesWithHandler:(void (^)(NSArray *, NEOError *))callback indexType:(IndexType)type request:(NSURLRequest *)request {
    __weak NEOGraphDatabase *graph = self;

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];
        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(nil, dbError);
            return;
        }

        NSError *jsonParseError;
        NSDictionary *resultData = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }

        NSMutableArray *result = [NSMutableArray array];
        [resultData enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            NEOIndex *index = [[NEOIndex alloc] initWithGraph:graph type:type andName:key];
            [result addObject:index];
        }];
        callback(result, nil);
    }];
}

- (void)getAllNodeIndexesWithHandler:(void (^)(NSArray *indexes, NEOError* error))callback{
    NSURLRequest *request = [self.requestBuilder requestForGetAllIndexesOfType:nodeIndex];
    [self getAllIndexesWithHandler:callback indexType:nodeIndex request:request];
}

- (void)getAllRelationshipIndexesWithHandler:(void (^)(NSArray *indexes, NEOError* error))callback{
    NSURLRequest *request = [self.requestBuilder requestForGetAllIndexesOfType:relationshipIndex];
    [self getAllIndexesWithHandler:callback indexType:relationshipIndex request:request];
}

- (void)addByURI:(NSString *)uri indexName:(NSString *)indexName indexType:(IndexType)type key:(NSString *)key value:(NSString *)value callback:(void (^)(NEOError *))callback {
    NSURLRequest *request = [self.requestBuilder requestForAddByURI:uri indexType:type name:indexName key:key andValue:value];

    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];
        if (foundUnexpectedHTTPError(res, error, 201, data, dbError)) {
            callback(dbError);
            return;
        }
        callback(nil);
    }];
}

- (void)addNodeByURI:(NSString *)nodeURI toIndex:(NSString *)indexName forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *))callback {
    [self addByURI:nodeURI indexName:indexName indexType:nodeIndex key:key value:value callback:callback];
}

- (void)addRelationshipByURI:(NSString *)relationshipURI toIndex:(NSString *)indexName forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *))callback {
    [self addByURI:relationshipURI indexName:indexName indexType:relationshipIndex key:key value:value callback:callback];
}

- (void)removeNodeById:(NSString *)nodeId fromIndex:(NSString *)indexName forKey:(NSString *)keyOrNil andValue:(NSString *)valueOrNil withResultHandler:(void (^)(NEOError *))callback{
    NSURLRequest *request = [self.requestBuilder requestForRemoveById:nodeId indexType:nodeIndex name:indexName key:keyOrNil andValue:valueOrNil];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (void)removeRelationshipById:(NSString *)nodeId fromIndex:(NSString *)indexName forKey:(NSString *)keyOrNil andValue:(NSString *)valueOrNil withResultHandler:(void (^)(NEOError *error))callback{
    NSURLRequest *request = [self.requestBuilder requestForRemoveById:nodeId indexType:relationshipIndex name:indexName key:keyOrNil andValue:valueOrNil];
    [self performDeleteWithRequest:request andHandler:callback];
}

- (void)findByExactMatchForIndex:(NSString *)indexName key:(NSString *)key value:(NSString *)value callback:(void (^)(NSArray *, NEOError *))callback type:(IndexType)type {
    NSURLRequest *request = [self.requestBuilder requestForFindByExactMatchForIndexType:type name:indexName key:key andValue:value];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];
        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(nil, dbError);
            return;
        }

        NSError *jsonParseError;
        NSArray *result = [NSJSONSerialization JSONObjectWithData:data options:NSJSONWritingPrettyPrinted error:&jsonParseError];
        if (jsonParseError) {
            [dbError addMessage:[NSString stringWithFormat:@"Technical Error on JSON Parsing. %@", jsonParseError.userInfo]];
            callback(nil, dbError);
            return;
        }
        NSMutableArray *dataResult = [NSMutableArray arrayWithCapacity:result.count];
        for (NSDictionary *elementResult in result) {
            [dataResult addObject:[self convertToRightType:elementResult]];
        }
        callback(dataResult, nil);
    }];
}

- (void)findNodesByExactMatchForIndex:(NSString*)indexName key:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback{
    [self findByExactMatchForIndex:indexName key:key value:value callback:callback type:nodeIndex];
}

- (void)findRelationshipByExactMatchForIndex:(NSString *)indexName key:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NSArray *, NEOError *))callback {
    [self findByExactMatchForIndex:indexName key:key value:value callback:callback type:relationshipIndex];
}

- (NEOBatchOperationBuilder*)createBatchBuilder{
    return [[NEOBatchOperationBuilder alloc] initWithGraph:self];
}

-(void)executeBatchOperations:(NSArray*)operations withResultHandler:(void (^)(NEOError *error))callback{
    NSURLRequest *request = [self.requestBuilder requestForExecuteBatchOperations:operations];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler:^(NSURLResponse *res, NSData *data, NSError *error) {
        NEOError *dbError = [[NEOError alloc] init];
        if (foundUnexpectedHTTPError(res, error, 200, data, dbError)) {
            callback(dbError);
            return;
        }
        
        callback(nil);
    }];
}

@end