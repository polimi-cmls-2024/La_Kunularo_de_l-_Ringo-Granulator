#pragma once
#include <JuceHeader.h>

#define DEFAULT_DW  0.0f
#define NAME_DW     "blend"


//The class DryWetter is used to implment the Blend parameter of the ring modulator.
class DryWetter : public AudioProcessorValueTreeState::Listener
{
public:
    DryWetter()
    {
        updateInternalState(DEFAULT_DW);
    }

    ~DryWetter() {};

    void prepareToPlay(const int maxSamplesPerBlock)
    {
        drySignal.setSize(2, maxSamplesPerBlock);
    }

    void releaseResources()
    {
        drySignal.setSize(0, 0);
    }
    
    
    void storeFrom(const AudioBuffer<float>& inputSignal)
    {
        const auto numSamples = inputSignal.getNumSamples();

        for (int ch = inputSignal.getNumChannels(); --ch >= 0;)
            drySignal.copyFrom(ch, 0, inputSignal, ch, 0, numSamples); //copy of the dry signal
    }

    
    void mergeTo(AudioBuffer<float>& outputSignal)
    {
        const auto numSamples = outputSignal.getNumSamples();

        if (doSmooth)
        {
            outputSignal.applyGainRamp(0, numSamples, wetGainOld, wetGain);//we apply a smooth transition when we change the wet parameter

            for (int ch = outputSignal.getNumChannels(); --ch >= 0;)
                outputSignal.addFromWithRamp(ch, 0, drySignal.getReadPointer(ch), numSamples, dryGainOld, dryGain); //generation of the new output signal

            doSmooth = false;
        }
        else
        {
            outputSignal.applyGain(wetGain);

            for (int ch = outputSignal.getNumChannels(); --ch >= 0;)
                outputSignal.addFrom(ch, 0, drySignal, ch, 0, numSamples, dryGain);
        }
    }

private:
    void parameterChanged(const String& paramID, float newValue) override
    {
        if (paramID == NAME_DW)
            updateInternalState(newValue);
    }

    //updating the values when the blend knob is turned
    void updateInternalState(float newValue)
    {
        dryGainOld = dryGain;
        wetGainOld = wetGain;

        dryGain = sqrt(1.0f - newValue);
        wetGain = sqrt(newValue);

        doSmooth = true;
    }
    
    AudioBuffer<float> drySignal;

    float dryGain, dryGainOld;
    float wetGain, wetGainOld;

    bool doSmooth;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(DryWetter)
};
