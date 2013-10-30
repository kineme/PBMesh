#import <OpenGL/CGLMacro.h>
#import <OpenGL/OpenGL.h>
#import "PBMesh.h"

/* Adapted from pbourke's mesh loading code.
In this version, we don't track the mesh bounds, we don't use 2D arrays, and
we dump to NSLog instead of fprintf.
*/
static PBMeshData *loadMesh(NSString *filename)
{
	PBMeshData *mesh;
	int j;
	int meshtype;
	double x,y,u,v,br;
	FILE *fptr;

	// Attempt to open the file
	if ((fptr = fopen([filename cStringUsingEncoding: NSASCIIStringEncoding],"r")) == NULL)
	{
		NSLog(@"PBMesh: failed to open file [%@]",filename);
		return NULL;
	}

	// Get the mesh type
	if (fscanf(fptr,"%d",&meshtype) != 1)
	{
		fclose(fptr);
		return NULL;
	}
	if (meshtype < 0 || meshtype > 5)
	{
		NSLog(@"PBMesh: Failed to get a recognised map type (%d)\n",meshtype);
		fclose(fptr);
		return NULL;
	}
	mesh = (PBMeshData*)malloc(sizeof(PBMeshData));
	// Get the dimensions
	if (fscanf(fptr,"%d %d",&mesh->width,&mesh->height) != 2)
	{
		NSLog(@"PBMesh: Failed to read the mesh dimensions\n");
		free(mesh);
		fclose(fptr);
		return(FALSE);
	}
	if (mesh->width < 4 || mesh->height < 4 ||
		mesh->width > 100000 || mesh->height > 100000)
	{
		NSLog(@"PBMesh: Didn't read acceptable mesh resolution (%d,%d)\n",
			mesh->width, mesh->height);
		free(mesh);
		fclose(fptr);
		return(FALSE);
	}

	// Create new mesh
	mesh->x = (float*)malloc(sizeof(float)*mesh->width*mesh->height);
	mesh->y = (float*)malloc(sizeof(float)*mesh->width*mesh->height);
	mesh->u = (float*)malloc(sizeof(float)*mesh->width*mesh->height);
	mesh->v = (float*)malloc(sizeof(float)*mesh->width*mesh->height);
	mesh->i = (float*)malloc(sizeof(float)*mesh->width*mesh->height);

	// Read the values
	for(j = 0; j < mesh->width * mesh->height; ++j)
	{
		if (fscanf(fptr,"%lf %lf %lf %lf %lf",&x,&y,&u,&v,&br) != 5)
		{
			// autogenerate points on error -- hopefully this doesn't happen.
			x = 2 * (j % mesh->width) / (double)(mesh->width  - 1) - 1;
			y = 2 * (j / mesh->width) / (double)(mesh->height - 1) - 1;
			u = (j % mesh->width) / (double)(mesh->width  - 1);
			v = (j / mesh->width) / (double)(mesh->height - 1);
			br = 1;
		}
		mesh->x[j] = x;
		mesh->y[j] = y;
		mesh->u[j] = u;
		mesh->v[j] = v;
		mesh->i[j] = br;
	}

	fclose(fptr);
	return mesh;
}

@implementation PBMesh : QCPatch

+ (int)executionModeWithIdentifier:(id)fp8
{
	return 1;
}

+ (BOOL)allowsSubpatchesWithIdentifier:(id)fp8
{
	return NO;
}

+ (int)timeModeWithIdentifier:(id)fp8
{
	return 1;
}

- (id)initWithIdentifier:(id)fp8
{
	if(self=[super initWithIdentifier:fp8])
	{
		[inputTextureControl setMaxIndexValue: 1];
		[inputWidth setDoubleValue: 1.0];
		[inputHeight setDoubleValue: 1.0];
	}

	return self;
}

- (void)disable:(QCOpenGLContext *)context
{
	if(currentMesh)
	{
		free(currentMesh->x);
		free(currentMesh->y);
		free(currentMesh->u);
		free(currentMesh->v);
		free(currentMesh->i);
		free(currentMesh);
	}
	currentMesh = NULL;
}


