//
//  SRWindowManagerImpl.m
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRWindowManagerImpl.h"
#import <Carbon/Carbon.h>

extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);

NSArray<NSDictionary<NSString *, id> *> * _Nullable SRWindowGetInfoList() {
    CGWindowListOption listOptions;
    listOptions = kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;
    
    CFArrayRef windowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
    if (windowList == NULL) {
        return nil;
    }
    
    NSMutableArray *list = [[NSMutableArray alloc] init];
    
    CFIndex len = CFArrayGetCount(windowList);
    for (int i=0; i < len; i++) {
        NSDictionary *entry = (NSDictionary *)CFArrayGetValueAtIndex(windowList, i);
        
        int sharingState = 0;
        CFNumberRef sharingStateNumber = (__bridge CFNumberRef)([entry objectForKey:(id)kCGWindowSharingState]);
        CFNumberGetValue(sharingStateNumber, kCFNumberIntType, &sharingState);
        
        SInt32 windowID = 0;
        CFNumberRef windowNumber = (__bridge CFNumberRef)([entry objectForKey:(id)kCGWindowNumber]);
        CFNumberGetValue(windowNumber, kCGWindowIDCFNumberType, &windowID);
        
        NSString *name = [entry objectForKey:(id)kCGWindowOwnerName];
        
        CGRect bounds;
        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
        
        int pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
        
        NSDictionary<NSString *, NSObject *> *info = @{ @"name": name,
                                                        @"bounds.origin.x": [NSNumber numberWithFloat:bounds.origin.x],
                                                        @"bounds.origin.y": [NSNumber numberWithFloat:bounds.origin.y],
                                                        @"bounds.size.width": [NSNumber numberWithFloat:bounds.size.width],
                                                        @"bounds.size.height": [NSNumber numberWithFloat:bounds.size.height],
                                                        @"pid": [NSNumber numberWithInt:pid],
                                                        @"windowid": [NSNumber numberWithInt:windowID],
                                                        @"sharingstate": [NSNumber numberWithInt:sharingState] };
        
        [list addObject:info];
    }
    
    CFRelease(windowList);
    
    return list;
}

NSImage * _Nullable SRWindowCaptureScreen(CGWindowID windowID, NSRect bounds) {
    CGImageRef cfimage = NULL;
    
    cfimage = CGWindowListCreateImage(bounds, kCGWindowListOptionAll, windowID, kCGWindowImageDefault);
    if (cfimage == NULL) return nil;
    NSImage *image = [[NSImage alloc] initWithCGImage:cfimage size:bounds.size];
    
    CFRelease(cfimage);
    
    return image;
}

CGWindowID SRWindowGetID(AXUIElementRef _Nonnull windowElement) {
    CGWindowID windowID = 0;
    _AXUIElementGetWindow(windowElement, &windowID);
    
    return windowID;
}

//NSArray<NSDictionary<NSString *, id> *> * _Nullable SRWindowGetApplicationWindows(pid_t pid) {
//    
//}

// Private
AXUIElementRef SRWindowCopyElementAttribute(AXUIElementRef element, CFStringRef attribute) {
    AXUIElementRef resultElement = NULL;
    AXError result = AXUIElementCopyAttributeValue(element, attribute, (CFTypeRef *)&resultElement);
    if (result == kAXErrorSuccess) {
        return resultElement;
    } else {
        return NULL;
    }
}

AXUIElementRef _Nullable SRWindowGetFrontmostWindowElement() {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedAppElement = SRWindowCopyElementAttribute(systemWideElement, kAXFocusedApplicationAttribute);
    AXUIElementRef frontWindowElement = NULL;
    
    if (focusedAppElement) {
        frontWindowElement = SRWindowCopyElementAttribute(focusedAppElement, kAXFocusedWindowAttribute);
        CFRelease(focusedAppElement);
    }
    
    CFRelease(systemWideElement);
    return frontWindowElement;
}

