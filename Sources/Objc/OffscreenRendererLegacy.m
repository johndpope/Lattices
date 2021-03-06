//
//  OffscreenRenderer.m
//  CIFCommand
//
//  Created by Jun Narumi on 2016/05/26.
//  Copyright © 2016年 zenithgear. All rights reserved.
//

#import "OffscreenRendererLegacy.h"
#import <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#include <OpenGL/glext.h>

static const size_t bytesPerPixel = 4;
static const size_t bitsPerPixel = 32;
static const size_t bitsPerComponent = 8;

static void rgbReleaseData( void *info, const void *data, size_t size )
{
    free((char *)data);
}

static CGDataProviderRef createRGBDataProvider( const char *bytes, size_t width, size_t height )
{
    CGDataProviderRef dataProvider = NULL;
    size_t imageDataSize = width*height*bytesPerPixel;
    unsigned char *dataP = (unsigned char *)malloc(imageDataSize);
    if(dataP == NULL){
        return NULL;
    }
#if 0
    p = memcpy(dataP, bytes, imageDataSize);
#else
    for ( size_t i = 0; i < height; ++i) {
        memcpy( &dataP[i * width * bytesPerPixel],
               &bytes[(height-i-1) * width * bytesPerPixel],
               width * bytesPerPixel);
    }
#endif
    dataProvider = CGDataProviderCreateWithData(NULL, dataP,
                                                imageDataSize, rgbReleaseData);
    return dataProvider;
}

@interface OffscreenRendererLegacy()
@property(strong) NSImage *image;
@end


@implementation OffscreenRendererLegacy
{
    CGLContextObj ctx;
    CGLPixelFormatObj pix;
    GLuint framebuffer, renderbuffer, depthbuffer;
    GLuint pbo_id;
    GLuint width;
    GLuint height;
}

- (instancetype)init
{
    self = [super init];
    if (self) {

    }
    return self;
}

- (void)setupWithWidth:(GLuint)width_ height:(GLuint)height_
{
    width = width_;
    height = height_;

    GLint npix;

    CGLPixelFormatAttribute attribs[] = {
        kCGLPFAAllowOfflineRenderers,
        kCGLPFAColorSize, 32,
        kCGLPFADepthSize, 24,
        kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_Legacy,
        0
    };

    CGLChoosePixelFormat(attribs, &pix, &npix);
    CGLCreateContext(pix, NULL, &ctx);
    CGLSetCurrentContext(ctx);

//    printf("%s %s\n", glGetString(GL_RENDERER), glGetString(GL_VERSION));

    //    GLuint framebuffer, renderbuffer, depthbuffer;
    GLenum status;
    // Set the width and height appropriately for your image
    //Set up a FBO with one renderbuffer attachment[
    assert(glGetError()==0);
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glGenRenderbuffers(1, &depthbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24, width, height);
    glGenRenderbuffers(1, &renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8, width, height);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthbuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);

    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE)
    {   // Handle errors
        assert(0);
    }
    assert(glGetError()==0);

    glGenBuffers(1, &pbo_id);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, pbo_id);
    glBufferData(GL_PIXEL_PACK_BUFFER, width*height*4, 0, GL_DYNAMIC_READ);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
}

- (void)begin
{
    CGLSetCurrentContext(ctx);
//    CGLClearDrawable(ctx);
    glViewport(0, 0, width, height);
}

- (id)imageWithSize:(NSSize)size
{
    [self setupWithWidth:size.width height:size.height];
    [self begin];

    // Draw Begin
#if 1
    glClearColor( 1,1,1,1 );
    glClearDepth( 1 );
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    SCNRenderer *renderer = [SCNRenderer rendererWithContext:ctx options:nil];
    renderer.autoenablesDefaultLighting = YES;
//    renderer.jitteringEnabled = YES;
//    self.scene.background.contents = [NSColor whiteColor];
    [SCNTransaction begin];
    [SCNTransaction setAnimationDuration:0.0];
    renderer.scene = self.scene;
    if ( self.pointOfView == nil )
    {
        SCNNode *baseNode = [SCNNode node];
        SCNNode *cameraNode = [SCNNode node];
        cameraNode.camera = [SCNCamera camera];
        SCNVector3 center;
        CGFloat radius;
        [self.scene.rootNode getBoundingSphereCenter:&center radius:&radius];
        baseNode.position = center;
        double angle = -45 * M_PI / 180.0;
        baseNode.rotation = SCNVector4Make(sin(angle), cos(angle), 0, M_PI_4);
        cameraNode.position = SCNVector3Make( 0, 0, radius * 2 );
        [baseNode addChildNode:cameraNode];
        [renderer.scene.rootNode addChildNode:baseNode];
        renderer.pointOfView = cameraNode;
    }
    [SCNTransaction commit];
    [SCNTransaction flush];
    [renderer renderAtTime:5];
#else
    glClearColor(0,0,0,1);
    glClearDepth(1);
    glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT );
    glBegin(GL_TRIANGLES);
    glColor3f(1, 0, 0);
    glVertex2f(0, 1);
    glColor3f(0, 1, 0);
    glVertex2f(-1, -1);
    glColor3f(0, 0, 1);
    glVertex2f(1, -1);
    glEnd();
#endif
    // Draw End

    [self end];
    [self teardown];
    return self.image;
}

- (void)end
{
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glReadBuffer(GL_COLOR_ATTACHMENT0);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, pbo_id);
    glReadPixels(0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, 0);
    GLubyte *ptr = glMapBufferARB(GL_PIXEL_PACK_BUFFER_ARB, GL_READ_ONLY_ARB);
    CGDataProviderRef provider = createRGBDataProvider( (const char *)ptr, width, height );
    glUnmapBuffer(GL_PIXEL_PACK_BUFFER);
    glBindBuffer(GL_PIXEL_PACK_BUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    // Delete the renderbuffer attachment
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef image = CGImageCreate(width,
                                     height,
                                     bitsPerComponent,
                                     bitsPerPixel,
                                     bytesPerPixel*width,
                                     colorSpace,
                                     kCGBitmapByteOrderDefault,
                                     provider,
                                     NULL,
                                     NO,
                                     kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    NSImage *result = [[NSImage alloc] initWithCGImage:image
                                                  size:NSMakeSize(width, height)];
    CGImageRelease(image);

    self.image = result;
}

- (void)teardown
{
    glDeleteBuffers(1, &pbo_id);
    glDeleteRenderbuffers(1, &renderbuffer);
    glDeleteRenderbuffers(1, &depthbuffer);
    glDeleteFramebuffers(1, &framebuffer);
}

@end












