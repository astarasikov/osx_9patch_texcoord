#import "inset_view.h"
#import "inset_gl_controller.h"
#import "opengl_shaders.h"
#import "opengl_utils.h"
#import "opengl_view.h"
#import <math.h>

/* we're now using a hardcoded texture */
enum {
	TEX_CHANS = 4,
	TEX_W = 256,
	TEX_H = 256,

	TEX_IN_W = TEX_W,
	TEX_IN_H = TEX_H,
	TEX_OUT_W = 512,
	TEX_OUT_H = 256,
};

static struct RectInset {
	unsigned left;
	unsigned right;
	unsigned top;
	unsigned bottom;
} TexInset = {
	50, TEX_W - 128, 50, TEX_H - 128,
};

#define QuadSide 0.7f
#define TEX_COUNT 1

static GLfloat QuadData[] = {
	//vertex coordinates
	-QuadSide, -QuadSide, 0.0f,
	QuadSide, -QuadSide, 0.0f,
	QuadSide, QuadSide, 0.0f,
	-QuadSide, QuadSide, 0.0f,

	//colors
	1, 0, 0,
	0, 1, 0,
	0, 0, 1,
	1, 1, 1,

	//texture coordinates
	0, 0,
	1, 0,
	1, 1,
	0, 1,
};

static GLuint QuadIndices[] = {
	0, 1, 2,
	0, 2, 3,
};

static const size_t VertexStride = 3;
static const size_t ColorStride = 3;
static const size_t TexCoordStride = 2;

static const size_t NumVertices = 4;

static const size_t CoordOffset = 0;
static const size_t ColorOffset = CoordOffset + VertexStride * NumVertices;
static const size_t TexCoordOffset = ColorOffset + ColorStride * NumVertices;

static const size_t NumIndices = sizeof(QuadIndices) / sizeof(QuadIndices[0]);

@implementation InsetView
{
	GLuint _programId;
	GLuint _vao;
	GLuint _vbo;
	GLuint _vbo_idx;

	GLuint _positionAttr;
	GLuint _colorAttr;
	GLuint _texCoordAttr;
	GLuint _insetUniform;
	GLuint _texInSizeUniform;
	GLuint _texOutSizeUniform;

	GLuint _textures[TEX_COUNT];
}

-(void)initializeContext
{
	static int init = 0;
	if (init) {
		return;
	}

	ogl(glGenVertexArrays(1, &_vao));
	ogl(glBindVertexArray(_vao));
	ogl(glGenBuffers(1, &_vbo));
	ogl(glGenBuffers(1, &_vbo_idx));
	
	ogl(_programId = glCreateProgram());

	const char * const vsrc = VERT;
	const char * const fsrc = FRAG;

	GLuint vert, frag;
	ogl(vert = glCreateShader(GL_VERTEX_SHADER));
	ogl(frag = glCreateShader(GL_FRAGMENT_SHADER));

	ogl(glShaderSource(vert, 1, &vsrc, NULL));
	ogl(glCompileShader(vert));
	oglShaderLog(vert);

	ogl(glShaderSource(frag, 1, &fsrc, NULL));
	ogl(glCompileShader(frag));
	oglShaderLog(frag);

	ogl(glAttachShader(_programId, frag));
	ogl(glAttachShader(_programId, vert));

	ogl(glBindAttribLocation(_programId, 0, "position"));
	ogl(glBindAttribLocation(_programId, 1, "color"));
	ogl(glBindAttribLocation(_programId, 2, "texcoord"));
	ogl(glBindFragDataLocation(_programId, 0, "out_color"));

	ogl(glLinkProgram(_programId));
	ogl(oglProgramLog(_programId));

	ogl(glGenTextures(3, _textures));
	
	glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	ogl(glEnable(GL_DEPTH_TEST));
	ogl(glEnable(GL_BLEND));
    ogl(glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA));
	
	ogl(_positionAttr = glGetAttribLocation(_programId, "position"));
	ogl(_colorAttr = glGetAttribLocation(_programId, "color"));
	ogl(_texCoordAttr = glGetAttribLocation(_programId, "texcoord"));
	ogl(_insetUniform = glGetUniformLocation(_programId, "insets"));
	ogl(_texInSizeUniform = glGetUniformLocation(_programId, "texInSize"));
	ogl(_texOutSizeUniform = glGetUniformLocation(_programId, "texOutSize"));

	//XXX: fix this
	init = 1;
}