// Private
AXValueRef _Nullable SRWindowCopyElementValue(AXUIElementRef element, CFStringRef attribute, AXValueType type) {
    if (CFGetTypeID(element) != AXUIElementGetTypeID()) return NULL;
    
    CFTypeRef value = NULL;
    AXError result = AXUIElementCopyAttributeValue(element, attribute, (CFTypeRef *)&value);
    if (result == kAXErrorSuccess && AXValueGetType(value) == type) {
        return value;
    } else {
        CFRelease(value);
        return NULL;
    }
}

CGRect SRWindowGetFrameOfWindowElement(AXUIElementRef _Nonnull windowElement) {
    CGRect result = CGRectNull;
    
    CFTypeRef positionObject = SRWindowCopyElementValue(windowElement, kAXPositionAttribute, kAXValueCGPointType);
    CFTypeRef sizeObject = SRWindowCopyElementValue(windowElement, kAXSizeAttribute, kAXValueCGSizeType);
    
    CGPoint position;
    CGSize size;
    int count = 0;
    
    if (positionObject) {
        AXValueGetValue(positionObject, kAXValueCGPointType, (void *)&position);
        CFRelease(positionObject);
        count++;
    }
    
    if (sizeObject) {
        AXValueGetValue(sizeObject, kAXValueCGSizeType, (void *)&size);
        CFRelease(sizeObject);
        count++;
    }
    
    if (count == 2) {
        result = CGRectMake(position.x, position.y, size.width, size.height);
    }
    
    return result;
}

CFArrayRef _Nullable SRWindowCopyApplicationWindows(AXUIElementRef applicationElement) {
    CFArrayRef result = NULL;

    AXError error = AXUIElementCopyAttributeValue(applicationElement, kAXWindowAttribute, (CFTypeRef *)&result);
    
    if (error != kAXErrorSuccess) { return nil; }
    return result;
}

AXUIElementRef _Nullable SRWindowCopyWindowElementFromArray(CFArrayRef _Nonnull theArray, int index) {
    AXUIElementRef result = NULL;
    
    result = (AXUIElementRef)CFArrayGetValueAtIndex(theArray, index);
    return result;
}

// Private
BOOL SRWindowSetElementValue(AXUIElementRef element, AXValueRef value, CFStringRef attribute) {
    AXError result = AXUIElementSetAttributeValue(element, attribute, (CFTypeRef *)value);
    return (result == kAXErrorSuccess);
}

BOOL SRWindowMoveWindowElement(AXUIElementRef _Nonnull windowElement, CGRect frame) {
    AXValueRef positionObject = AXValueCreate(kAXValueCGPointType, (const void *)&frame.origin);
    AXValueRef sizeObject = AXValueCreate(kAXValueCGSizeType, (const void *)&frame.size);
    int count = 0;
    
    // TODO: If not move correctly, attach resize above of belows
    // eg: resize -> move -> resize
    
    if (positionObject) {
        SRWindowSetElementValue(windowElement, positionObject, kAXPositionAttribute);
        CFRelease(positionObject);
        count++;
    }
    
    if (sizeObject) {
        SRWindowSetElementValue(windowElement, sizeObject, kAXSizeAttribute);
        CFRelease(sizeObject);
        count++;
    }
    
    return (count == 2);
}

#pragma mark - Handling Mouse

void SRMousePostEvent(CGMouseButton button, CGEventType type, const CGPoint point) {
    CGEventRef event = CGEventCreateMouseEvent(NULL, type, point, button);
    CGEventSetType(event, type);
    CGEventPost(kCGHIDEventTap, event);
    CFRelease(event);
}

