//
//  RMSMeteringController.m
//  TAAESample
//
//  Created by 32BT on 11/04/16.
//  Copyright © 2016 A Tasty Pixel. All rights reserved.
//

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

// This is called in a backgroundthread, but not the audiothread
// so we are free to use whatever language constructs we like

- (void) updateWithRingBufferModule:(AERingBufferModule *)ringBuffer
{
	if (ringBuffer.silent == NO)
	{
		// Reinitialize engines if necessary
		Float64 sampleRate = ringBuffer.renderer.sampleRate;
		if (mEngineRate != sampleRate)
		{
			mEngineRate = sampleRate;
			mEngineL = RMSEngineInit(sampleRate);
			mEngineR = RMSEngineInit(sampleRate);
		}
		
		
		// Compute samplerange since last update
		AERange range = [ringBuffer availableRange];
		
		// reset index if necessary
		if (mIndex < AERangeMin(range)||
			mIndex > AERangeMax(range))
		{ mIndex = range.index; }

		range.count -= mIndex - range.index;
				
		// Process samples
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
		for (uint64_t n=2048; n!=0; n--)
		{
			RMSEngineAddSample(&mEngineL, 0);
			RMSEngineAddSample(&mEngineR, 0);
		}
	}
		
	// Transfer result to view on main
	rmsresult_t L = RMSEngineFetchResult(&mEngineL);
	rmsresult_t R = RMSEngineFetchResult(&mEngineR);
	
	dispatch_async(dispatch_get_main_queue(),
	^{
		mLevelsViewL.levels = L;
		mLevelsViewR.levels = R;
	});
}


@end
