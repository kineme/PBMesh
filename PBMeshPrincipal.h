#import "QCProtocols.h"
#import "GFNodeManager.h"

@interface PBMeshPlugin : NSObject <GFPlugInRegistration>
+ (void)registerNodesWithManager:(GFNodeManager*)manager;
@end
