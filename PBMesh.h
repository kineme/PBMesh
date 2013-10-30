#import "QCPatch.h"
#import "QCOpenGLContext.h"

#import "QCStringPort.h"
#import "QCNumberPort.h"
#import "QCIndexPort.h"
#import "QCBooleanPort.h"
#import "QCOpenGLPort_Image.h"

typedef struct
{
	unsigned int	width;
	unsigned int	height;
	float			*x;	// width * height entries long
	float			*y;	// ...
	float			*u;	// ...
	float			*v;	// ...
	float			*i;	// ...
} PBMeshData;

@interface PBMesh : QCPatch
{
	QCStringPort		*inputFile;
	QCIndexPort			*inputTextureControl;
	
	QCNumberPort		*inputXPos;
	QCNumberPort		*inputYPos;
	QCNumberPort		*inputZPos;
	
	QCNumberPort		*inputWidth;
	QCNumberPort		*inputHeight;
	
	QCNumberPort		*inputDeltaU;
	QCNumberPort		*inputDeltaV;
	QCOpenGLPort_Image	*inputImage;
	
	PBMeshData			*currentMesh;
}

- (id)initWithIdentifier:(id)fp8;

- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments;
@end