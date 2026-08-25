#pragma once

#include "Biquad.hpp"

/** A single-channel warmth tone stage matching the desktop plugin:
    low-shelf body boost, low-pass, then tanh saturation. */
class WarmthStage
{
public:
    void prepare(double newSampleRate)
    {
        sampleRate = newSampleRate;
        updateLowShelf();
        reset();
    }

    void reset()
    {
        lowShelf.reset();
        filter.reset();
    }

    void setToneHz(float hz)
    {
        filter.setFromArray(Biquad::makeLowPass(sampleRate, hz, 0.707f));
    }

    void setDrive(float amount01) { drive = amount01; }

    void setBodyAmount(float amount01)
    {
        if (std::abs(amount01 - bodyAmount) < 1.0e-4f)
            return;
        bodyAmount = amount01;
        updateLowShelf();
    }

    float processSample(float x)
    {
        const float shelved = lowShelf.processSample(x);
        const float filtered = filter.processSample(shelved);

        if (drive < 1.0e-4f)
            return filtered;

        const float k = drive * 10.0f;
        return std::tanh(filtered * k) / std::tanh(k);
    }

private:
    void updateLowShelf()
    {
        static constexpr float bodyHz = 150.0f;
        static constexpr float maxBoostDb = 6.0f;
        const float linearGain = std::pow(10.0f, (bodyAmount * maxBoostDb) / 20.0f);
        lowShelf.setFromArray(Biquad::makeLowShelf(sampleRate, bodyHz, 0.707f, linearGain));
    }

    double sampleRate = 44100.0;
    Biquad lowShelf;
    Biquad filter;
    float drive = 0.0f;
    float bodyAmount = 0.0f;
};
