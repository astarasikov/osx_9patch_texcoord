#ifndef __OPENGL_SHADERS__H__
#define __OPENGL_SHADERS__H__

#import "common.h"

#define QUOTE(A) #A

const char * const FRAG = "#version 150 core\n" QUOTE(
	in vec3 vert_color;
	in vec2 vert_texcoord;
	out vec4 out_color;
	uniform sampler2D texture_Y;
	uniform vec4 insets;
	uniform vec2 texInSize;
	uniform vec2 texOutSize;

	void main(void) {
		float scale = texInSize.x / texOutSize.x;
		float sx = vert_texcoord.x * texOutSize.x;
		float sy = vert_texcoord.y * texOutSize.y;

		vec4 bounds = vec4(insets.x,
			texOutSize.x - texInSize.x + insets.y,
			insets.z,
			texOutSize.y - texInSize.y + insets.w);

		vec2 len = vec2(bounds.y - bounds.x, bounds.z - bounds.w);

		float niX = texInSize.x - texOutSize.x + sx;
		float niY = texInSize.y - texOutSize.y + sy;

		if ((sx > bounds.x && sx < bounds.y)
			|| (sy > bounds.z && sy < bounds.w))
		{
			out_color = texture(texture_Y, vert_texcoord);
		}
		else if (sx > bounds.y && sy > bounds.w) {
			vec2 coord = vec2(niX / texOutSize.x, niY / texOutSize.y);
			out_color = texture(texture_Y, coord);
		}
		else {
			out_color = vec4(0, 1, 0, 1);
		}
	}
);

const char * const VERT = "#version 150 core\n" QUOTE(
	in vec4 position;
	in vec3 color;
	in vec2 texcoord;
	out vec3 vert_color;
	out vec2 vert_texcoord;

	void main(void) {
		gl_Position = position;
		vert_color = color;
		vert_texcoord = texcoord;
	}
);

#undef QUOTE

static inline void oglShaderLog(int sid) {
	GLint logLen;
	GLsizei realLen;

	glGetShaderiv(sid, GL_INFO_LOG_LENGTH, &logLen);
	if (!logLen) {
		return;
	}
	char* log = (char*)malloc(logLen);
	if (!log) {
		NSLog(@"Failed to allocate memory for the shader log");
		return;
	}
	glGetShaderInfoLog(sid, logLen, &realLen, log);
	NSLog(@"shader %d log %s", sid, log);
	free(log);
}

#endif //__OPENGL_SHADERS__H__
