
#import "NEO4OCTests.h"
#import "NEOGraphDatabase.h"
#import "NEONode.h"
#import "NEOError.h"
#import "NEOPath.h"

#define START_WAIT __block int wait = 1
#define END_WAIT while(wait>0){}

@implementation NEO4OCTests {
    NEOGraphDatabase *graph;
}

- (void)setUp {
    [super setUp];
    graph = [[NEOGraphDatabase alloc] initWithURL:[NSURL URLWithString:@"http://localhost:7474"]];
}

- (void)tearDown {
    // Tear-down code here.

    [super tearDown];
}

- (void)testInitGraph {
    STAssertNotNil(graph, @"Not nil");
}

- (void)testGetInfo {
    __block NSDictionary *latch = nil;
    NSLog(@"Start");
    [graph getInfo:^(NSDictionary *info, NEOError *error) {
        latch = [info copy];
    }];
    while (latch == nil) {
        //NSLog(@"Waiting");
    }
    NSLog(@"Info: %@", latch);
}

- (void)testCreateAndDeleteNode {
    NEONodePromise *promise = [graph createNodeWithData:nil];
    STAssertNotNil(promise.nodeURI, @"node URI shold not be nil");
    NSString *nodeId = [promise nodeId];
    STAssertNotNil(nodeId, @"node Id shold not be nil");
    __block NSString *wait = @"Wait";
    [promise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should be nil");
        NSLog(@"Deleted nodeId: %@", nodeId);
        wait = nil;
    }];
    while (wait) {}
}

- (void)testCreateNodeWithData {
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Maxim" forKey:@"name"];
    NEONodePromise *promise = [graph createNodeWithData:data];
    NSString *nodeId = promise.nodeId;
    STAssertEqualObjects(data, promise.data, @"Node should have the same data");
    __block NSString *wait = @"Wait";
    [promise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should be nil");
        NSLog(@"Deleted nodeId: %@", nodeId);
        wait = nil;
    }];
    while (wait) {}
}

- (void)testDeleteNoneExistingNode {
    __block NSString *wait = @"Wait";
    [graph deleteNodeById:@"9999999" withResultHandler:^(NEOError *error) {
        STAssertNotNil(error, @"Should not be nil");
        NSLog(@"Error emssage, %@", error.messages);
        wait = nil;
    }];
    while (wait) {}
}

- (void)testDeleteNodeRemovesData {
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"Maxim" forKey:@"name"];
    NEONodePromise *promise = [graph createNodeWithData:data];
    NSString *nodeId = promise.nodeId;
    STAssertEqualObjects(data, promise.data, @"Node should have the same data");
    __block NSString *wait = @"Wait";
    [promise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should be nil");
        NSLog(@"Deleted nodeId: %@", nodeId);
        wait = nil;
    }];
    while (wait) {}
    STAssertNil(promise.data, @"Data should be nil after node is removed");
    STAssertNil(promise.nodeURI, @"Data should be nil after node is removed");
    STAssertNil(promise.nodeId, @"Data should be nil after node is removed");
}

- (void)testOrphanAndDeleteNode {
    NEONodePromise *promise = [graph createNodeWithData:nil];
    [[promise createRelationshipOfType:@"self" toNode:promise andData:nil] wait];
    NSString *nodeId = promise.nodeId;
    START_WAIT;
    [promise getAllRelationshipsOfTypes:nil withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"Unexpected error : %@", error);
        STAssertTrue(relationships.count == 1, @"Unexpected number of relationships : %i", relationships.count);
        wait--;
    }];
    END_WAIT;
    wait++;
    [promise orphanNodeAndDeleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Unexpected error : %@", error);
        wait--;
    }];
    END_WAIT;
    NEONodePromise * promise1 = [[graph getNodeById:nodeId] wait];
    STAssertNotNil(promise1.error, @"Unexpected no node: %@", promise1);
}

