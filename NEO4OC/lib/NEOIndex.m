
#import "NEOIndex.h"
#import "NEOGraphDatabase_Internal.h"

@implementation NEOIndex {
    NSString *_indexName;
    NEOGraphDatabase *_graph;
    IndexType _type;
}

- (id)initWithGraph:(__weak NEOGraphDatabase *)database type:(IndexType)type andName:(NSString *)name {
    self = [super init];
    if (self) {
        _indexName = name;
        _graph = database;
        _type = type;
    }
    return self;
}

- (NSString *)indexName {
    return _indexName;
}

- (void)deleteWithResultHandler:(void (^)(NEOError *))callback {
    if (_type == nodeIndex) {
        [_graph deleteNodeIndexByName:_indexName withResultHandler:^(NEOError *error) {
            if (!error) {
                _indexName = nil;
            }
            callback(error);
        }];
    } else {
        [_graph deleteRelationshipIndexByName:_indexName withResultHandler:^(NEOError *error) {
            if (!error) {
                _indexName = nil;
            }
            callback(error);
        }];
    }

}

- (void)addNode:(id <NEONode>)node forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *))callback {

    if ([node isKindOfClass:[NEONodePromise class]]) {
        NEONodePromise *promise = (NEONodePromise *) node;
        [promise waitForNodeWithHandler:^(id <NEONode> node1, NEOError *error) {
            [_graph addNodeByURI:node1.nodeURI toIndex:self.indexName forKey:key andValue:value withResultHandler:callback];
        }];

    } else {
        [_graph addNodeByURI:node.nodeURI toIndex:self.indexName forKey:key andValue:value withResultHandler:callback];
    }
}

- (void)addRelationship:(id <NEORelationship>)relationship forKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NEOError *error))callback {
    if ([relationship isKindOfClass:[NEORelationshipPromise class]]) {
        NEORelationshipPromise *promise = (NEORelationshipPromise *) relationship;
        [promise waitForRelationshipWithHandler:^(id <NEORelationship> rel, NEOError *error) {
            [_graph addRelationshipByURI:rel.relationshipURI toIndex:self.indexName forKey:key andValue:value withResultHandler:callback];
        }];

    } else {
        [_graph addRelationshipByURI:relationship.relationshipURI toIndex:self.indexName forKey:key andValue:value withResultHandler:callback];
    }
}

- (void)removeNode:(id <NEONode>)node forKey:(NSString *)keyOrNil andValue:(NSString *)valueOrNil withResultHandler:(void (^)(NEOError *))callback {

    if ([node isKindOfClass:[NEONodePromise class]]) {
        NEONodePromise *promise = (NEONodePromise *) node;
        [promise waitForNodeWithHandler:^(id <NEONode> node1, NEOError *error) {
            [_graph removeNodeById:node1.nodeId fromIndex:self.indexName forKey:keyOrNil andValue:valueOrNil withResultHandler:callback];
        }];

    } else {
        [_graph removeNodeById:node.nodeId fromIndex:self.indexName forKey:keyOrNil andValue:valueOrNil withResultHandler:callback];
    }
}

- (void)removeRelationship:(id<NEORelationship>)relationship forKey:(NSString*)keyOrNil andValue:(NSString*)valueOrNil withResultHandler:(void (^)(NEOError *error))callback{
    if ([relationship isKindOfClass:[NEORelationshipPromise class]]) {
            NEORelationshipPromise *promise = (NEORelationshipPromise *) relationship;
            [promise waitForRelationshipWithHandler:^(id <NEORelationship> rel, NEOError *error) {
                [_graph removeRelationshipById:rel.relationshipId fromIndex:self.indexName forKey:keyOrNil andValue:valueOrNil withResultHandler:callback];
            }];

        } else {
            [_graph removeRelationshipById:relationship.relationshipId fromIndex:self.indexName forKey:keyOrNil andValue:valueOrNil withResultHandler:callback];
        }
}

- (void)findNodesByExactMatchForKey:(NSString *)key andValue:(NSString *)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback {
    [_graph findNodesByExactMatchForIndex:self.indexName key:key andValue:value withResultHandler:callback];
}

- (void)findRelationshipsByExactMatchForKey:(NSString*)key andValue:(NSString*)value withResultHandler:(void (^)(NSArray *result, NEOError *error))callback{
    [_graph findRelationshipByExactMatchForIndex:self.indexName key:key andValue:value withResultHandler:callback];
}

- (NSString *)description {
    NSString *typeString;
    if (_type == nodeIndex) {
        typeString = @"Node";
    } else {
        typeString = @"Relationship";
    }
    return [NSString stringWithFormat:@"%@ index with name: %@", typeString, _indexName];
}

@end

@implementation NEONodeIndexPromise

- (void)waitForIndexWithHandler:(void (^)(id <NEONodeIndex> value, NEOError *error))callback {
    return [self waitWithHandler:^(id value, NEOError *error) {
        callback(value, error);
    }];
}

@end

@implementation NEORelationshipIndexPromise

- (void)waitForIndexWithHandler:(void (^)(id <NEORelationshipIndex> value, NEOError *error))callback {
    return [self waitWithHandler:^(id value, NEOError *error) {
        callback(value, error);
    }];
}

@end