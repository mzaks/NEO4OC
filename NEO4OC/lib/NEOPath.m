
#import "NEOPath.h"
#import "NEOGraphDatabase_Internal.h"

static NSOperationQueue * queue;

@implementation NEOPath{
    NEOGraphDatabase * _graph;
    NSString * _startId;
    NSString * _endId;
    NSUInteger _length;
    NSArray * _nodes;
    NSArray * _relationships;
}

- (id)initWithGraph:(__weak NEOGraphDatabase *)database startId:(NSString*)start endId:(NSString*)end length:(NSUInteger)pathLength nodes:(NSArray*)nodes relationships:(NSArray*)relationships{
    self = [super init];
    if(self){
        _graph = database;
        _startId = start;
        _endId = end;
        _length = pathLength;
        _nodes = nodes;
        _relationships = relationships;
    }
    return self;
}

-(NEONodePromise*)startNode{
    return [_graph getNodeById:_startId];
}

-(NEONodePromise*)endNode{
    return [_graph getNodeById:_endId];
}

-(NSUInteger)length{
    return _length;
}

-(void)iterateThroughNodes:(void(^)(id<NEONode> data, NEOError* error, BOOL *stop))iteratee{
    if (!queue){
        queue = [[NSOperationQueue alloc] init];
    }
    __weak NEOGraphDatabase *graph = _graph;
    __weak NSArray * nodes = _nodes;
    
    [queue addOperationWithBlock:^{
        BOOL stop = NO;
        for (NSString * nodeURI in nodes) {
            if (stop) {
                break;
            }
            NEONodePromise * promise = [[graph getNodeById:idOfURI(nodeURI)] wait];
            iteratee(promise, promise.error, &stop);
        }
    }];
    
}

-(void)iterateThroughRelationships:(void(^)(id<NEORelationship> data, NEOError* error, BOOL *stop))iteratee{
    if (!queue){
        queue = [[NSOperationQueue alloc] init];
    }
    __weak NEOGraphDatabase *graph = _graph;
    __weak NSArray * relationships = _relationships;
    [queue addOperationWithBlock:^{
        BOOL stop = NO;
        for (NSString * relationshipURI in relationships) {
            if (stop) {
                break;
            }
            NEORelationshipPromise * promise = [[graph getRelationshipById:idOfURI(relationshipURI)] wait];
            iteratee(promise, promise.error, &stop);
        }
    }];
}

-(NSString*)description{    
    return [NSString stringWithFormat:@"Path with start:%@ end:%@ length:%i nodes:%@ relationships:%@", _startId, _endId, _length, _nodes, _relationships];
}

@end
