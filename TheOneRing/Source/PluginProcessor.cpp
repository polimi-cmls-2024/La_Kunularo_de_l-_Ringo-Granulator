
#include "PluginProcessor.h"

//==============================================================================
TheOneRingAudioProcessor::TheOneRingAudioProcessor() :
parameters(*this, nullptr, Identifier("RingWormParameters"), {
        std::make_unique<AudioParameterFloat>(NAME_RATE, "Rate", NormalisableRange<float>(0.1f, 127.0f, 0.1f, 0.5f), DEFAULT_RATE),
        std::make_unique<AudioParameterFloat>(NAME_FREQ, "Frequency", NormalisableRange<float>(0.1f, 127.0f, 0.1f, 0.5f), DEFAULT_FREQ),
        std::make_unique<AudioParameterChoice>(NAME_WF, "Mode", StringArray{ "Sine", "Step squared", "Squared", "Random", "Envelope Follower" }, DEFAULT_WF),
        std::make_unique<AudioParameterFloat>(NAME_WT, "Width", 0.0f, 100.0f, DEFAULT_WT),
        std::make_unique<AudioParameterFloat>(NAME_DW, "Blend", 0.0f, 1.0f, DEFAULT_DW),
        
    
        std::make_unique<AudioParameterFloat>(NAME_RS, "Room_size", 0.0f, 1.0f, DEFAULT_RATE),
        std::make_unique<AudioParameterFloat>(NAME_DM, "Damping", 0.0f, 1.0f, DEFAULT_RATE),
        std::make_unique<AudioParameterFloat>(NAME_RDW, "Reverb_Dry_Wet", 0.0f, 1.0f, DEFAULT_RATE),
        std::make_unique<AudioParameterFloat>(NAME_WR, "Reverb_width", 0.0f, 1.0f, DEFAULT_RATE),
        std::make_unique<AudioParameterFloat>(NAME_FM, "Freeze_mode", 0.0f, 1.0f, DEFAULT_RATE),
        })
{
    parameters.addParameterListener(NAME_RATE, &lfo);
    parameters.addParameterListener(NAME_FREQ, &osc);
    parameters.addParameterListener(NAME_WF, &lfo);
    parameters.addParameterListener(NAME_DW, &dryWet);
    parameters.addParameterListener(NAME_WT, this);
    
    parameters.addParameterListener(NAME_RS, this);
    parameters.addParameterListener(NAME_DM, this);
    parameters.addParameterListener(NAME_RDW, this);
    parameters.addParameterListener(NAME_WR, this);
    parameters.addParameterListener(NAME_FM, this);
    
    width.setCurrentAndTargetValue(DEFAULT_DW);
}

TheOneRingAudioProcessor::~TheOneRingAudioProcessor()
{
}


void TheOneRingAudioProcessor::parameterChanged(const String& paramID, float newValue)
{
    if (paramID == NAME_WT)
        width.setTargetValue(newValue);
    
    else if (paramID == NAME_RS)
        roomSize = newValue;
    else if (paramID == NAME_DM)
        damping = newValue;
    else if (paramID == NAME_RDW)
        ReverdDryWet = newValue;
    else if (paramID == NAME_WR)
        reverbWidth = newValue;
    else if (paramID == NAME_FM)
        freezeMode = newValue;
}
//==============================================================================
const juce::String TheOneRingAudioProcessor::getName() const
{
    return JucePlugin_Name;
}

bool TheOneRingAudioProcessor::acceptsMidi() const
{
   #if JucePlugin_WantsMidiInput
    return true;
   #else
    return false;
   #endif
}

bool TheOneRingAudioProcessor::producesMidi() const
{
   #if JucePlugin_ProducesMidiOutput
    return true;
   #else
    return false;
   #endif
}

bool TheOneRingAudioProcessor::isMidiEffect() const
{
   #if JucePlugin_IsMidiEffect
    return true;
   #else
    return false;
   #endif
}

double TheOneRingAudioProcessor::getTailLengthSeconds() const
{
    return 0.0;
}

int TheOneRingAudioProcessor::getNumPrograms()
{
    return 1;   // NB: some hosts don't cope very well if you tell them there are 0 programs,
                // so this should be at least 1, even if you're not really implementing programs.
}

int TheOneRingAudioProcessor::getCurrentProgram()
{
    return 0;
}

void TheOneRingAudioProcessor::setCurrentProgram (int index)
{
}

const juce::String TheOneRingAudioProcessor::getProgramName (int index)
{
    return {};
}

void TheOneRingAudioProcessor::changeProgramName (int index, const juce::String& newName)
{
}

