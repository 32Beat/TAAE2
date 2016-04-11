//
//  RMSMeteringController.h
//  TAAESample
//
//  Created by 32BT on 11/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AERingBufferModule.h"

@interface RMSMeteringController : NSObject
<AERingBufferModuleObserverProtocol>

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer;

@end
