#pragma once
#include <JuceHeader.h>


#define NAME_FREQ      "frequency"
#define DEFAULT_FREQ   1.0f
#define RATE_SMTH      0.05f


//The class RingModOscillator creates an oscillator that is directly modulated in frequency by the lfo.
class RingModOscillator : public AudioProcessorValueTreeState::Listener
{
public:
    RingModOscillator()
    {
        frequency.setCurrentAndTargetValue(DEFAULT_FREQ);
    }

    ~RingModOscillator() {};

    void prepareToPlay(double sr, const int maxSamplesPerBlock)
    {
        sampleRate = sr;
        frequency.reset(sr, RATE_SMTH);
        
    }

    void getNextAudioBlock(AudioBuffer<float>& lfoBuffer, AudioBuffer<float>& oscillatorBuffer, const int numSamples)
    {
        auto* oscillatorBufferData = oscillatorBuffer.getWritePointer(0);
        auto* lfoBufferData = lfoBuffer.getWritePointer(0);
        for (int smp = 0; smp < numSamples; ++smp)
        {
            getNextAudioSample(lfoBufferData[smp]);
            oscillatorBufferData[smp] = sampleValue;
        }
    
    }

    void getNextAudioSample(float lfoSmp)
    {
        sampleValue = sin(2.0f * float_Pi * normalizedPhaseValue);
        
        //computation of the the frequency value appling the frequency modulation by the lfo
        float freqValue = 440.0f * std::pow(2.0, (frequency.getNextValue() + lfoSmp - 69.0f) / 12.0f);
        const float phaseIncrement = freqValue / sampleRate;
        
        //updating the phase value
        normalizedPhaseValue += phaseIncrement;
        normalizedPhaseValue -= static_cast<int>(normalizedPhaseValue);
    }

private:
    void parameterChanged(const String& paramID, float newValue) override
    {
        if (paramID == NAME_FREQ)
            frequency.setTargetValue(newValue);
    }

    double sampleRate = 1.0;
    
    float sampleValue = 0.0;
    
    float normalizedPhaseValue = 0.0f;
    
    SmoothedValue<float, ValueSmoothingTypes::Multiplicative> frequency;
    
    
    
};