- (void)testGetNode {
    NEONodePromise *promise = [graph getNodeById:@"0"];
    NSDictionary *data = promise.data;
    STAssertEqualObjects([data objectForKey:@"name"], @"First One", @"Check for expected name");
    STAssertEqualObjects([data objectForKey:@"foo"], @"", @"Check for expected name");
    STAssertNil([data objectForKey:@"blob"], @"Unexpected property should be nil");
    STAssertNil(promise.error, @"Unexpected property should be nil");
}

- (void)testGetInvalidNode {
    NEONodePromise *promise = [graph getNodeById:@"9999999999"];
    NSDictionary *data = promise.data;
    STAssertNil(data, @"No data for Invalid node");
    NEOError *error = promise.error;
    STAssertNotNil(error, @"Should not be nil");
    NSLog(@"Error: %@", error);
}

- (void)testCreateRelationship {
    NSDictionary *data = [NSDictionary dictionaryWithObject:@"123" forKey:@"cid"];
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node1" forKey:@"name"]];
    NEONodePromise *promise2 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node2" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [graph createRelationshipOfType:@"friend" fromNode:promise1 toNode:promise2 withData:data];
    STAssertNotNil(relPromise.relationshipId, @"Shoudl have relationship ID");
    STAssertEqualObjects(relPromise.startNodeId, promise1.nodeId, @"Should have the right starNodeId");
    STAssertEqualObjects(relPromise.endNodeId, promise2.nodeId, @"Should have the right endNodeId");
    STAssertEqualObjects(relPromise.data, data, @"Should have the right data");
    STAssertEqualObjects(relPromise.type, @"friend", @"Should have the right type");
    NSLog(@"Created relationship: %@", relPromise);
}

- (void)testCreateRelationshipFromNode {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Self Refered Node" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [promise1 createRelationshipOfType:@"me" toNode:promise1 andData:nil];
    STAssertNotNil(relPromise.relationshipId, @"Shoudl have relationship ID");
    NSLog(@"Created relationship: %@", relPromise);
}

- (void)testCreateRelationshipAndThenGetItFromGraph {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Self Refered Node" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [promise1 createRelationshipOfType:@"me" toNode:promise1 andData:nil];
    STAssertNotNil(relPromise.relationshipId, @"Shoudl have relationship ID");
    NEORelationshipPromise *relPromise2 = [graph getRelationshipById:relPromise.relationshipId];
    STAssertEqualObjects(relPromise.startNodeId, relPromise2.startNodeId, @"Should have the right starNodeId");
    STAssertEqualObjects(relPromise.endNodeId, relPromise2.endNodeId, @"Should have the right endNodeId");
    STAssertEqualObjects(relPromise.relationshipId, relPromise2.relationshipId, @"Should have equal IDs");
}

- (void)testCreateRelationshipAndThenGetStartAndEndNodes {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node A" forKey:@"name"]];
    NEONodePromise *promise2 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node B" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [promise1 createRelationshipOfType:@"rel" toNode:promise2 andData:nil];
    STAssertNotNil(relPromise.relationshipId, @"Shoudl have relationship ID");
    NEONodePromise *startNode = relPromise.startNode;
    STAssertEqualObjects(startNode.data, promise1.data, @"Should have the right starNode");
    NEONodePromise *endNode = relPromise.endNode;
    STAssertEqualObjects(endNode.data, promise2.data, @"Should have the right endNode");
}

- (void)testGetInvalidRelationship {
    NEORelationshipPromise *promise = [graph getRelationshipById:@"9999999999"];
    NSDictionary *data = promise.data;
    STAssertNil(data, @"No data for Invalid node");
    NEOError *error = promise.error;
    STAssertNotNil(error, @"Should not be nil");
    NSLog(@"Error: %@", error);
}

- (void)testDeleteRelationshipById {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Self Refered Node" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [promise1 createRelationshipOfType:@"me" toNode:promise1 andData:nil];
    __block NSString *wait = @"";
    [graph deleteRelationshipById:relPromise.relationshipId withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"No error should accure");
        wait = @"done";
    }];
    while ([wait isEqualToString:@""]) {}
}

