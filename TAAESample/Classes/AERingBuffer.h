//
//  AERingBuffer.h
//  TAAESample
//
//  Created by 32BT on 12/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
/*
	AERingBuffer
	------------
	A simple unguarded ringbuffer type for quickly transferring samples 
	between the audio-thread and other threads.
	
	usage indication:
	
	// initialize struct with maximum required sample count (incl margin)
	AERingBuffer ringBuffer = AERingBufferBegin(maxSampleCount);
	
	// on audio thread call:
	AERingBufferWriteSamples(&ringBuffer, srcPtr, frameCount);
	
	
	
*/
////////////////////////////////////////////////////////////////////////////////
#ifndef aeringbuffer_t
#define aeringbuffer_t


#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

typedef struct AERingBuffer
{
	uint64_t index;
	uint64_t indexMask;
	float *samplePtr;
}
AERingBuffer;


#ifdef __cplusplus
extern "C" {
#endif

AERingBuffer AERingBufferBegin(size_t maxSampleCount);
void AERingBufferEnd(AERingBuffer ringBuffer);

static inline void AERingBufferWriteSample(AERingBuffer *ringBuffer, float sample)
{ ringBuffer->samplePtr[(ringBuffer->index += 1)&ringBuffer->indexMask] = sample; }

static inline float AERingBufferReadSample(const AERingBuffer *ringBuffer, uint64_t index)
{ return ringBuffer->samplePtr[index&ringBuffer->indexMask]; }

#ifdef __cplusplus
}
#endif
#endif // aeringbuffer_t
////////////////////////////////////////////////////////////////////////////////







