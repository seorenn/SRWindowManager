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

void SRWindowLogUIElementCopyAttributeError(NSString *prefix, AXError error) {
    switch (error) {
        case kAXErrorAttributeUnsupported:
            NSLog(@"%@ UIElementCopyAttributeError: Attribute Unsupported", prefix);
            break;
        case kAXErrorNoValue:
            NSLog(@"%@ UIElementCopyAttributeError: No Value", prefix);
            break;
        case kAXErrorIllegalArgument:
            NSLog(@"%@ UIElementCopyAttributeError: Illegal Argument", prefix);
            break;
        case kAXErrorInvalidUIElement:
            NSLog(@"%@ UIElementCopyAttributeError: Invalid UI Element", prefix);
            break;
        case kAXErrorCannotComplete:
            NSLog(@"%@ UIElementCopyAttributeError: Cannot Complete", prefix);
            break;
        case kAXErrorNotImplemented:
            NSLog(@"%@ UIElementCopyAttributeError: Not Implemented", prefix);
            break;
        default:
            NSLog(@"%@ UIElementCopyAttributeError: Unknown(%d)", prefix, error);
    }
}

void SRWindowRequestAccessibility() {
    NSDictionary *options = @{ (__bridge id)kAXTrustedCheckOptionPrompt: @YES };
    AXIsProcessTrustedWithOptions((__bridge CFDictionaryRef)options);
}

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
    
    cfimage = CGWindowListCreateImage(bounds, kCGWindowListOptionIncludingWindow, windowID, kCGWindowImageBoundsIgnoreFraming | kCGWindowImageShouldBeOpaque);
    if (cfimage == NULL) return nil;
    NSImage *image = [[NSImage alloc] initWithCGImage:cfimage size:bounds.size];
    
    CFRelease(cfimage);
    
    return image;
}

CFDictionaryRef _Nullable SRWindowCreateWindowDescription(CGWindowID windowID) {
    CGWindowID windowIDArray[1] = { windowID };
    CFArrayRef descriptionInput = CFArrayCreate(kCFAllocatorDefault, (const void **)&windowIDArray, 1, NULL);
    CFArrayRef descriptions = CGWindowListCreateDescriptionFromArray(descriptionInput);
    
    if (descriptions == NULL || CFArrayGetCount(descriptions) <= 0) {
        CFRelease(descriptionInput);
        if (descriptions) { CFRelease(descriptions); }
        return NULL;
    }
    
    CFDictionaryRef desc = CFArrayGetValueAtIndex(descriptions, 0);
    CFRetain(desc);
    
    CFRelease(descriptionInput);
    CFRelease(descriptions);
    
    return desc;
}

//NSString * _Nonnull SRWindowGetWindowName(CGWindowID windowID) {
//    CFDictionaryRef description = SRWindowCreateWindowDescription(windowID);
//    if (description == NULL) return @"";
//    
//    NSString *name = (__bridge NSString *)CFDictionaryGetValue(description, kCGWindowName);
//    CFRelease(description);
//    
//    return name;
//}

//NSString * _Nonnull SRWindowGetWindowOwnerName(CGWindowID windowID) {
//    CFDictionaryRef description = SRWindowCreateWindowDescription(windowID);
//    if (description == NULL) return @"";
//    
//    NSString *name = (__bridge NSString *)CFDictionaryGetValue(description, kCGWindowOwnerName);
//    CFRelease(description);
//    
//    return name;
//}

pid_t SRWindowGetWindowOwnerPID(CGWindowID windowID) {
    CFDictionaryRef description = SRWindowCreateWindowDescription(windowID);
    if (description == NULL) return 0;
    
    NSNumber *pid = (__bridge NSNumber *)CFDictionaryGetValue(description, kCGWindowOwnerPID);
    CFRelease(description);
    
    return [pid intValue];
}

#pragma mark - Private API Interfaces

CGWindowID SRWindowGetID(AXUIElementRef _Nonnull windowElement) {
    CGWindowID windowID = 0;
    _AXUIElementGetWindow(windowElement, &windowID);
    
    return windowID;
}

#pragma mark - Interfaces with Accessibility
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
    } else {
        NSLog(@"Failed to get Focused Application Attribute");
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

//CGRect SRWindowGetFrameOfWindowElement(AXUIElementRef _Nonnull windowElement) {
//    CGRect result = CGRectNull;
//    
//    CFTypeRef positionObject = SRWindowCopyElementValue(windowElement, kAXPositionAttribute, kAXValueCGPointType);
//    CFTypeRef sizeObject = SRWindowCopyElementValue(windowElement, kAXSizeAttribute, kAXValueCGSizeType);
//    
//    CGPoint position;
//    CGSize size;
//    int count = 0;
//    
//    if (positionObject) {
//        AXValueGetValue(positionObject, kAXValueCGPointType, (void *)&position);
//        CFRelease(positionObject);
//        count++;
//    }
//    
//    if (sizeObject) {
//        AXValueGetValue(sizeObject, kAXValueCGSizeType, (void *)&size);
//        CFRelease(sizeObject);
//        count++;
//    }
//    
//    if (count == 2) {
//        result = CGRectMake(position.x, position.y, size.width, size.height);
//    }
//    
//    return result;
//}

CFArrayRef _Nullable SRWindowCopyApplicationWindows(AXUIElementRef applicationElement) {
    CFArrayRef result = NULL;

    AXError error = AXUIElementCopyAttributeValue(applicationElement, kAXWindowsAttribute, (CFTypeRef *)&result);
    
    if (error != kAXErrorSuccess) {
#if DEBUG
        SRWindowLogUIElementCopyAttributeError(@"SRWindowCopyApplicationWindows", error);
#endif
        return nil;
    }
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