- (void)testDeleteRelationshipByWrongId {
    __block NSString *wait = @"";
    [graph deleteRelationshipById:@"99999999999999999" withResultHandler:^(NEOError *error) {
        STAssertNotNil(error, @"Error should accure");
        NSLog(@"Error : %@", error);
        wait = @"done";
    }];
    while ([wait isEqualToString:@""]) {}
}

- (void)testDeleteRelationship {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Self Refered Node" forKey:@"name"]];
    NEORelationshipPromise *relPromise = [promise1 createRelationshipOfType:@"me" toNode:promise1 andData:nil];
    __block NSString *wait = @"";
    [relPromise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"No error should accure");
        wait = @"done";
    }];
    while ([wait isEqualToString:@""]) {}
    STAssertNil(relPromise.relationshipId, @"Should be deleted");
    STAssertNil(relPromise.relationshipURI, @"Should be deleted");
    STAssertNil(relPromise.startNodeId, @"Should be deleted");
    STAssertNil(relPromise.endNodeId, @"Should be deleted");
    STAssertNil(relPromise.type, @"Should be deleted");
    STAssertNil(relPromise.data, @"Should be deleted");
}

- (void)testGetRelationshipsFromNode {
    NEONodePromise *promise1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node1" forKey:@"name"]];
    NEONodePromise *promise2 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node2" forKey:@"name"]];
    NEONodePromise *promise3 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node3" forKey:@"name"]];

    NEORelationshipPromise *relPromise1 = [promise1 createRelationshipOfType:@"A" toNode:promise2 andData:nil];
    //[NEOPromise waitForPromises:relPromise1, nil];
    NEORelationshipPromise *relPromise2 = [promise1 createRelationshipOfType:@"A" toNode:promise3 andData:nil];
    //[NEOPromise waitForPromises:relPromise2, nil];
    NEORelationshipPromise *relPromise3 = [promise2 createRelationshipOfType:@"B" toNode:promise1 andData:nil];
    //[NEOPromise waitForPromises:relPromise3, nil];
    NEORelationshipPromise *relPromise4 = [promise1 createRelationshipOfType:@"C" toNode:promise3 andData:nil];
    //[NEOPromise waitForPromises:relPromise4, nil];
    [NEOPromise waitForPromises:relPromise1, relPromise2, relPromise3, relPromise4, nil];

    STAssertNil(relPromise1.error, @"Unexpected error %@", relPromise1.error);
    STAssertNil(relPromise2.error, @"Unexpected error %@", relPromise2.error);
    STAssertNil(relPromise3.error, @"Unexpected error %@", relPromise3.error);
    STAssertNil(relPromise4.error, @"Unexpected error %@", relPromise4.error);

    __block NSInteger wait = 0;
    [promise1 getAllRelationshipsOfTypes:nil withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"No errors");
        STAssertTrue([relationships count] == 4, @"Shoud have 4 relationships %@", relationships);
        wait++;
    }];
    [promise1 getOutgoingRelationshipsOfTypes:nil withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"No errors");
        STAssertTrue([relationships count] == 3, @"Shoud have 3 relationships %@", relationships);
        wait++;

    }];
    [promise1 getIncomingRelationshipsOfTypes:nil withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"No errors");
        STAssertTrue([relationships count] == 1, @"Shoud have 1 relationships %@", relationships);
        wait++;

    }];
    [promise1 getAllRelationshipsOfTypes:[NSArray arrayWithObject:@"A"] withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"No errors");
        STAssertTrue([relationships count] == 2, @"Shoud have 2 relationships");
        wait++;
    }];
    [promise1 getAllRelationshipsOfTypes:[NSArray arrayWithObjects:@"A", @"B", nil] withResultHandler:^(NSArray *relationships, NEOError *error) {
        STAssertNil(error, @"No errors");
        STAssertTrue([relationships count] == 3, @"Shoud have 3 relationships %@", relationships);
        wait++;
    }];
    while (wait < 5) {}
}

