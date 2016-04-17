//
//  RMSOscilloscopeController.h
//  TAAESample
//
//  Created by 32BT on 17/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AERingBufferModule.h"
#import "RMSOscilloscopeView.h"

@interface RMSOscilloscopeController : NSObject
<AERingBufferModuleObserverProtocol>

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer;

@property (nonatomic, weak) IBOutlet RMSOscilloscopeView *view;

@end
