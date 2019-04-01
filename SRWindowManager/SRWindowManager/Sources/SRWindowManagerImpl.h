//
//  SRWindowManagerImpl.h
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@import CoreGraphics;

NSArray<NSDictionary<NSString *, id> *> * _Nullable SRWindowGetInfoList(void);
NSImage * _Nullable SRWindowCaptureScreen(CGWindowID windowID, NSRect bounds);
CFArrayRef _Nonnull SRWindowCreateWindowDescriptionInput(CGWindowID windowID);
NSArray<NSDictionary<NSString *, id> *> * _Nullable SRWindowGetDescriptions(CGWindowID windowID);
CFDictionaryRef _Nullable SRWindowCreateWindowDescription(CGWindowID windowID);
//NSString * _Nonnull SRWindowGetWindowName(CGWindowID windowID);
//NSString * _Nonnull SRWindowGetWindowOwnerName(CGWindowID windowID);
pid_t SRWindowGetWindowOwnerPID(CGWindowID windowID);

#pragma mark - Accessibility Wrappers

CGWindowID SRWindowGetID(AXUIElementRef _Nonnull windowElement);
CFArrayRef _Nullable SRWindowCopyApplicationWindows(AXUIElementRef _Nonnull applicationElement);
AXUIElementRef _Nullable SRWindowCopyWindowElementFromArray(CFArrayRef _Nonnull theArray, int index);
AXUIElementRef _Nullable SRWindowGetFrontmostWindowElement(void);
//CGRect SRWindowGetFrameOfWindowElement(AXUIElementRef _Nonnull windowElement);
BOOL SRWindowMoveWindowElement(AXUIElementRef _Nonnull windowElement, CGRect frame);

#pragma mark - Handling Mouse

void SRMousePostEvent(CGMouseButton button, CGEventType type, const CGPoint point);

#pragma mark - Window Activation Detector

@interface SRWindowActivationDetector : NSObject
@property (nonatomic, strong, nullable) void (^handler)(AXUIElementRef _Nonnull element, NSRunningApplication * _Nonnull runningApplication);
- (void)startWithRunningApplication:(NSRunningApplication * _Nonnull)runningApplication;
- (void)stop;
@end