- (void)testCypher {
    NEONodePromise *node1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node1" forKey:@"name"]];
    NEONodePromise *node2 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node2" forKey:@"name"]];
    NEONodePromise *node3 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node3" forKey:@"name"]];
    NEORelationshipPromise *rel1 = [node1 createRelationshipOfType:@"A" toNode:node2 andData:nil];
    NEORelationshipPromise *rel2 = [node2 createRelationshipOfType:@"B" toNode:node3 andData:nil];
    [NEOPromise waitForPromises:rel1, rel2, nil];

    NSNumber *nodeId = [NSNumber numberWithInt:node1.nodeId.intValue];
    NSDictionary *params = [NSDictionary dictionaryWithObject:nodeId forKey:@"startNodeId"];
    NSString *cypher = @"START n = node({startNodeId}) MATCH path = n-[r*]->b RETURN b, r, path";
    __block int wait = 0;
    [graph queryCypher:cypher withParameters:params andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNotNil(result, @"Result should not be nil, error: %@", error.description);
        NEOPath *path = [[result objectAtIndex:0] objectForKey:@"path"];
        STAssertNotNil(path, @"Path should not be nil.");
        STAssertTrue(path.length == 1, @"path length");
        STAssertEqualObjects([[path.startNode wait] nodeId], node1.nodeId, @"path start node");
        STAssertEqualObjects([[path.endNode wait] nodeId], node2.nodeId, @"path start node");
        wait++;
    }];
    while (wait == 0) {}
}

- (void)testFetchPropertyForNode {
    NSDictionary *myData = [NSDictionary dictionaryWithObject:@"klop" forKey:@"mop"];
    NEONodePromise *node1 = [graph createNodeWithData:myData];
    __block int wait = 0;
    [node1 fetchData:^(NSDictionary *data, NEOError *error) {
        STAssertNil(error, @"Should not have errors, error: %@", error.description);
        STAssertEqualObjects(data, myData, @"data should stay same");
        wait++;
    }];
    while (wait == 0) {}
}

- (void)testSetPropertyForNode {
    NSDictionary *myData = [NSDictionary dictionaryWithObject:@"klop" forKey:@"mop"];
    NSDictionary *newData = [NSDictionary dictionaryWithObject:@"kas" forKey:@"mas"];
    NEONodePromise *node1 = [graph createNodeWithData:myData];
    STAssertEqualObjects(node1.data, myData, @"data should stay same");
    __block int wait = 0;
    [node1 setData:newData withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should not have errors, error: %@", error.description);
        wait++;
    }];
    while (wait == 0) {}

    STAssertEqualObjects(node1.data, newData, @"data should stay same");
}

- (void)testSetPropertyForNodeToNil {
    NSDictionary *myData = [NSDictionary dictionaryWithObject:@"klop" forKey:@"mop"];
    NEONodePromise *node1 = [graph createNodeWithData:myData];
    STAssertEqualObjects(node1.data, myData, @"data should stay same");
    __block int wait = 0;
    [node1 setData:nil withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should not have errors, error: %@", error.description);
        wait++;
    }];
    while (wait == 0) {}

    STAssertNil(node1.data, @"data should stay same");
}

- (void)testSetPropertyForRelationship {
    NSDictionary *myData = [NSDictionary dictionaryWithObject:@"klop" forKey:@"mop"];
    NSDictionary *newData = [NSDictionary dictionaryWithObject:@"klop2" forKey:@"mop2"];
    NEONodePromise *node1 = [graph createNodeWithData:nil];
    NEORelationshipPromise *rel = [node1 createRelationshipOfType:@"me" toNode:node1 andData:myData];
    STAssertEqualObjects(rel.data, myData, @"data should stay same");
    __block int wait = 0;
    [rel setData:newData withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"Should not have errors, error: %@", error.description);
        wait++;
    }];
    while (wait == 0) {}

    STAssertEqualObjects(rel.data, newData, @"data should stay same");
}

