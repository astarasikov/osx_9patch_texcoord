#ifndef __FFMPEG_VIEW__H__
#define __FFMPEG_VIEW__H__

#import "opengl_view.h"

@interface InsetView : MyOpenGLViewBase
-(void)renderForTime:(CVTimeStamp)time;
-(void)setTexture:(char*)data andWidth:(unsigned)width andHeight:(unsigned)height;
@end

#endif //__FFMPEG_VIEW__H__
