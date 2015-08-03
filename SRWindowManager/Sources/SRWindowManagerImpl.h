//
//  SRWindowManagerImpl.h
//  SRWindowManager
//
//  Created by Heeseung Seo on 2015. 7. 30..
//  Copyright © 2015년 Seorenn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@class SRWindowManagerImpl;

@protocol SRWindowManagerImplDelegate /* <NSObject>*/
@optional
- (void)windowManagerImpl:(SRWindowManagerImpl *)windowManagerImpl detectWindowActivating:(NSRunningApplication *)runningApplication;
@end

@interface SRWindowManagerImpl : NSObject

@property (nonatomic, readonly) BOOL detecting;
@property (nonatomic, strong) id<SRWindowManagerImplDelegate> delegate;

- (void)startDetect;
- (void)stopDetect;

- (NSArray *)windows;
- (NSArray *)windowInfoList;

@end
