#pragma once

#include <AudioToolbox/AudioToolbox.h>
#include <algorithm>
#include <cmath>
#include <span>
#include <vector>

#include "JJBreezeParameterAddresses.h"
#include "PitchShifter.h"
#include "ModulatedDelay.h"
#include "Warmth.h"
#include "Biquad.hpp"

class JJBreezeDSPKernel
{
public:
    void initialize(int inputChannelCount, int outputChannelCount, double inSampleRate)
    {
        mSampleRate = inSampleRate;
        mInputChannelCount = inputChannelCount;
        mOutputChannelCount = outputChannelCount;

        leftVoice.prepare(inSampleRate);
        rightVoice.prepare(inSampleRate);
        leftVoice.delay.setLfoStartPhase(0.0f);
        rightVoice.delay.setLfoStartPhase(0.5f);

        vibratoL.prepare(inSampleRate);
        vibratoR.prepare(inSampleRate);
        vibratoL.setBaseDelayMs(9.0f);
        vibratoR.setBaseDelayMs(9.0f);
        vibratoL.setLfoStartPhase(0.0f);
        vibratoR.setLfoStartPhase(0.5f);

        warmthL.prepare(inSampleRate);
        warmthR.prepare(inSampleRate);
        mInitialized = true;
    }

    void deInitialize()
    {
        leftVoice.reset();
        rightVoice.reset();
        vibratoL.reset();
        vibratoR.reset();
        warmthL.reset();
        warmthR.reset();
        mInitialized = false;
    }

    bool isBypassed() const { return mBypassed; }
    void setBypass(bool shouldBypass) { mBypassed = shouldBypass; }

    void setParameter(AUParameterAddress address, AUValue value)
    {
        switch (address)
        {
            case JJBreezeParameterAddress::pitchL:       mPitchL = value; break;
            case JJBreezeParameterAddress::pitchR:       mPitchR = value; break;
            case JJBreezeParameterAddress::delayL:       mDelayL = std::clamp(value, 0.0f, 250.0f); break;
            case JJBreezeParameterAddress::delayR:       mDelayR = std::clamp(value, 0.0f, 250.0f); break;
            case JJBreezeParameterAddress::focus:        mFocus = value; break;
            case JJBreezeParameterAddress::mix:          mMix = value; break;
            case JJBreezeParameterAddress::vibratoRate:  mVibratoRate = value; break;
            case JJBreezeParameterAddress::vibratoDepth: mVibratoDepth = value; break;
            case JJBreezeParameterAddress::vibratoMix:   mVibratoMix = value; break;
            case JJBreezeParameterAddress::warmthTone:   mWarmthTone = value; break;
            case JJBreezeParameterAddress::warmthDrive:  mWarmthDrive = value; break;
            case JJBreezeParameterAddress::warmthBody:   mWarmthBody = value; break;
            case JJBreezeParameterAddress::warmthMix:    mWarmthMix = value; break;
            case JJBreezeParameterAddress::shiftOn:      mShiftOn = value; break;
            case JJBreezeParameterAddress::vibratoOn:    mVibratoOn = value; break;
            case JJBreezeParameterAddress::warmthOn:     mWarmthOn = value; break;
            default: break;
        }
    }

    AUValue getParameter(AUParameterAddress address)
    {
        switch (address)
        {
            case JJBreezeParameterAddress::pitchL:       return mPitchL;
            case JJBreezeParameterAddress::pitchR:       return mPitchR;
            case JJBreezeParameterAddress::delayL:       return mDelayL;
            case JJBreezeParameterAddress::delayR:       return mDelayR;
            case JJBreezeParameterAddress::focus:        return mFocus;
            case JJBreezeParameterAddress::mix:          return mMix;
            case JJBreezeParameterAddress::vibratoRate:  return mVibratoRate;
            case JJBreezeParameterAddress::vibratoDepth: return mVibratoDepth;
            case JJBreezeParameterAddress::vibratoMix:   return mVibratoMix;
            case JJBreezeParameterAddress::warmthTone:   return mWarmthTone;
            case JJBreezeParameterAddress::warmthDrive:  return mWarmthDrive;
            case JJBreezeParameterAddress::warmthBody:   return mWarmthBody;
            case JJBreezeParameterAddress::warmthMix:    return mWarmthMix;
            case JJBreezeParameterAddress::shiftOn:      return mShiftOn;
            case JJBreezeParameterAddress::vibratoOn:    return mVibratoOn;
            case JJBreezeParameterAddress::warmthOn:     return mWarmthOn;
            default: return 0.f;
        }
    }

