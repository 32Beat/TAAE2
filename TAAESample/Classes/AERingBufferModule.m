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
	
	size_t mSampleCount;
	size_t mChannelCount;
	AERingBuffer mRingBuffer[2];
	
	NSHashTable *mObservers;
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
		mSampleCount = (1<<16);
		
		mChannelCount = 2;
		mRingBuffer[0] = AERingBufferBegin(mSampleCount);
		mRingBuffer[1] = AERingBufferBegin(mSampleCount);
		self.processFunction = AERingBufferModuleProcessFunction;
	}
	
	return self;
}

////////////////////////////////////////////////////////////////////////////////

- (void) dealloc
{
	for (int n=0; n!=mChannelCount; n++)
	{
		AERingBufferEnd(&mRingBuffer[n]);
	}
}

////////////////////////////////////////////////////////////////////////////////

static void AERingBufferModuleProcessFunction(__unsafe_unretained AERingBufferModule * THIS,
const AERenderContext * _Nonnull context)
{
	if (THIS->mIndex != context->frameIndex)
	{
		THIS->mIndex = context->frameIndex;
		AERingBufferReset(&THIS->mRingBuffer[0]);
		AERingBufferReset(&THIS->mRingBuffer[1]);
	}
	
	// source = top of stack
	const AudioBufferList *bufferList = THIS->_srcIndex >= 0 ?
	AEBufferStackGet(context->stack, THIS->_srcIndex) : context->output;
	
	if (bufferList != nil)
	{
		// frameCount is MIN(stackFrames, contextFrames)
		// although contextFrameCount > stackFrameCount is probably an error
		size_t frameCount = AEBufferStackGetFrameCount(context->stack);
		if (frameCount > context->frames)
		{ frameCount = context->frames; }

		// if at least 2 channels,
		// then copy first two channels into our ringbuffers
		if (bufferList->mNumberBuffers >= 2)
		{
			float *srcPtr0 = bufferList->mBuffers[0].mData;
			float *srcPtr1 = bufferList->mBuffers[1].mData;
			for (UInt32 n=0; n!=frameCount; n++)
			{
				AERingBufferWriteSample(&THIS->mRingBuffer[0], srcPtr0[n]);
				AERingBufferWriteSample(&THIS->mRingBuffer[1], srcPtr1[n]);
			}
		}
		else
		if (bufferList->mNumberBuffers == 1)
		{
			float *srcPtr0 = bufferList->mBuffers[0].mData;
			for (UInt32 n=0; n!=frameCount; n++)
			{
				AERingBufferWriteSample(&THIS->mRingBuffer[0], srcPtr0[n]);
				AERingBufferWriteSample(&THIS->mRingBuffer[1], srcPtr0[n]);
			}
		}
		
		THIS->mIndex += frameCount;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Read Logic
////////////////////////////////////////////////////////////////////////////////

- (AERange) availableRange
{
	// fetch writeIndices, determine minimum index
	uint64_t index0 = mRingBuffer[0].index;
	uint64_t index1 = mRingBuffer[1].index;
	uint64_t index = index0 < index1 ? index0 : index1;
	
	// available count is at most half the buffer
	uint64_t count = (mRingBuffer[0].indexMask+1) >> 1;
	
	if (index <= count)
	{ return (AERange){ 0, index }; }
	
	return (AERange){ index - count, count };
}

////////////////////////////////////////////////////////////////////////////////

- (uint64_t) indexMask
{ return mSampleCount-1; }

- (const float *) samplePtrAtIndex:(unsigned)channelIndex
{ return channelIndex < mChannelCount ? mRingBuffer[channelIndex].samplePtr : nil; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark Observer Logic
////////////////////////////////////////////////////////////////////////////////

- (BOOL) validateObserver:(id)observer
{
	return observer != nil &&
	[observer respondsToSelector:@selector(updateWithRingBufferModule:)];
}

////////////////////////////////////////////////////////////////////////////////

- (void) addObserver:(id<AERingBufferModuleObserverProtocol>)observer
{
	if (mObservers == nil)
	{ mObservers = [NSHashTable weakObjectsHashTable]; }
	
	if ([self validateObserver:observer] &&
	[mObservers containsObject:observer] == NO)
	{ [mObservers addObject:observer]; }
}

////////////////////////////////////////////////////////////////////////////////

- (void) removeObserver:(id<AERingBufferModuleObserverProtocol>)observer
{
	[mObservers removeObject:observer];
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
	[[mObservers allObjects] enumerateObjectsWithOptions:NSEnumerationConcurrent
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











