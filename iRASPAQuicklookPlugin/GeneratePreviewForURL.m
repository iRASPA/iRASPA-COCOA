#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#include <OpenGL/OpenGL.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{

  //Create a GL Context
  CGLError cglerr;
  
  CGLPixelFormatAttribute attributes[] = {
    kCGLPFAColorSize, 24,
    kCGLPFAAlphaSize, 8,
    kCGLPFAOpenGLProfile, (CGLPixelFormatAttribute)kCGLOGLPVersion_GL3_Core,
    kCGLPFAAllowOfflineRenderers,
    kCGLPFANoRecovery,
    kCGLPFAAccelerated,
    0
  };
  
  CGLPixelFormatObj format;
  GLint npix;
  cglerr = CGLChoosePixelFormat(attributes, &format, &npix);
  if (cglerr != kCGLNoError) {
    fprintf(stderr, "CGLChoosePixelFormat failed: %s", CGLErrorString(cglerr));
    exit(1);
  }

  CGLContextObj cgl_ctx;
  cglerr = CGLCreateContext(format, NULL, &cgl_ctx);
  if (cglerr != kCGLNoError) {
    fprintf(stderr, "CGLCreateContext failed: %s", CGLErrorString(cglerr));
    exit(1);
  }
  
  
  
  CGLSetCurrentContext(cgl_ctx);
  
  fprintf(stderr,"GOING GREAT!!\n");
  NSLog(@"contentTypeUTI %@", contentTypeUTI);
  
  
  NSImage* someImage = [NSImage imageNamed: NSImageNameGoLeftTemplate];
  // create the image somehow, load from file, draw into it...
  CGImageSourceRef source;
  
  source = CGImageSourceCreateWithData((CFDataRef)[someImage TIFFRepresentation], NULL);
  CGImageRef image =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
  
  CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
  CGContextRef ctxt = QLPreviewRequestCreateContext(preview, size, YES, nil);
  CGContextDrawImage(ctxt, CGRectMake(0, 0, size.width, size.height), image);
  QLPreviewRequestFlushContext(preview, ctxt);
  CGContextRelease(ctxt);

    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
  
  CGImageRelease(image);
  CFRelease(source);
  
    return noErr;
}


void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

