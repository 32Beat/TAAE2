//
//  RMSMeteringController.m
//  TAAESample
//
//  Created by 32BT on 11/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////
/*
	RMSMeteringController
	---------------------
	An object to monitor the levels in a ringbuffer and 
	display the results in a view.
*/
////////////////////////////////////////////////////////////////////////////////


#import "RMSMeteringController.h"
#import "rmslevels_t.h"
#import "RMSLevelsView.h"


@interface RMSMeteringController ()
{
	uint64_t mIndex;
	
	Float64 mEngineRate;
	rmsengine_t mEngineL;
	rmsengine_t mEngineR;
	
	IBOutlet RMSLevelsView *mLevelsViewL;
	IBOutlet RMSLevelsView *mLevelsViewR;
}
@end

@implementation RMSMeteringController

/* 
	updateWithRingBufferModule:
	---------------------------
	This is called in a backgroundthread, but not the audiothread
	so we are free to use whatever language constructs we like. 
	
	It is called appr 24 times per second, so updating the view will seem 
	visually continuous. Note that we use the normal update mechanism
	where OS viewupdates are collected before being drawn.
	
	Because this is not on the audio-thread, nor on the main-thread, 
	we can be fairly liberal in codingconstructs, though it obviously
	pays to be fast regardless.
*/

/*
	1. Check ringBuffer state
	-------------------------
	When ringBuffer.silent is set, it means the ringBuffer is not currently 
	being updated for whatever reason, including not being part of 
	an audio-renderloop. This implies in particular that we need to fill the 
	metering with zero by ourselves, and not rely on the buffer being cleared.
	
	When the buffer is re-entering a renderloop, ringBuffer.reset will be set 
	to indicate to the audio-thread that the buffer needs clearing first,
	so the update-thread should ignore results until reset == NO.
*/

/*
	2. Reinitialize if necessary
	----------------------------
	The metering engine needs to reinitialize the integrationtime when 
	the samplerate changes, otherwise the meteringlevels will move faster 
	or slower depending on the ratechange. No memory is being allocated
	or released, although this might be possible within reason.
*/

/*
	3. Compute samplerange since last update
	----------------------------------------
	About 1/24th to 1/20th of a second passes between updates. 
	
	The ringbuffer has ample room for at least twice the corresponding samples. 
	
	e.g.: 1/20th of a second x samplerate of 44.1kHz = 2205 samples, 
	the ringbuffer is currently set for a capacity of more than 65000 samples. 
	
	For our meteringmodel we need to traverse all samples since the last update, 
	so we keep track of the next index we want to read and ask the ringBuffer 
	for its available range. 
	The normal updatecycle then requires the following range:
	
		readCount = range.count - (mIndex - range.index)
	
	which generally means we read appr the latest 2000 samples
*/

/*
	4. Process ringBuffer samples
	-----------------------------
	Next we read the samples within range from the ringBuffer and run them 
	through our metering engine. In order to speed things up slightly, 
	we fetch the pointers and indexMask and use them to read the samples 
	directly from the ringBuffer.
*/

/*
	5. Transfer results to views
	----------------------------
	Finally we fetch the results from the metering engine and transfer these 
	to the main-thread using block logic. This means we have a locally fixed 
	result that can be displayed, while the engine may be metering the next 
	stream of samples in the background.
*/

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer
{
	// 1. Check ringBuffer state
	if ((ringBuffer.silent == NO)&&(ringBuffer.reset == NO))
	{
		// 2. Reinitialize engines if necessary
		Float64 sampleRate = ringBuffer.renderer.sampleRate;
		if (mEngineRate != sampleRate)
		{
			mEngineRate = sampleRate;
			mEngineL = RMSEngineInit(sampleRate);
			mEngineR = RMSEngineInit(sampleRate);
		}
		
		// 3. Compute samplerange since last update
		AERange range = [ringBuffer availableRange];
		
		// reset index if necessary
		if (mIndex < AERangeMin(range)||
			mIndex > AERangeMax(range))
		{ mIndex = range.index; }

		range.count -= mIndex - range.index;
				
		// 4. Process samples
		uint64_t indexMask = [ringBuffer indexMask];
		const float *srcPtrL = [ringBuffer samplePtrAtIndex:0];
		const float *srcPtrR = [ringBuffer samplePtrAtIndex:1];
		for (uint64_t n=range.count; n!=0; n--)
		{
			RMSEngineAddSample(&mEngineL, srcPtrL[mIndex&indexMask]);
			RMSEngineAddSample(&mEngineR, srcPtrR[mIndex&indexMask]);
			mIndex += 1;
		}
	}
	else
	{
		// produce silence with reasonable integration time
		for (uint64_t n=ringBuffer.renderer.sampleRate/20.0; n!=0; n--)
		{
			RMSEngineAddSample(&mEngineL, 0);
			RMSEngineAddSample(&mEngineR, 0);
		}
	}
		
	// 5. Transfer result to view on main
	rmsresult_t L = RMSEngineFetchResult(&mEngineL);
	rmsresult_t R = RMSEngineFetchResult(&mEngineR);
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		mLevelsViewL.levels = L;
		mLevelsViewR.levels = R;
	});
}


@end
