//
//  AERingBufferModule.h
//  TAAESample
//
//  Created by 32BT on 10/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>
#import "AERingBuffer.h"

typedef struct AERange
{
	uint64_t index;
	uint64_t count;
}
AERange;

static inline uint64_t AERangeMin(AERange R)
{ return R.index; }

static inline uint64_t AERangeMax(AERange R)
{ return R.index+R.count-(R.count!=0); }

@class AERingBufferModule;

/*
	AERingBufferModuleObserverProtocol
	----------------------------------
	Implement this protocol in your object to be able to attach the object 
	as observer and receive periodic ringbuffer updates. 
	
	Note that this is called on a concurrent background thread, but not on 
	the audiothread. The latest range of samples can be obtained by calling 
	ringBuffer->availableRange. If you add an index that stores the previous 
	update range, you can compute the new range as follows:

	// Compute samplerange since last update
	AERange range = [ringBuffer availableRange];
	if (mIndex < range.index)
	{ mIndex = range.index; }
	range.count -= mIndex-range.index;
	
*/
@protocol AERingBufferModuleObserverProtocol <NSObject>
- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer;
@end


/*
	AERingBufferModuleDelegateProtocol
	----------------------------------
	Implement this protocol in an object to be able to handle updates on main,
	after an observer is updated with the ringbuffer. 
	
	If the observer is a model object, then the delegate can for example 
	transfer the model result to a view, but only if doing so does not 
	collide with concurrent background updates of the model object. 
	(Generally true for displaying a value in a label for example).
	
	Because observing and delegation do not happen on the audio-thread, 
	it is possible to use locks. Recommended practice however is to simply 
	create a controller object that contains the model and the view, 
	and let the controller object be observer.
*/
@protocol AERingBufferModuleDelegateProtocol <NSObject>
- (void) ringBufferModule:(AERingBufferModule *)ringBuffer didUpdateObserver:(id)observer;
@end



@interface AERingBufferModule : AEModule

// srcIndex indicates buffer to process:
// -1 = output buffer, otherwise index into bufferstack where 0 = top-of-stack
@property (nonatomic, assign) int srcIndex;

// indicator whether currently part of a renderloop and in a valid state
@property (nonatomic, assign, getter=isActive) BOOL active;

// delegate
@property (nonatomic, weak) id<AERingBufferModuleDelegateProtocol> delegate;

// observer logic
- (void) addObserver:(id<AERingBufferModuleObserverProtocol>)observer;
- (void) removeObserver:(id<AERingBufferModuleObserverProtocol>)observer;
- (void) updateObservers;


// returns the available range (excluding margin)
- (AERange) availableRange;

// return indexing parameters:
- (uint64_t) indexMask;
- (const float *) samplePtrAtIndex:(unsigned)channelIndex;

@end




