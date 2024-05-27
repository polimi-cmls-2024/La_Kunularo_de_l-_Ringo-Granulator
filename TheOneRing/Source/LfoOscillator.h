#pragma once
#include <JuceHeader.h>



#define NAME_RATE      "rate"
#define DEFAULT_RATE   50.0f  //lfo frequency
#define RATE_SMTH      0.05f


#define NAME_WF        "waveform"
#define DEFAULT_WF     0


#define TGT_LVL          0.36f // 1/e the target level


//The class NaiveOscillator creates an lfo (low frequency oscillator) that is used to modulate the oscillator in frequency. The peculiarity of this class is the implementation of different waveforms: sinusoid, step sinusoid, square wave, random and envelope follower.

class NaiveOscillator : public AudioProcessorValueTreeState::Listener
{
public:
    NaiveOscillator()
    {
        frequency.setCurrentAndTargetValue(DEFAULT_RATE);
    }

    ~NaiveOscillator() {};

    void prepareToPlay(double sr, const int maxSamplesPerBlock)
    {
        sampleRate = sr;
        frequency.reset(sr, RATE_SMTH);
    }

    void getNextAudioBlock(AudioBuffer<float>& bufferInput, AudioBuffer<float>& lfoBuffer, const int numSamples)
    {
        auto* bufferInputData = bufferInput.getWritePointer(0);
        auto* lfoBufferData = lfoBuffer.getWritePointer(0);
        
        for (int smp = 0; smp < numSamples; ++smp)
        {
            getNextAudioSample(bufferInputData[smp]);
            lfoBufferData[smp] = sampleValue;
        }
    
    }

    void getNextAudioSample(float smp)
    {
        
        switch (waveform)
        {
            case 0: //sinusoid
                sampleValue = (sin(2.0f * float_Pi * normalizedPhaseValue)/2.0f)+0.5f;
                
                break;
            case 1: { //step sinusoid
                auto triang = round((2.0f *abs(normalizedPhaseValue - 0.5f)) * 5.0f);
                sampleValue = triang / 5.0f;
                break;
            };
            case 2: //square wave
                sampleValue = (((normalizedPhaseValue > 0.5) - (normalizedPhaseValue < 0.5))/2.0f) + 0.5f;
                break;
            case 3: { //we implement an lfo of random samples
                if(oldNormalizedPhaseValue > normalizedPhaseValue)
                {
                    sampleValue = rand.nextFloat();
                }
                break;
            };
            case 4:{ //envelope follower
                float frequencyValue = 440.0f * std::pow(2.0,(frequency.getCurrentValue() - 69.0f) / 12.0f);
                sampleValue = envelopeFollowerSampleValue(smp, frequencyValue); 
               
                break;
            }
            default:
                sampleValue = 0.0f;
        }
        
        const float phaseIncrement = frequency.getNextValue() / sampleRate;
        
        oldNormalizedPhaseValue = normalizedPhaseValue;
        normalizedPhaseValue += phaseIncrement;
        normalizedPhaseValue -= static_cast<int>(normalizedPhaseValue);
    }

    
private:
    void parameterChanged(const String& paramID, float newValue) override
    {
        
        if (paramID == NAME_RATE)
            frequency.setTargetValue(newValue);
            
        
        if (paramID == NAME_WF)
            waveform = roundToInt(newValue);
    
    }
    
    
    float envelopeFollowerSampleValue(float sampleValue, float freq)
    {
        updateAlpha(freq);
        
        //we compute the max between the current sample value and the decayed one in order to allow the envelope to follow the peaks of the signal. In fact when the sample value is higher than the envelope, we update the envelope value to the peak value, otherwise we upgrade the value to the decayed one.
        envelopeValue = jmax(sampleValue, envelopeValue * alpha);
        return envelopeValue;
        
    }
    
    //alpha is the decay factor, the higher aplha is the slower the decay is.
    void updateAlpha(float freq)
    {
        float release = 1.0f / freq; //release time
        const float n = jmax(1.0f, (float)(release * sampleRate)); // release time in samples
        alpha = pow(TGT_LVL, 1.0f / n); //alpha depends on the target level, in our case the 36% of the signal value, and the number of samples n, used to reach the target.
    }
    
    int waveform = DEFAULT_WF;
    
    double sampleRate = 1.0;
    
    float sampleValue = 0.0;
    
    
    
    float normalizedPhaseValue = 0.0f;
    float oldNormalizedPhaseValue = 0.0f;
    
    SmoothedValue<float, ValueSmoothingTypes::Multiplicative> frequency;
    
    Random rand;
    
    //envelope follower parameters
    float envelopeValue = 0.0f;
    float alpha;
};
