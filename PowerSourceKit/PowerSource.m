/*************************************************************************************************************
 The MIT License
 
 Copyright (c) 2014-2020 David Dubbeldam, Sofia Calero, Thijs J.H. Vlugt.
 
 D.Dubbeldam@uva.nl      http://www.uva.nl/profiel/d/u/d.dubbeldam/d.dubbeldam.html
 S.Calero@tue.nl         https://www.tue.nl/en/research/researchers/sofia-calero/
 t.j.h.vlugt@tudelft.nl  http://homepage.tudelft.nl/v9k6y
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 *************************************************************************************************************/

#import <Foundation/Foundation.h>
#import <IOKit/ps/IOPowerSources.h>
#include <IOKit/pwr_mgt/IOPMLib.h>
#import <notify.h>
#import "PowerSource.h"

@implementation PowerSource

@synthesize powerSourceType;

- (id) init
{
  if ((self = [super init]) != nil)
  {
    int outtoken;
    notify_register_dispatch(kIOPSTimeRemainingNotificationKey, &outtoken, dispatch_get_main_queue(), ^(int token) {
      [self checkPowerConnection];
    });
  }
  
  CFTimeInterval timeRemaining = IOPSGetTimeRemainingEstimate();
  
  if (timeRemaining == kIOPSTimeRemainingUnlimited)
  {
    self.powerSourceType = unlimited;
  }
  else
  {
    self.powerSourceType = limited;
  }
  
  return self;
}

+ (PowerSource *)shared
{
  static PowerSource *shared = nil;
  @synchronized(self) {
    if (shared == nil)
      shared = [[self alloc] init];
  }
  return shared;
}

- (void) checkPowerConnection
{
  CFTimeInterval timeRemaining = IOPSGetTimeRemainingEstimate();
  
  if (timeRemaining == kIOPSTimeRemainingUnlimited)
  {
    self.powerSourceType = unlimited;
    
  }
  else
  {
    self.powerSourceType = limited;
  }
  [[NSNotificationCenter defaultCenter] postNotificationName:PowerSourceDidChange object:self];
}

@end