- (void)testFetchPropertyForRelationship {
    NSDictionary *myData = [NSDictionary dictionaryWithObject:@"klop" forKey:@"mop"];
    NEONodePromise *node1 = [graph createNodeWithData:nil];
    NEORelationshipPromise *rel = [node1 createRelationshipOfType:@"me" toNode:node1 andData:myData];
    STAssertEqualObjects(rel.data, myData, @"data should stay same");
    __block int wait = 0;
    [rel fetchData:^(NSDictionary *data, NEOError *error) {
        STAssertNil(error, @"Should not have errors, error: %@", error.description);
        STAssertEqualObjects(data, myData, @"data should stay same");
        wait++;
    }];
    while (wait == 0) {}
}

- (void)testIterateThroughPath {
    NEONodePromise *node1 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node1" forKey:@"name"]];
    NEONodePromise *node2 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node2" forKey:@"name"]];
    NEONodePromise *node3 = [graph createNodeWithData:[NSDictionary dictionaryWithObject:@"Node3" forKey:@"name"]];
    NEORelationshipPromise *rel1 = [node1 createRelationshipOfType:@"A" toNode:node2 andData:nil];
    NEORelationshipPromise *rel2 = [node2 createRelationshipOfType:@"B" toNode:node3 andData:nil];
    [NEOPromise waitForPromises:rel1, rel2, nil];

    NSNumber *nodeId = [NSNumber numberWithInt:node1.nodeId.intValue];
    NSNumber *nodeId2 = [NSNumber numberWithInt:node3.nodeId.intValue];
    NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:nodeId, @"startNodeId", nodeId2, @"endNode", nil];
    NSString *cypher = @"START n = node({startNodeId}), b = node({endNode}) MATCH path = n-[r*]->b RETURN path";

    __block int wait = 0;
    [graph queryCypher:cypher withParameters:params andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNotNil(result, @"Result should not be nil, error: %@", error.description);
        NSLog(@"Result of cypher: %@", result);
        NEOPath *path = [[result objectAtIndex:0] objectForKey:@"path"];
        __block int count = 0;
        [path iterateThroughNodes:^(id <NEONode> data, NEOError *error, BOOL *stop) {
            STAssertNotNil(data, @"Result should not be nil, error: %@", data);
            count++;
        }];
        while (count < 3) {
        }
        wait++;
    }];
    while (wait == 0) {}

    wait = 0;
    [graph queryCypher:cypher withParameters:params andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNotNil(result, @"Result should not be nil, error: %@", error.description);
        NSLog(@"Result of cypher: %@", result);
        NEOPath *path = [[result objectAtIndex:0] objectForKey:@"path"];
        __block int count = 0;
        [path iterateThroughNodes:^(id <NEONode> data, NEOError *error, BOOL *stop) {
            STAssertNotNil(data, @"Result should not be nil, error: %@", data);
            count++;
            if (count == 2) {
                *stop = YES;
            }
        }];
        sleep(1);
        STAssertTrue(count == 2, @"should only increase count by one");
        wait++;
    }];
    while (wait == 0) {}

    wait = 0;
    [graph queryCypher:cypher withParameters:params andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNotNil(result, @"Result should not be nil, error: %@", error.description);
        NSLog(@"Result of cypher: %@", result);
        NEOPath *path = [[result objectAtIndex:0] objectForKey:@"path"];
        __block int count = 0;
        [path iterateThroughRelationships:^(id <NEORelationship> data, NEOError *error, BOOL *stop) {
            STAssertNotNil(data, @"Result should not be nil, error: %@", data);
            count++;
        }];
        while (count != 2) {};
        wait++;
    }];
    while (wait == 0) {}

    wait = 0;
    [graph queryCypher:cypher withParameters:params andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNotNil(result, @"Result should not be nil, error: %@", error.description);
        NSLog(@"Result of cypher: %@", result);
        NEOPath *path = [[result objectAtIndex:0] objectForKey:@"path"];
        __block int count = 0;
        [path iterateThroughRelationships:^(id <NEORelationship> data, NEOError *error, BOOL *stop) {
            STAssertNotNil(data, @"Result should not be nil, error: %@", data);
            count++;
            *stop = YES;
        }];
        sleep(1);
        STAssertTrue(count == 1, @"should only increase count by one");
        wait++;
    }];
    while (wait == 0) {}
}

