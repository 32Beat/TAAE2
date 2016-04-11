//
//  AERingBufferModule.m
//  TAAESample
//
//  Created by 32BT on 10/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "AERingBufferModule.h"


@interface AERingBufferModule ()
{
	uint64_t mIndex;
	uint64_t mIndexMask;
	
	unsigned mChannelCount;
	float *_samplePtr[2];
	
	NSMutableArray *mObservers;
}
@end

////////////////////////////////////////////////////////////////////////////////
@implementation AERingBufferModule
////////////////////////////////////////////////////////////////////////////////
#pragma mark AEModule Logic
////////////////////////////////////////////////////////////////////////////////

- (instancetype)initWithRenderer:(AERenderer *)renderer
{
	self = [super initWithRenderer:renderer];
	if (self != nil)
	{
		mIndexMask = (1<<12) - 1;
		
		mChannelCount = 2;
		_samplePtr[0] = calloc(mIndexMask+1, sizeof(float));
		_samplePtr[1] = calloc(mIndexMask+1, sizeof(float));
		self.processFunction = AERingBufferModuleProcessFunction;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	for (int n=0; n!=mChannelCount; n++)
	{
		if (_samplePtr[n] != nil)
		{
			free(_samplePtr[n]);
			_samplePtr[n] = nil;
		}
	}
}

////////////////////////////////////////////////////////////////////////////////

- (float) valueAtIndex:(uint64_t)index channelIndex:(unsigned)channelIndex
{ return _samplePtr[channelIndex][index&mIndexMask]; }

////////////////////////////////////////////////////////////////////////////////

- (uint64_t) indexMask
{ return mIndexMask; }

- (const float *) samplePtrAtIndex:(unsigned)channelIndex
{ return channelIndex < mChannelCount ? _samplePtr[channelIndex] : nil; }

////////////////////////////////////////////////////////////////////////////////

static void RingBufferCopy
(
	float *dstPtr,
	uint64_t index,
	uint64_t indexMask,
	const float *srcPtr,
	size_t frameCount
)
{
/*
	for (size_t n=0; n!=frameCount; n++)
	{
		index &= indexMask;
		dstPtr0[index] = srcPtr0[n];
		dstPtr1[index] = srcPtr1[n];
		index += 1;
	}
*/
	for (;frameCount!=0; frameCount--)
	{
		dstPtr[index&indexMask] = srcPtr[0];
		srcPtr += 1;
		index += 1;
	}
}

////////////////////////////////////////////////////////////////////////////////

static void AERingBufferModuleProcessFunction(__unsafe_unretained AERingBufferModule * THIS,
const AERenderContext * _Nonnull context)
{
	const AudioBufferList *bufferList = AEBufferStackGet(context->stack, 0);
	if (bufferList != nil)
	{
		uint64_t index = THIS->mIndex;
		uint64_t indexMask = THIS->mIndexMask;
		size_t frameCount = AEBufferStackGetFrameCount(context->stack);
		if (frameCount > context->frames)
		{ frameCount = context->frames; }
		
		if (bufferList->mNumberBuffers > 0)
		{ RingBufferCopy(THIS->_samplePtr[0], index, indexMask, bufferList->mBuffers[0].mData, frameCount); }
		if (bufferList->mNumberBuffers > 1)
		{ RingBufferCopy(THIS->_samplePtr[1], index, indexMask, bufferList->mBuffers[1].mData, frameCount); }
		
		THIS->mIndex += frameCount;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Read Logic
////////////////////////////////////////////////////////////////////////////////

- (AERange) availableRange
{
	uint64_t index = mIndex;
	uint64_t count = (mIndexMask + 1) >> 1;
	
	if (index <= count)
	{ return (AERange){ 0, index }; }
	
	return (AERange){ index - count, count };
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Observer Logic
////////////////////////////////////////////////////////////////////////////////

- (BOOL) validateObserver:(id<AERingBufferModuleObserverProtocol>)observer
{
	return observer != nil &&
	[observer respondsToSelector:@selector(updateWithRingBufferModule:)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) addObserver:(id<AERingBufferModuleObserverProtocol>)observer
{
	if (mObservers == nil)
	{ mObservers = [NSMutableArray new]; }
	
	if ([self validateObserver:observer] &&
	[mObservers indexOfObjectIdenticalTo:observer] == NSNotFound)
	{ [mObservers addObject:observer]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeObserver:(id<AERingBufferModuleObserverProtocol>)observer
{
	[mObservers removeObjectIdenticalTo:observer];
}

////////////////////////////////////////////////////////////////////////////////

- (void) updateObservers
{
/*
	for(id observer in mObservers)
	{
		[observer updateWithRingBufferModule:self];
		if ([self.delegate respondsToSelector:
			@selector(ringBufferModule:didUpdateObserver:)])
		{ [self.delegate ringBufferModule:self didUpdateObserver:observer]; }
	}
/*/
	[mObservers enumerateObjectsWithOptions:NSEnumerationConcurrent
	usingBlock:^(id observer, NSUInteger index, BOOL *stop)
	{
		[observer updateWithRingBufferModule:self];
		if ([self.delegate respondsToSelector:
			@selector(ringBufferModule:didUpdateObserver:)])
		{
			dispatch_async(dispatch_get_main_queue(),
			^{ [self.delegate ringBufferModule:self didUpdateObserver:observer]; });
		}
	}];
//*/
}

////////////////////////////////////////////////////////////////////////////////
@end
////////////////////////////////////////////////////////////////////////////////