//@implementation SRWindowManagerImpl
//
//@synthesize detecting = _detecting;
//
//- (instancetype)init {
//    self = [super init];
//    if (self) {
//        _detecting = NO;
//        NSNotificationCenter *nc = [[NSWorkspace sharedWorkspace] notificationCenter];
//        [nc addObserver:self
//               selector:@selector(didActivateWindowNotification:)
//                   name:NSWorkspaceDidActivateApplicationNotification
//                 object:nil];
//    }
//    return self;
//}
//
//- (void)dealloc {
//    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
//}
//
//- (void)didActivateWindowNotification:(NSNotification *)notification {
//    if (_detecting == NO || self.delegate == nil) return;
//    
//    NSRunningApplication *app = [notification.userInfo objectForKey:NSWorkspaceApplicationKey];
//    [self.delegate windowManagerImpl:self detectWindowActivating:app];
//}
//
//- (void)startDetect {
//    _detecting = YES;
//}
//
//- (void)stopDetect {
//    _detecting = NO;
//}
//
//- (NSArray *)windows {
//    NSMutableArray *results = [[NSMutableArray alloc] init];
//    CFArrayRef list = CGWindowListCopyWindowInfo(kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID);
//    if (!list) return nil;
//    
//    NSInteger count = CFArrayGetCount(list);
//    for (int i=0; i < count; i++) {
//        CFDictionaryRef info = CFArrayGetValueAtIndex(list, i);
//        if (!info) continue;
//        
//        CFNumberRef pidNumber = CFDictionaryGetValue(info, kCGWindowOwnerPID);
//        pid_t pid;
//        CFNumberGetValue(pidNumber, kCFNumberIntType, &pid);
//        
//        NSRunningApplication *app = [NSRunningApplication runningApplicationWithProcessIdentifier: pid];
//        if (!app) continue;
//        
//        [results addObject:app];
//    }
//    
//    CFRelease(list);
//    
//    return results;
//}
//
//- (NSArray *)windowInfoList {
//    CGWindowListOption listOptions;
//    listOptions = kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements;
//    
//    CFArrayRef windowList = CGWindowListCopyWindowInfo(listOptions, kCGNullWindowID);
//    if (windowList == NULL) {
//        return nil;
//    }
//    
//    NSMutableArray *list = [[NSMutableArray alloc] init];
//    
//    CFIndex len = CFArrayGetCount(windowList);
//    for (int i=0; i < len; i++) {
//        NSDictionary *entry = (NSDictionary *)CFArrayGetValueAtIndex(windowList, i);
//        
//        //        int sharingState = [[entry objectForKey:(id)kCGWindowSharingState] intValue];
//        //        if (sharingState == kCGWindowSharingNone) continue;
//        
//        SInt32 windowID = 0;
//        CFNumberRef windowNumber = (__bridge CFNumberRef)([entry objectForKey:(id)kCGWindowNumber]);
//        CFNumberGetValue(windowNumber, kCGWindowIDCFNumberType, &windowID);
//        
//        NSString *name = [entry objectForKey:(id)kCGWindowOwnerName];
//        
//        CGRect bounds;
//        CGRectMakeWithDictionaryRepresentation((CFDictionaryRef)[entry objectForKey:(id)kCGWindowBounds], &bounds);
//        
//        int pid = [[entry objectForKey:(id)kCGWindowOwnerPID] intValue];
//        int number = [[entry objectForKey:(id)kCGWindowNumber] intValue];
//        
//        NSDictionary *info = @{ @"name": name,
//                                @"bounds.origin.x": [NSNumber numberWithFloat:bounds.origin.x],
//                                @"bounds.origin.y": [NSNumber numberWithFloat:bounds.origin.y],
//                                @"bounds.size.width": [NSNumber numberWithFloat:bounds.size.width],
//                                @"bounds.size.height": [NSNumber numberWithFloat:bounds.size.height],
//                                @"pid": [NSNumber numberWithInt:pid],
//                                @"number": [NSNumber numberWithInt:number] };
//        
//        [list addObject:info];
//    }
//    
//    CFRelease(windowList);
//    
//    return list;
//}
//
//
//@end