    AUAudioFrameCount maximumFramesToRender() const { return mMaxFramesToRender; }
    void setMaximumFramesToRender(const AUAudioFrameCount& maxFrames) { mMaxFramesToRender = maxFrames; }

    void setMusicalContextBlock(AUHostMusicalContextBlock contextBlock)
    {
        mMusicalContextBlock = contextBlock;
    }

    void process(std::span<float const*> inputBuffers,
                 std::span<float*> outputBuffers,
                 AUEventSampleTime,
                 AUAudioFrameCount frameCount)
    {
        if (! mInitialized || inputBuffers.empty() || outputBuffers.empty())
            return;

        if (mBypassed)
        {
            float peak = 0.f;
            for (size_t channel = 0; channel < outputBuffers.size(); ++channel)
            {
                const float* src = inputBuffers[std::min(channel, inputBuffers.size() - 1)];
                std::copy_n(src, frameCount, outputBuffers[channel]);
                for (AUAudioFrameCount n = 0; n < frameCount; ++n)
                    peak = std::max(peak, std::abs(src[n]));
            }
            capturePeaks(peak, peak);
            return;
        }

        FlushDenormals denormals;

        const float pitchLCents = mPitchL;
        const float pitchRCents = mPitchR;
        const float delayLMs    = mDelayL;
        const float delayRMs    = mDelayR;
        const float focusHz     = mFocus;
        const float mix         = mMix * 0.01f;
        const float vibRateHz   = mVibratoRate;
        const float vibDepthMs  = mVibratoDepth;
        const float vibMixAmt   = mVibratoMix * 0.01f;
        const float warmthToneHz   = mWarmthTone;
        const float warmthDriveAmt = mWarmthDrive * 0.01f;
        const float warmthBodyAmt  = mWarmthBody * 0.01f;
        const float warmthMixAmt   = mWarmthMix * 0.01f;

        const bool shiftIsOn   = mShiftOn > 0.5f;
        const bool vibratoIsOn = mVibratoOn > 0.5f;
        const bool warmthIsOn  = mWarmthOn > 0.5f;

        leftVoice.pitchShifter.setShiftCents(pitchLCents);
        rightVoice.pitchShifter.setShiftCents(pitchRCents);
        leftVoice.delay.setBaseDelayMs(delayLMs);
        rightVoice.delay.setBaseDelayMs(delayRMs);

        const auto lowCoeffs  = Biquad::makeLowPass(mSampleRate, focusHz);
        const auto highCoeffs = Biquad::makeHighPass(mSampleRate, focusHz);
        leftVoice.lowBandFilter.setFromArray(lowCoeffs);
        leftVoice.highBandFilter.setFromArray(highCoeffs);
        rightVoice.lowBandFilter.setFromArray(lowCoeffs);
        rightVoice.highBandFilter.setFromArray(highCoeffs);

        vibratoL.lfoRateHz  = vibRateHz;
        vibratoL.lfoDepthMs = vibDepthMs;
        vibratoR.lfoRateHz  = vibRateHz;
        vibratoR.lfoDepthMs = vibDepthMs;

        warmthL.setToneHz(warmthToneHz);
        warmthR.setToneHz(warmthToneHz);
        warmthL.setDrive(warmthDriveAmt);
        warmthR.setDrive(warmthDriveAmt);
        warmthL.setBodyAmount(warmthBodyAmt);
        warmthR.setBodyAmount(warmthBodyAmt);

        const float* inL = inputBuffers[0];
        const float* inR = inputBuffers.size() > 1 ? inputBuffers[1] : inputBuffers[0];
        float* outLPtr = outputBuffers[0];
        float* outRPtr = outputBuffers.size() > 1 ? outputBuffers[1] : outputBuffers[0];

        float peakIn = 0.f;
        float peakOut = 0.f;

        for (AUAudioFrameCount n = 0; n < frameCount; ++n)
        {
            const float dryL = inL[n];
            const float dryR = inR[n];

            const float lowL = leftVoice.lowBandFilter.processSample(dryL);
            float highL = leftVoice.highBandFilter.processSample(dryL);
            highL = leftVoice.pitchShifter.processSample(highL);
            highL = leftVoice.delay.processSample(highL);
            const float wetL = lowL + highL;

            const float lowR = rightVoice.lowBandFilter.processSample(dryR);
            float highR = rightVoice.highBandFilter.processSample(dryR);
            highR = rightVoice.pitchShifter.processSample(highR);
            highR = rightVoice.delay.processSample(highR);
            const float wetR = lowR + highR;

            const float vibL = vibratoL.processSample(dryL);
            const float vibR = vibratoR.processSample(dryR);

            const float shiftMixL = shiftIsOn ? mix * (wetL - dryL) : 0.0f;
            const float shiftMixR = shiftIsOn ? mix * (wetR - dryR) : 0.0f;
            const float vibMixL   = vibratoIsOn ? vibMixAmt * (vibL - dryL) : 0.0f;
            const float vibMixR   = vibratoIsOn ? vibMixAmt * (vibR - dryR) : 0.0f;

            const float chainL = dryL + shiftMixL + vibMixL;
            const float chainR = dryR + shiftMixR + vibMixR;

            const float warmL = warmthL.processSample(chainL);
            const float warmR = warmthR.processSample(chainR);
            const float warmthBlend = warmthIsOn ? warmthMixAmt : 0.0f;

            const float outL = chainL + warmthBlend * (warmL - chainL);
            const float outR = chainR + warmthBlend * (warmR - chainR);
            outLPtr[n] = outL;
            outRPtr[n] = outR;

            peakIn = std::max(peakIn, std::max(std::abs(dryL), std::abs(dryR)));
            peakOut = std::max(peakOut, std::max(std::abs(outL), std::abs(outR)));
        }

        capturePeaks(peakIn, peakOut);
    }