-(void)renderQuad
{
	ogl(glUseProgram(_programId));
	
	GLuint texLoc[TEX_COUNT];
	const char * const texNames[TEX_COUNT] = {
		"texture_Y",
	};
	for (size_t i = 0; i < TEX_COUNT; i++) {
		ogl(texLoc[i] = glGetUniformLocation(_programId, texNames[i]));
		ogl(glUniform1i(texLoc[i], i));
	}

	ogl(glUniform4f(_insetUniform, TexInset.left, TexInset.right,
		TexInset.top, TexInset.bottom));
	ogl(glUniform2f(_texInSizeUniform, TEX_IN_W, TEX_IN_H));
	ogl(glUniform2f(_texOutSizeUniform, TEX_OUT_W, TEX_OUT_H));
	ogl(glBindVertexArray(_vao));

	ogl(glBindBuffer(GL_ARRAY_BUFFER, _vbo));
	ogl(glBufferData(GL_ARRAY_BUFFER,
		sizeof(QuadData), QuadData, GL_STATIC_DRAW));

	ogl(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _vbo_idx));
	ogl(glBufferData(GL_ELEMENT_ARRAY_BUFFER,
		sizeof(QuadIndices), QuadIndices, GL_STATIC_DRAW));

	ogl(glVertexAttribPointer(_positionAttr, VertexStride,
		GL_FLOAT, GL_FALSE, 0,
		(GLvoid*)(CoordOffset * sizeof(GLfloat))));
	ogl(glVertexAttribPointer(_colorAttr, ColorStride,
		GL_FLOAT, GL_FALSE, 0,
		(GLvoid*)(ColorOffset * sizeof(GLfloat))));
	ogl(glVertexAttribPointer(_texCoordAttr, TexCoordStride,
		GL_FLOAT, GL_FALSE, 0,
		(GLvoid*)(TexCoordOffset * sizeof(GLfloat))));

	ogl(glEnableVertexAttribArray(_positionAttr));
	ogl(glEnableVertexAttribArray(_colorAttr));
	ogl(glEnableVertexAttribArray(_texCoordAttr));

	ogl(glDrawElements(GL_TRIANGLES, NumIndices, GL_UNSIGNED_INT, 0));

	ogl(glDisableVertexAttribArray(_texCoordAttr));
	ogl(glDisableVertexAttribArray(_colorAttr));
	ogl(glDisableVertexAttribArray(_positionAttr));

	ogl(glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0));
	ogl(glBindBuffer(GL_ARRAY_BUFFER, 0));
	ogl(glBindVertexArray(0));
}

-(void)renderForTime:(CVTimeStamp)time
{
	NSLog(@"Render");
	if ([self lockFocusIfCanDraw] == NO) {
		return;
	}
	CGLContextObj contextObj = [[self openGLContext] CGLContextObj];
	CGLLockContext(contextObj);

	[self initializeContext];
	ogl(glViewport(0, 0, self.frame.size.width, self.frame.size.height));
	ogl(glClearColor(1, 1, 1, 1));
	ogl(glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT));

	[self renderQuad];
	[[self openGLContext] flushBuffer];

	CGLUnlockContext(contextObj);
	[self unlockFocus];
}

-(void)setTexture:(char*)data andWidth:(unsigned)width andHeight:(unsigned)height
{
	if ([self lockFocusIfCanDraw] == NO) {
		return;
	}
	CGLContextObj contextObj = [[self openGLContext] CGLContextObj];
	CGLLockContext(contextObj);

	ogl(glActiveTexture(GL_TEXTURE0));
	ogl(glBindTexture(GL_TEXTURE_2D, _textures[0]));
		
	ogl(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR));
	ogl(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR));
	ogl(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE));
	ogl(glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE));

	ogl(glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,
		width,
		height,
		0, GL_RGBA,
		GL_UNSIGNED_BYTE, data));

	CGLUnlockContext(contextObj);
	[self unlockFocus];
}
@end

static void loadImage(id controller) {
	NSImage *image = [[NSImage alloc] initWithContentsOfFile: @"texture.png"];
	NSBitmapImageRep *repr = [[image representations] objectAtIndex: 0];

	[[controller glView] setTexture: (char*)[repr bitmapData
		]andWidth: (unsigned)[repr pixelsWide]
		andHeight: (unsigned)[repr pixelsHigh]];

	[repr release];
	[image release];
}

int main(int argc, char** argv) {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSApplication *app = [NSApplication sharedApplication];
	GLController *controller = [[GLController alloc] init];
	loadImage(controller);
	[app run];
	[pool release];
	return 0;
}
