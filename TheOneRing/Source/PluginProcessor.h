
#pragma once

#include <JuceHeader.h>
#include "Oscillator.h"
#include "LfoOscillator.h"
#include "DryWet.h"



#define DEFAULT_WT  0.0f
#define NAME_WT    "width"

//reverb paraeters' name
#define NAME_RS "Room_size"
#define NAME_DM "Damping"

#define NAME_WR "Reverb_width"
#define NAME_FM "Freeze_mode"

#define NAME_RDW "Reverb_Dry_Wet"


//==============================================================================
/**
*/
class TheOneRingAudioProcessor  : public juce::AudioProcessor, public AudioProcessorValueTreeState::Listener
{
public:
    //==============================================================================
    TheOneRingAudioProcessor();
    ~TheOneRingAudioProcessor() override;

    //==============================================================================
    void prepareToPlay (double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

   #ifndef JucePlugin_PreferredChannelConfigurations
    bool isBusesLayoutSupported (const BusesLayout& layouts) const override;
   #endif

    void processBlock (juce::AudioBuffer<float>&, juce::MidiBuffer&) override;

    //==============================================================================
    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    //==============================================================================
    const juce::String getName() const override;

    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    //==============================================================================
    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram (int index) override;
    const juce::String getProgramName (int index) override;
    void changeProgramName (int index, const juce::String& newName) override;

    //==============================================================================
    void getStateInformation (juce::MemoryBlock& destData) override;
    void setStateInformation (const void* data, int sizeInBytes) override;
    
    
    
private:
    
    void parameterChanged(const String& paramID, float newValue) override;
    
    void widthLfoModulation(int numSamples);
    
    void ApplyRingModulation(AudioBuffer<float>& buffer, int numSamples);
    
    void ApplyReverberation(AudioBuffer<float>& buffer, int numSamples);
    
    AudioProcessorValueTreeState parameters;
    
    NaiveOscillator lfo;
    
    RingModOscillator osc;
    
    AudioBuffer<float> lfoBuffer;
    
    AudioBuffer<float> modulator;
    
    SmoothedValue<float, ValueSmoothingTypes::Linear> width;
    
    DryWetter dryWet;
    
    
    //Reverb
    Reverb reverbEffect;
    
    Reverb::Parameters reverbParams;

    float roomSize;
    float damping;
    float reverbWidth;
    float freezeMode;
    
    float ReverdDryWet;
    
    //==============================================================================
    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR (TheOneRingAudioProcessor)
};
