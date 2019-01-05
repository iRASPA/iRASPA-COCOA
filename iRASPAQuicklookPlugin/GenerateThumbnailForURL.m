#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize);
void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail);

/* -----------------------------------------------------------------------------
    Generate a thumbnail for file

   This function's job is to create thumbnail for designated file as fast as possible
   ----------------------------------------------------------------------------- */

OSStatus GenerateThumbnailForURL(void *thisInterface, QLThumbnailRequestRef thumbnail, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options, CGSize maxSize)
{
    // To complete your generator please implement the function GenerateThumbnailForURL in GenerateThumbnailForURL.c
  
  /* Based on example code from quicklook-dev mailing list */
  // NSSize previewSize = NSSizeFromCGSize(maxSize);

  
  NSImage* someImage = [NSImage imageNamed: NSImageNameGoLeftTemplate];
  // create the image somehow, load from file, draw into it...
  CGImageSourceRef source;
  
  source = CGImageSourceCreateWithData((CFDataRef)[someImage TIFFRepresentation], NULL);
  
  CGImageRef image =  CGImageSourceCreateImageAtIndex(source, 0, NULL);
  
  
  CGSize size = CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
  
  CGContextRef context = QLThumbnailRequestCreateContext(thumbnail, size, false, NULL);

  NSLog(@"TEST");
  

  
  if(context != NULL)
  {
    
    
    CGContextDrawImage(context, CGRectMake(0, 0, size.width, size.height), image);
    QLThumbnailRequestFlushContext(thumbnail, context);
    
    CFRelease(context);
  }
  
  CGImageRelease(image);
  CFRelease(source);
  
  
  
  return noErr;
}

void CancelThumbnailGeneration(void *thisInterface, QLThumbnailRequestRef thumbnail)
{
    // Implement only if supported
}
