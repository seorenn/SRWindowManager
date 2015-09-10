//
//  SRWindowManagerImpl.m
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import "SRWindowManagerImpl.h"
#import <Carbon/Carbon.h>

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

NSImage * _Nullable SRWindowCaptureScreen(SInt32 windowID, NSRect bounds) {
    CGImageRef cfimage = NULL;
    
    cfimage = CGWindowListCreateImage(bounds, kCGWindowListOptionAll, windowID, kCGWindowImageDefault);
    if (cfimage == NULL) return nil;
    NSImage *image = [[NSImage alloc] initWithCGImage:cfimage size:bounds.size];
    
    CFRelease(cfimage);
    
    return image;
}

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

NSDictionary<NSString *, id> * _Nullable SRWindowGetFrontmostInfo() {
    AXUIElementRef systemWideElement = AXUIElementCreateSystemWide();
    AXUIElementRef focusedAppElement = SRWindowCopyElementAttribute(systemWideElement, kAXFocusedApplicationAttribute);
    NSDictionary<NSString *, id> *result = nil;
    
    if (focusedAppElement) {
        AXUIElementRef frontWindowElement = SRWindowCopyElementAttribute(focusedAppElement, kAXFocusedWindowAttribute);
        if (frontWindowElement) {
            // TODO
            CFRelease(frontWindowElement);
        }
        
        CFRelease(focusedAppElement);
    }
    
    CFRelease(systemWideElement);
    return result;
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