- (void)testNodeIndex {
    NEONodeIndexPromise *promise = [graph createNodeIndexWithName:@"myIndex" andConfig:nil];
    STAssertEqualObjects(promise.indexName, @"myIndex", @"name should be right");
    NSLog(@"%@", promise);

    NEONodeIndexPromise *promise1 = [graph getNodeIndexWithName:@"myIndex"];
    STAssertEqualObjects(promise1.indexName, @"myIndex", @"name should be right");

    __block BOOL waiting = YES;
    [promise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"should delete without errors");
        waiting = NO;
    }];
    while (waiting) {}

    NEONodeIndexPromise *promise2 = [graph getNodeIndexWithName:@"myIndex"];
    [promise2 wait];
    NSLog(@"%@", promise2.error);
    STAssertNotNil(promise2.error, @"myIndex is deleted");
}

- (void)testAddNodeToIndex {
    NEONodeIndexPromise *index = [graph createNodeIndexWithName:@"nodeIndex" andConfig:nil];
    NEONodePromise *node = [graph createNodeWithData:nil];
    __block BOOL waiting = YES;
    [index addNode:node forKey:@"name" andValue:@"mob" withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"should add without errors");
        waiting = NO;
    }];
    while (waiting) {}

    waiting = YES;
    [index deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"should delete without errors");
        waiting = NO;
    }];
    while (waiting) {}
}

- (void)testGetAllNodeIndexes {
    NEONodeIndexPromise *index1 = [graph createNodeIndexWithName:@"nodeIndex1" andConfig:nil];
    NEONodeIndexPromise *index2 = [graph createNodeIndexWithName:@"nodeIndex2" andConfig:nil];
    NEONodeIndexPromise *index3 = [graph createNodeIndexWithName:@"nodeIndex3" andConfig:nil];

    [NEOPromise waitForPromises:index1, index2, index3, nil];
    __block BOOL waiting = YES;
    [graph getAllNodeIndexesWithHandler:^(NSArray *indexes, NEOError *error) {
        STAssertNil(error, @"no errors");
        STAssertTrue(indexes.count == 3, @"check for number");
        NSLog(@"Indexes: %@", indexes);
        waiting = NO;
    }];
    while (waiting) {}

}

- (void)testRemoveNodesFromIndex {
    NEONodeIndexPromise *index1 = [graph createNodeIndexWithName:@"nodeIndex1" andConfig:nil];
    NEONodePromise *node = [graph createNodeWithData:nil];

    __block int waiting = 2;

    [index1 addNode:node forKey:@"foo" andValue:@"bar" withResultHandler:^(NEOError *e) {
        STAssertNil(e, @"should roduce no errors");
        waiting--;
    }];

    [index1 addNode:node forKey:@"foo" andValue:@"bar2" withResultHandler:^(NEOError *e) {
        STAssertNil(e, @"should roduce no errors");
        waiting--;
    }];

    while (waiting) {}

    waiting = 1;
    [graph queryCypher:@"start n = node:nodeIndex1(foo=\"bar\") return n" withParameters:nil andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertTrue(result.count == 1, @"should return one node as result : %@", result);
        waiting += result.count;
        for (NSDictionary *node in result) {
            [index1 removeNode:[node objectForKey:@"n"] forKey:nil andValue:nil withResultHandler:^(NEOError *error) {
                STAssertNil(error, @"should produce no error, %@", error);
                waiting--;
            }];
        }
        waiting--;
    }];

    while (waiting) {}

    waiting = 1;

    [index1 findNodesByExactMatchForKey:@"foo" andValue:@"bar2" withResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNil(error, @"Should not return with error : %@", error);
        waiting += result.count;
        for (id <NEONode> node in result) {
            [index1 removeNode:node forKey:@"foo" andValue:@"bar2" withResultHandler:^(NEOError *error) {
                STAssertNil(error, @"should produce no error, %@", error);
                waiting--;
            }];
        }
        waiting--;
    }];

    while (waiting) {}
}