- (BOOL)execute:(QCOpenGLContext *)context time:(double)time arguments:(NSDictionary *)arguments
{
	if([inputFile wasUpdated])
	{
		if(currentMesh)
		{
			free(currentMesh->x);
			free(currentMesh->y);
			free(currentMesh->u);
			free(currentMesh->v);
			free(currentMesh->i);
			free(currentMesh);
		}
		NSString *path = KIExpandPath(self,[inputFile stringValue]);
		currentMesh = loadMesh(path);
	}
		
	if(currentMesh)
	{
		GLint	oldSMode, oldTMode;
		//NSLog(@"Rendering... %ix%i",currentMesh->width, currentMesh->height);
		unsigned int x, y, offset, width = currentMesh->width;
		CGLContextObj cgl_ctx = [context CGLContextObj];
		
		[inputImage setOnOpenGLContext: context unit:GL_TEXTURE0];

		// only works if images are passed through an Image Texturing Properties patch, and set to 2D.
		glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_WRAP_S,&oldSMode);
		glGetTexParameteriv(GL_TEXTURE_2D,GL_TEXTURE_WRAP_T,&oldTMode);
		if([inputTextureControl indexValue] == 0)	// wrap mode
		{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
		}
		else	// clamp
		{
			//do nothing for now;  QC's GL context is configured to clamp automatically
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
		}
		
		glNormal3f(0., 0., -1.);
		//glBegin(GL_QUADS);
		float du = [inputDeltaU doubleValue], dv = [inputDeltaV doubleValue];
		float xp = [inputXPos doubleValue], yp = [inputYPos doubleValue], zp = [inputZPos doubleValue];
		float w = [inputWidth doubleValue], h = [inputHeight doubleValue];
		// XXX This isn't particularly elegant...
		for(y = 0; y < currentMesh->height - 1; ++y)
		{
			offset = y * width;
			glBegin(GL_QUAD_STRIP);	// GL_QUAD_STRIP is faster than GL_TRIANGLE_STRIP here by about 10%... weird
			for(x = 0; x < width - 0; ++x)
			{
				glColor3f(currentMesh->i[offset+width],currentMesh->i[offset+width],currentMesh->i[offset+width]);
				glTexCoord2f(currentMesh->u[offset+width]+du,currentMesh->v[offset+width]+dv);
				glVertex3f(currentMesh->x[offset+width]*w+xp,currentMesh->y[offset+width]*h+yp,zp);

				// GL_QUADS version is the following four blocks, minus the one above.  2x as much
				// function call overhead (still >60fps for all sample meshes though)
				glColor3f(currentMesh->i[offset],currentMesh->i[offset],currentMesh->i[offset]);
				glTexCoord2f(currentMesh->u[offset]+du,currentMesh->v[offset]+dv);
				glVertex3f(currentMesh->x[offset]*w+xp,currentMesh->y[offset]*h+yp,zp);
				
				//glColor3f(currentMesh->i[offset+1],currentMesh->i[offset+1],currentMesh->i[offset+1]);
				//glTexCoord2f(currentMesh->u[offset+1]+du,currentMesh->v[offset+1]+dv);
				//glVertex2f(currentMesh->x[offset+1],currentMesh->y[offset+1]);
				
				//glColor3f(currentMesh->i[offset+1+width],currentMesh->i[offset+1+width],currentMesh->i[offset+1+width]);
				//glTexCoord2f(currentMesh->u[offset+1+width]+du,currentMesh->v[offset+1+width]+dv);
				//glVertex2f(currentMesh->x[offset+1+width],currentMesh->y[offset+1+width]);
				
				//glColor3f(currentMesh->i[offset+width],currentMesh->i[offset+width],currentMesh->i[offset+width]);
				//glTexCoord2f(currentMesh->u[offset+width]+du,currentMesh->v[offset+width]+dv);
				//glVertex2f(currentMesh->x[offset+width],currentMesh->y[offset+width]);
				offset++;
			}
			glEnd();
		}
		//glEnd();
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, oldSMode);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, oldTMode);

		[inputImage unsetOnOpenGLContext: context];
	}
	
	return YES;
}

@end