//==============================================================================
void TheOneRingAudioProcessor::prepareToPlay (double sampleRate, int samplesPerBlock)
{
    
    lfo.prepareToPlay(sampleRate, samplesPerBlock);
    osc.prepareToPlay(sampleRate, samplesPerBlock);
    dryWet.prepareToPlay(samplesPerBlock);
    
    
    lfoBuffer.setSize(1, samplesPerBlock);
    modulator.setSize(1, samplesPerBlock);
    
    
    width.reset(sampleRate, RATE_SMTH);
    
    
}

void TheOneRingAudioProcessor::releaseResources()
{
    lfoBuffer.setSize(0, 0);
    modulator.setSize(0, 0);
    dryWet.releaseResources();
    
}

#ifndef JucePlugin_PreferredChannelConfigurations
bool TheOneRingAudioProcessor::isBusesLayoutSupported (const BusesLayout& layouts) const
{
  #if JucePlugin_IsMidiEffect
    juce::ignoreUnused (layouts);
    return true;
  #else
    // This is the place where you check if the layout is supported.
    // In this template code we only support mono or stereo.
    // Some plugin hosts, such as certain GarageBand versions, will only
    // load plugins that support stereo bus layouts.
    if (layouts.getMainOutputChannelSet() != juce::AudioChannelSet::mono()
     && layouts.getMainOutputChannelSet() != juce::AudioChannelSet::stereo())
        return false;

    // This checks if the input layout matches the output layout
   #if ! JucePlugin_IsSynth
    if (layouts.getMainOutputChannelSet() != layouts.getMainInputChannelSet())
        return false;
   #endif

    return true;
  #endif
}
#endif

void TheOneRingAudioProcessor::processBlock (juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;

    const auto numSamples = buffer.getNumSamples();
    
    dryWet.storeFrom(buffer);
    
    lfo.getNextAudioBlock(buffer, lfoBuffer, numSamples);
    
    widthLfoModulation(numSamples);
    
    osc.getNextAudioBlock(lfoBuffer, modulator, numSamples);
    
    ApplyRingModulation(buffer, numSamples);
    
    dryWet.mergeTo(buffer);
    
    //Reverb
    ApplyReverberation(buffer, numSamples);
    
    
}
//appling width to the lfo buffer
void TheOneRingAudioProcessor::widthLfoModulation(int numSamples)
{
    auto* lfoBufferData = lfoBuffer.getArrayOfWritePointers();
    
    FloatVectorOperations::add(lfoBufferData[0], 1.0f, numSamples);
    FloatVectorOperations::multiply(lfoBufferData[0], 0.5f, numSamples);
    width.applyGain(lfoBufferData[0], numSamples);
}

//appling the ring modulation to the buffer input
void TheOneRingAudioProcessor::ApplyRingModulation(AudioBuffer<float>& buffer, int numSamples)
{
    const auto numChannels = buffer.getNumChannels();
    auto* bufferData = buffer.getArrayOfWritePointers();
    auto* modulatorData = modulator.getArrayOfReadPointers();
    
    for (int ch = 0; ch < numChannels; ++ch)
    {
        FloatVectorOperations::multiply(bufferData[ch], modulatorData[0], numSamples);
    }
}

//appling the reverb to the buffer input 
void TheOneRingAudioProcessor::ApplyReverberation(AudioBuffer<float>& buffer, int numSamples)
{
    
    reverbParams.roomSize = roomSize;
    reverbParams.damping = damping;
    reverbParams.wetLevel = ReverdDryWet;
    reverbParams.dryLevel = 1 - ReverdDryWet;
    reverbParams.width = reverbWidth;
    reverbParams.freezeMode = freezeMode;
    
    reverbEffect.setParameters(reverbParams);
    
    auto* bufferData = buffer.getArrayOfWritePointers();
    
    reverbEffect.processStereo(bufferData[0], bufferData[1], numSamples);
}


//==============================================================================
//we manage the editor part totally with Processing
bool TheOneRingAudioProcessor::hasEditor() const
{
    //return true; // (change this to false if you choose not to apply an editor)
    return false;
}

juce::AudioProcessorEditor* TheOneRingAudioProcessor::createEditor()
{
    //return new PluginEditorGui (*this, parameters);
    return nullptr;
}

//==============================================================================
void TheOneRingAudioProcessor::getStateInformation (juce::MemoryBlock& destData)
{
    // You should use this method to store your parameters in the memory block.
    // You could do that either as raw data, or use the XML or ValueTree classes
    // as intermediaries to make it easy to save and load complex data.
}

void TheOneRingAudioProcessor::setStateInformation (const void* data, int sizeInBytes)
{
    // You should use this method to restore your parameters from this memory block,
    // whose contents will have been created by the getStateInformation() call.
}

//==============================================================================
// This creates new instances of the plugin..
juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new TheOneRingAudioProcessor();
}
