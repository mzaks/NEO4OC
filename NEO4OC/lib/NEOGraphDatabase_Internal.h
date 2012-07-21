//
//  NEOGraphDatabase_Internal.h
//  NEO4OC
//
//  Created by Maxim Zaks on 21.07.12.
//  Copyright (c) 2012 Besitzer. All rights reserved.
//

#import "NEOGraphDatabase.h"

@interface NEOGraphDatabase (Internal)

// Nodes
- (void)deleteNodeById:(NSString *)nodeId withResultHandler:(void (^)(NEOError *error))callback;
- (void)fetchDataForNodeId:(NSString*)nodeId withResultHandler:(void(^)(NSDictionary* data, NEOError* error))callback;
- (void)setData:(NSDictionary*)newDataOrEmpty forNodeId:(NSString*)nodeId withResultHandler:(void (^)(NEOError *error))callback;

// Relationships
- (NEORelationshipPromise *)getRelationshipById:(NSString *)relationshipId;
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


@end
