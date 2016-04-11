//
//  AERingBufferModule.h
//  TAAESample
//
//  Created by 32BT on 10/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

typedef struct AERange
{
	uint64_t index;
	uint64_t count;
}
AERange;


@class AERingBufferModule;

@protocol AERingBufferModuleObserverProtocol <NSObject>
- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer;
@end

@protocol AERingBufferModuleDelegateProtocol <NSObject>
- (void) ringBufferModule:(AERingBufferModule *)ringBuffer
	didUpdateObserver:(id)observer;
@end

@interface AERingBufferModule : AEModule
@property (nonatomic, weak) id<AERingBufferModuleDelegateProtocol> delegate;

- (void) addObserver:(id<AERingBufferModuleObserverProtocol>)observer;
- (void) removeObserver:(id<AERingBufferModuleObserverProtocol>)observer;

- (AERange) availableRange;
- (float) valueAtIndex0:(uint64_t)index;
- (float) valueAtIndex1:(uint64_t)index;

@end