    void readPeaks(float* inPeak, float* outPeak)
    {
        if (inPeak)
        {
            *inPeak = mPeakIn;
            mPeakIn = 0.f;
        }
        if (outPeak)
        {
            *outPeak = mPeakOut;
            mPeakOut = 0.f;
        }
    }

    void handleOneEvent(AUEventSampleTime now, AURenderEvent const* event)
    {
        switch (event->head.eventType)
        {
            case AURenderEventParameter:
                handleParameterEvent(now, event->parameter);
                break;
            default:
                break;
        }
    }

    void handleParameterEvent(AUEventSampleTime, AUParameterEvent const& parameterEvent)
    {
        setParameter(parameterEvent.parameterAddress, parameterEvent.value);
    }

private:
    struct ChannelVoice
    {
        PitchShifter pitchShifter;
        ModulatedDelay delay;
        Biquad lowBandFilter;
        Biquad highBandFilter;

        void prepare(double sampleRate)
        {
            pitchShifter.prepare(sampleRate, 70.0f);
            delay.prepare(sampleRate);
            lowBandFilter.reset();
            highBandFilter.reset();
        }

        void reset()
        {
            pitchShifter.reset();
            delay.reset();
            lowBandFilter.reset();
            highBandFilter.reset();
        }
    };

    ChannelVoice leftVoice, rightVoice;
    ModulatedDelay vibratoL, vibratoR;
    WarmthStage warmthL, warmthR;

    AUHostMusicalContextBlock mMusicalContextBlock;

    double mSampleRate = 44100.0;
    int mInputChannelCount = 2;
    int mOutputChannelCount = 2;
    bool mBypassed = false;
    bool mInitialized = false;
    AUAudioFrameCount mMaxFramesToRender = 1024;

    float mPitchL = 300.0f;
    float mPitchR = 300.0f;
    float mDelayL = 15.0f;
    float mDelayR = 15.0f;
    float mFocus = 150.0f;
    float mMix = 50.0f;
    float mVibratoRate = 1.2f;
    float mVibratoDepth = 3.0f;
    float mVibratoMix = 0.0f;
    float mWarmthTone = 3500.0f;
    float mWarmthDrive = 20.0f;
    float mWarmthBody = 0.0f;
    float mWarmthMix = 0.0f;
    float mShiftOn = 1.0f;
    float mVibratoOn = 0.0f;
    float mWarmthOn = 0.0f;

    float mPeakIn = 0.f;
    float mPeakOut = 0.f;

    void capturePeaks(float inPeak, float outPeak)
    {
        if (inPeak > mPeakIn)
            mPeakIn = inPeak;
        if (outPeak > mPeakOut)
            mPeakOut = outPeak;
    }
};
