#import "PBMeshPrincipal.h"
#import "PBMesh.h"

@implementation PBMeshPlugin
+ (void)registerNodesWithManager:(GFNodeManager*)manager
{
	// each pattern checks to see if it's already registered.  Follow the pattern with additional patches.
	if( [manager isNodeRegisteredWithName: NSStringFromClass([PBMesh class])] == FALSE )
		[manager registerNodeWithClass:[PBMesh class]];
}
@end
