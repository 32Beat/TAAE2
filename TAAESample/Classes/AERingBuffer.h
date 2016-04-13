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
	A lightweight unguarded ringbuffer type for quickly transferring samples
	between the audio-thread and other threads.
	
	Continuously increments an unmasked 64bit index on write, 
	and uses a bitmask to find the true index within the buffer.
	
		samplePtr[index & indexMask] = src
	
	Similarly a sample can be fetched using a continuously incrementing readindex 
	where: readIndex < writeIndex (writeIndex always points to the next empty slot)
	and: readIndex >= writeIndex - (indexMask+1)
	
	usage indication:
	
	// initialize struct with a minimum required sample count (incl margin)
	AERingBuffer ringBuffer = AERingBufferBegin(minSampleCount);
	
	// on audio thread call:
	AERingBufferWriteSamples(&ringBuffer, srcPtr, frameCount);
	
	// when done with the buffer entirely, use:
	AERingBufferEnd(&ringBuffer);
	
*/
////////////////////////////////////////////////////////////////////////////////
#ifndef aeringbuffer_t
#define aeringbuffer_t


#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>


typedef struct AERingBuffer
{
	uint64_t index; 	// continuously incremented write index
	uint64_t indexMask; // bitmask for true index
	float *samplePtr; 	// sample data
}
AERingBuffer;


////////////////////////////////////////////////////////////////////////////////
#ifdef __cplusplus
extern "C" {
#endif
////////////////////////////////////////////////////////////////////////////////

/*
	AERingBufferBegin
	-----------------
	Initialize a ringbuffer struct 
	
	minSampleCount: the minimum capacity of the buffer, 
	note that the true capacity will always be a multiple of 2
	
	calloc is used to initialize samplePtr
*/
AERingBuffer AERingBufferBegin(size_t minSampleCount);


/*
	AERingBufferEnd
	---------------
	Free the pointer in the struct and set it to nil
*/
void AERingBufferEnd(AERingBuffer *ringBuffer);

////////////////////////////////////////////////////////////////////////////////

// Write a sample into the buffer at the next available slot
static inline void AERingBufferWriteSample(AERingBuffer *ringBuffer, float sample)
{ ringBuffer->samplePtr[(ringBuffer->index += 1)&ringBuffer->indexMask] = sample; }

// Fetch a sample from the buffer at the specified index
static inline float AERingBufferReadSample(const AERingBuffer *ringBuffer, uint64_t index)
{ return ringBuffer->samplePtr[index&ringBuffer->indexMask]; }

////////////////////////////////////////////////////////////////////////////////
#ifdef __cplusplus
}
#endif
#endif // aeringbuffer_t
////////////////////////////////////////////////////////////////////////////////







