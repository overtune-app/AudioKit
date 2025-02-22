// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/AudioKit/

#include "ParameterAutomation.h"
#include <algorithm>
#include <mach/mach_time.h>
#include <map>
#include <vector>
#include <list>
#include <utility>

/// Returns a render observer block which will apply the automation to the selected parameter.
extern "C"
AURenderObserver ParameterAutomationGetRenderObserver(AUParameterAddress address,
                                                      AUScheduleParameterBlock scheduleParameterBlock,
                                                      Float64 sampleRate,
                                                      Float64 startSampleTime,
                                                      const struct AutomationEvent* eventsArray,
                                                      size_t count) {

    std::vector<AutomationEvent> events{eventsArray, eventsArray+count};

    // Sort events by start time.
    std::sort(events.begin(), events.end(), [](auto a, auto b) {
        return a.startTime < b.startTime;
    });

    __block int index = 0;

    return ^void(AudioUnitRenderActionFlags actionFlags,
                 const AudioTimeStamp *timestamp,
                 AUAudioFrameCount frameCount,
                 NSInteger outputBusNumber)
    {
        if (actionFlags != kAudioUnitRenderAction_PreRender) return;

        Float64 blockStartTime = timestamp->mSampleTime - startSampleTime;
        Float64 blockEndTime = blockStartTime + frameCount;

        AUValue initial = NAN;

        // Skip over events completely in the past to determine
        // an initial value.
        for(; index < count; ++index) {
            auto event = events[index];
            if ( round(sampleRate * (event.startTime + event.rampDuration)) >= blockStartTime ) {
               break;
            }
            initial = event.targetValue;
        }

        // Do we have an initial value from completed events?
        if(!isnan(initial)) {
            scheduleParameterBlock(AUEventSampleTimeImmediate,
                                   0,
                                   address,
                                   initial);
        }

        // Apply parameter automation for the segment.
        while (index < count) {
            auto event = events[index];

            // Is it after the current block?
            if (round(sampleRate * event.startTime) >= blockEndTime) break;

            AUEventSampleTime startTime = round(sampleRate * event.startTime - blockStartTime);
            AUAudioFrameCount duration = round(sampleRate * event.rampDuration);

            // If the event has already started, ensure we hit the targetValue
            // at the appropriate time.
            if(startTime < 0) {
                duration += startTime;
            }

            scheduleParameterBlock(AUEventSampleTimeImmediate + startTime,
                                   duration,
                                   address,
                                   event.targetValue);

            index++;
        }

    };

}
