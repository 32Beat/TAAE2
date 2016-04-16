//
//  AERingBuffer.m
//  TAAESample
//
//  Created by 32BT on 12/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

#import "AERingBuffer.h"
#import <math.h>
#import <Accelerate/Accelerate.h>

////////////////////////////////////////////////////////////////////////////////

AERingBuffer AERingBufferBegin(size_t minSampleCount)
{
	uint64_t shift = ceil(log2(minSampleCount));
	uint64_t indexMask = (1<<shift)-1;
	float *samplePtr = calloc(indexMask+1, sizeof(float));
	
	return (AERingBuffer){ 0, indexMask, samplePtr };
}

////////////////////////////////////////////////////////////////////////////////

void AERingBufferEnd(AERingBuffer *ringBuffer)
{
	if (ringBuffer->samplePtr != NULL)
	{
		free(ringBuffer->samplePtr);
		ringBuffer->samplePtr = NULL;
	}
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark
////////////////////////////////////////////////////////////////////////////////

void AERingBufferReset(AERingBuffer *ringBuffer)
{
	ringBuffer->index = 0;
	vDSP_vclr(ringBuffer->samplePtr, 1, ringBuffer->indexMask+1);
}

////////////////////////////////////////////////////////////////////////////////

void AERingBufferClear(AERingBuffer *ringBuffer)
{
	vDSP_vclr(ringBuffer->samplePtr, 1, ringBuffer->indexMask+1);
}

////////////////////////////////////////////////////////////////////////////////

void AERingBufferWriteSamples(AERingBuffer *ringBuffer, float *srcPtr, size_t count)
{
	for (;count!=0; count--)
	{ AERingBufferWriteSample(ringBuffer, *srcPtr++); }
}

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////