- (void)testRelationshipIndex {
    NEORelationshipIndexPromise *promise = [graph createRelationshipIndexWithName:@"myIndex" andConfig:nil];
    [promise wait];
    STAssertEqualObjects(promise.indexName, @"myIndex", @"name should be right");
    NSLog(@"%@", promise);

//  TODO: Report the bug to neo4j
//    NEORelationshipIndexPromise * promise1 = [graph getRelationshipIndexWithName:@"myIndex"];
//    [promise1 waitForIndexWithHandler:^(id<NEORelationshipIndex> value, NEOError *error) {
//        STAssertNil(error,@"should delete without errors, %@", error);
//        STAssertEqualObjects(value.indexName, @"myIndex",@"name should be right");
//    }];


    __block BOOL waiting = YES;
    [promise deleteWithResultHandler:^(NEOError *error) {
        STAssertNil(error, @"should delete without errors, %@", error);
        waiting = NO;
    }];
    while (waiting) {}

    NEORelationshipIndexPromise *promise2 = [graph getRelationshipIndexWithName:@"myIndex"];
    [promise2 wait];
    NSLog(@"%@", promise2.error);
    STAssertNotNil(promise2.error, @"myIndex is deleted");
}

- (void)testGetAllRelationshipIndexes {
    NEORelationshipIndexPromise *index1 = [graph createRelationshipIndexWithName:@"relIndex1" andConfig:nil];
    NEORelationshipIndexPromise *index2 = [graph createRelationshipIndexWithName:@"relIndex2" andConfig:nil];
    NEORelationshipIndexPromise *index3 = [graph createRelationshipIndexWithName:@"relIndex3" andConfig:nil];

    [NEOPromise waitForPromises:index1, index2, index3, nil];
    __block BOOL waiting = YES;
    [graph getAllRelationshipIndexesWithHandler:^(NSArray *indexes, NEOError *error) {
        STAssertNil(error, @"no errors");
        STAssertTrue(indexes.count == 3, @"check for number, %i", indexes.count);
        NSLog(@"Indexes: %@", indexes);
        waiting = NO;
    }];
    while (waiting) {}

}

- (void)testAddFindAndDeleteRelationshipForIndex {
    NEORelationshipIndexPromise *index1 = [graph createRelationshipIndexWithName:@"relIndex1" andConfig:nil];
    NEONodePromise *node = [graph createNodeWithData:nil];
    NEORelationshipPromise *const rel = [node createRelationshipOfType:@"knows" toNode:node andData:nil];

    __block int waiting = 1;
    [index1 addRelationship:rel forKey:@"foo" andValue:@"bar" withResultHandler:^(NEOError *error) {
        STAssertNil(error, @"no errors");
        waiting--;
    }];
    while (waiting) {}

    waiting = 1;
    
    [index1 findRelationshipsByExactMatchForKey:@"foo" andValue:@"bar" withResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNil(error, @"no errors");
        STAssertTrue(result.count > 0, @"should return nodes as result : %@", result);
        waiting += result.count;
        for (id<NEORelationship> rel in result) {
            [index1 removeRelationship:rel forKey:@"foo" andValue:@"bar" withResultHandler:^(NEOError *error) {
                STAssertNil(error, @"should produce no error, %@", error);
                waiting--;
            }]; 
        }
        waiting --;
    }];
    
    while (waiting) {}
    
    waiting = 1;
    [graph queryCypher:@"start n = relationship:relIndex1(foo=\"bar\") return n" withParameters:nil andTypedResultHandler:^(NSArray *result, NEOError *error) {
        STAssertNil(error, @"should produce no error, %@", error);
        STAssertTrue(result.count == 0, @"should return no nodes as result : %@", result);
        
        waiting--;
    }];
    while (waiting) {}
}

@end
