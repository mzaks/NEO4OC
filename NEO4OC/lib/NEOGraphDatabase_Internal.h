/*
 The MIT License (MIT)
 Copyright (c) 2012 Maxim Zaks (maxim.zaks@gmail.com)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 */

#import "NEOGraphDatabase.h"

@interface NEOGraphDatabase (Internal)

// Nodes
- (void)deleteNodeById:(NSString *)nodeId withResultHandler:(void (^)(NEOError *error))callback;
- (void)fetchDataForNodeId:(NSString*)nodeId withResultHandler:(void(^)(NSDictionary* data, NEOError* error))callback;
- (void)setData:(NSDictionary*)newDataOrEmpty forNodeId:(NSString*)nodeId withResultHandler:(void (^)(NEOError *error))callback;

// Relationships
- (NEORelationshipPromise *)createRelationshipOfType:(NSString *)type fromNode:(id<NEONode>)node1 toNode:(id<NEONode>)node2 withData:(NSDictionary *)theDataOrNil;
- (void)deleteRelationshipById:(NSString *)relationshipId withResultHandler:(void (^)(NEOError *error))callback;
- (void)fetchDataForRelationshipId:(NSString*)relId withResultHandler:(void(^)(NSDictionary* data, NEOError* error))callback;
- (void)setData:(NSDictionary*)newDataOrEmpty forRelationshipId:(NSString*)relId withResultHandler:(void (^)(NEOError *error))callback;
- (void)getRelationships:(RELATIONSHIP_DIRECTION)direction forNodeId:(NSString *)nodeId andTypes:(NSArray *)typesOrNil withResultHandler:(void(^)(NSArray * relationships, NEOError * error))callback;

// Cypher
- (void)queryCypher:(NSString *)cypher withParameters:(NSDictionary *)paramsOrNil andResultHandler:(void (^)(NSDictionary *result, NEOError *error))callback;

// Indexes
- (void)deleteNodeIndexByName:(NSString*)name withResultHandler:(void (^)(NEOError *error))callback;
- (void)deleteRelationshipIndexByName:(NSString *)name withResultHandler:(void (^)(NEOError *error))callback;

- (void)addNodeByURI:(NSString *)nodeURI toIndex:(NSString *)indexName forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *error))callback;
- (void)removeNodeById:(NSString *)nodeId fromIndex:(NSString *)indexName forKey:(NSString *)keyOrNil andValue:(NSString *)valueOrNil withResultHandler:(void (^)(NEOError *error))callback;
- (void)findNodesByExactMatchForIndex:(NSString*)indexName key:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback;

- (void)addRelationshipByURI:(NSString *)relationshipURI toIndex:(NSString *)indexName forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *))callback;
- (void)removeRelationshipById:(NSString *)nodeId fromIndex:(NSString *)indexName forKey:(NSString *)keyOrNil andValue:(NSString *)valueOrNil withResultHandler:(void (^)(NEOError *error))callback;
- (void)findRelationshipByExactMatchForIndex:(NSString*)indexName key:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback;

-(void)executeBatchOperations:(NSArray*)operations withResultHandler:(void (^)(NEOError *error))callback;
@end
