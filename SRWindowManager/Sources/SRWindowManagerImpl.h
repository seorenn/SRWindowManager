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

void SRWindowRequestAccessibility();

NSArray<NSDictionary<NSString *, id> *> * _Nullable SRWindowGetInfoList();
NSImage * _Nullable SRWindowCaptureScreen(CGWindowID windowID, NSRect bounds);
CFArrayRef _Nonnull SRWindowCreateWindowDescriptionInput(CGWindowID windowID);
CFDictionaryRef _Nullable SRWindowCreateWindowDescription(CGWindowID windowID);
NSString * _Nonnull SRWindowGetWindowName(CGWindowID windowID);
NSString * _Nonnull SRWindowGetWindowOwnerName(CGWindowID windowID);

#pragma mark - Accessibility Wrappers

CGWindowID SRWindowGetID(AXUIElementRef _Nonnull windowElement);
CFArrayRef _Nullable SRWindowCopyApplicationWindows(AXUIElementRef _Nonnull applicationElement);
AXUIElementRef _Nullable SRWindowCopyWindowElementFromArray(CFArrayRef _Nonnull theArray, int index);
AXUIElementRef _Nullable SRWindowGetFrontmostWindowElement();
CGRect SRWindowGetFrameOfWindowElement(AXUIElementRef _Nonnull windowElement);
//NSString * _Nullable SRWindowGetTitleOfWindowElement(AXUIElementRef _Nonnull windowElement);
BOOL SRWindowMoveWindowElement(AXUIElementRef _Nonnull windowElement, CGRect frame);

#pragma mark - Handling Mouse

void SRMousePostEvent(CGMouseButton button, CGEventType type, const CGPoint point);

//@class SRWindowManagerImpl;
//
//@protocol SRWindowManagerImplDelegate /* <NSObject>*/
//@optional
//- (void)windowManagerImpl:(SRWindowManagerImpl *)windowManagerImpl detectWindowActivating:(NSRunningApplication *)runningApplication;
//@end
//
//@interface SRWindowManagerImpl : NSObject
//
//@property (nonatomic, readonly) BOOL detecting;
//@property (nonatomic, strong) id<SRWindowManagerImplDelegate> delegate;
//
//- (void)startDetect;
//- (void)stopDetect;
//
//- (NSArray *)windows;
//- (NSArray *)windowInfoList;
//
//@end
