import oscP5.*;
import netP5.*;
import controlP5.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.spi.*;
import java.util.Arrays;

OscP5 oscP5;
NetAddress remoteLocation;
ControlP5 cP5;
Minim minim;
AudioSample sound;

//public variables
public color mainColor = #eaeaea;
public color secondColor = #ffc966;
public color thirdColor = #bfffff;

public color knob1_fore = #000000;
public color knob1_back = #c7c7c7;
public color knob1_active = #ffffff;

public color knob2_fore = #000000;
public color knob2_back = #c7c7c7;
public color knob2_active = #ffd700;

public color knob3_fore = #000000;
public color knob3_back = #c7c7c7;
public color knob3_active = #66cccc;

public float[][] spectra;
public float norm;

public int arduino1;
public int arduino2;
public int midi;
public float pot;
public int touch;
public int breath;
public int pitch;

public PImage ring;
public String filepath;


//granulizer, ring modulator and reverb params
Knob gran_panamt;
Knob gran_panfreq;
Knob gran_pan;
Knob gran_density;
Knob gran_duration;
Knob gran_durrand;
Knob gran_pitch;
Knob gran_randpos;
Knob gran_db;
Slider gran_position;
Toggle gran_trigger;

Knob ringo_freq;
Knob ringo_modrate;
Knob ringo_blend;
Knob ringo_width;
DropdownList ringo_lfomode;

Knob rev_roomsize;
Knob rev_damping;
Knob rev_width;
Knob rev_drywet;
Toggle rev_freeze;

//granulizer, ring modulator and reverb variables
float g_panamt;
float g_panfreq;
float g_pan;
int g_density;
float g_duration;
float g_durrand;
int g_pitch;
float g_randpos;
int g_db;
float g_position;
int g_trigger;

float ri_freq;
float ri_modrate;
float ri_blend;
float ri_width;
float ri_lfomode;

float re_roomsize;
float re_damping;
float re_width;
float re_drywet;
boolean re_freeze;


void setup(){
  
  size(1000, 800); 
  frameRate(125);
  stroke(#000000);
  
  oscP5 = new OscP5(this, 12000);
  remoteLocation = new NetAddress("127.0.0.1", 57120);
  cP5 = new ControlP5(this);
  minim  = new Minim(this);
  
  ring = loadImage("img_blackring.png");
  ring.resize(700,700);
  
  initControls();
}

void initControls() {
  
  //-- Initializes GUI Controls 

  //Granulizer Controls 
  
  gran_pan = cP5.addKnob("g_pan")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(150,50)
    .setRadius(50)
    .setRange(-1,1)
    .setValue(0)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("pan") 
    ;
    
  gran_panamt = cP5.addKnob("g_panamt")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(50,175)
    .setRadius(50)
    .setRange(0,100)
    .setValue(0)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("pan\namount") 
    ;
    
  gran_panfreq = cP5.addKnob("g_panfreq")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(150,300)
    .setRadius(50)
    .setRange(0,20)
    .setValue(0)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("pan rate") 
    ;
  
  gran_density = cP5.addKnob("g_density")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(360,100)
    .setRadius(40)
    .setRange(5,25)
    .setValue(10)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("density") 
    ;
  
  gran_duration = cP5.addKnob("g_duration")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(460,100)
    .setRadius(40)
    .setRange(0.80,3)
    .setValue(1) 
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("duration") 
    ;
  
  gran_durrand = cP5.addKnob("g_durrand")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(560,100)
    .setRadius(40)
    .setRange(0,1)
    .setValue(0) 
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) //colore label text
    .setColorValue(knob1_fore) //colore label value
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("random\nduration") 
    ;
    
  gran_pitch = cP5.addKnob("g_pitch")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(750,50)
    .setRadius(50)
    .setRange(-24,24)
    .setValue(0)
    .setNumberOfTickMarks(48)
    .setTickMarkLength(8)
    .snapToTickMarks(true)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) 
    .setColorValue(knob1_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("pitch")
    ;
    
  gran_randpos = cP5.addKnob("g_randpos")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(750,300)
    .setRadius(50)
    .setRange(0,100)
    .setValue(0)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore)
    .setColorValue(knob1_fore)
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("random\nposition") 
    ;
    
  gran_db = cP5.addKnob("g_db")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(850,175)
    .setRadius(50)
    .setRange(0,100)
    .setValue(50)
    .setColorForeground(knob1_fore)
    .setColorBackground(knob1_back)
    .setColorActive(knob1_active)
    .setColorLabel(knob1_fore) 
    .setColorValue(knob1_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("volume") 
    ;
    
  gran_position = cP5.addSlider("g_position")
   .setFont(createFont("halfelven.ttf", 15))
   .setRange(0,100)
   .setValue(0)
   .setPosition(300,400)
   .setSize(400,10)
   .setSliderMode(Slider.FLEXIBLE)
   .setColorForeground(knob1_fore)
   .setColorBackground(knob1_back)
   .setColorActive(knob1_active)
   .setColorLabel(knob1_active) 
   .setColorValue(knob1_fore) 
   .setCaptionLabel("")
   ;
     
  gran_trigger = cP5.addToggle("g_trigger")
   .setFont(createFont("halfelven.ttf", 18))
   .setPosition(40,50)
   .setSize(50,20)
   .setValue(true) 
   .setMode(ControlP5.SWITCH)
   .setColorForeground(knob1_fore)
   .setColorBackground(knob1_back)
   .setColorActive(knob1_fore)
   .setColorLabel(knob1_fore) 
   .setColorValue(knob1_fore) 
   .setCaptionLabel("trigger")
   ;
    
  //Ringo Modulator Controls
  
  ringo_freq = cP5.addKnob("ri_freq")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(50,500)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob2_fore)
    .setColorBackground(knob2_back)
    .setColorActive(knob2_active)
    .setColorLabel(knob2_fore) 
    .setColorValue(knob2_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("frequency") 
    ;
    
  ringo_modrate = cP5.addKnob("ri_modrate")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(120,650)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob2_fore)
    .setColorBackground(knob2_back)
    .setColorActive(knob2_active)
    .setColorLabel(knob2_fore) 
    .setColorValue(knob2_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("modulation\nrate") 
    ;
    
  ringo_blend = cP5.addKnob("ri_blend")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(455,500)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob2_fore)
    .setColorBackground(knob2_back)
    .setColorActive(knob2_active)
    .setColorLabel(knob2_fore) 
    .setColorValue(knob2_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("blend") 
    ;
    
  ringo_width = cP5.addKnob("ri_width")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(400,650)
    .setRadius(45)
    .setRange(0,100)
    .setValue(0)
    .setColorForeground(knob2_fore)
    .setColorBackground(knob2_back)
    .setColorActive(knob2_active)
    .setColorLabel(knob2_fore) 
    .setColorValue(knob2_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("ring\nwidth") 
    ;
    
  ringo_lfomode = cP5.addDropdownList("ri_lfomode")
      .setPosition(230,590)
      .setSize(150,100)
      .setBarHeight(20)
      .setItemHeight(20)
      .setColorBackground(knob2_back)
      .setColorActive(knob2_active)
      .setColorForeground(knob2_fore)
      .setOpen(false)
      .addItems(new String[]{"Sine", "Step squared", "Squared", "Random", "Envelope Follower"})
      .setCaptionLabel("Mode")
      .setValue(0);
  
  //Reverb Controls

  rev_roomsize = cP5.addKnob("re_roomsize")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(630,500)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob3_fore)
    .setColorBackground(knob3_back)
    .setColorActive(knob3_active)
    .setColorLabel(knob3_fore) 
    .setColorValue(knob3_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("room\nsize") 
    ;
    
  rev_damping = cP5.addKnob("re_damping")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(630,650)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob3_fore)
    .setColorBackground(knob3_back)
    .setColorActive(knob3_active)
    .setColorLabel(knob3_fore) 
    .setColorValue(knob3_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("damping") 
    ;
    
  rev_width = cP5.addKnob("re_width")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(870,500)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob3_fore)
    .setColorBackground(knob3_back)
    .setColorActive(knob3_active)
    .setColorLabel(knob3_fore) 
    .setColorValue(knob3_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("reverb\nwidth") 
    ;
    
  rev_drywet = cP5.addKnob("re_drywet")
    .setFont(createFont("halfelven.ttf", 18))
    .setPosition(870,650)
    .setRadius(45)
    .setRange(0,1)
    .setValue(0)
    .setColorForeground(knob3_fore)
    .setColorBackground(knob3_back)
    .setColorActive(knob3_active)
    .setColorLabel(knob3_fore) 
    .setColorValue(knob3_fore) 
    .setDragDirection(Knob.VERTICAL)
    .setCaptionLabel("dry/wet") 
    ;
    
  rev_freeze = cP5.addToggle("re_freeze")
     .setFont(createFont("halfelven.ttf", 18))
     .setPosition(770,590)
     .setSize(50,50)
     .setValue(false)
     .setMode(ControlP5.DEFAULT)
     .setColorForeground(knob3_fore)
     .setColorBackground(knob3_back)
     .setColorActive(knob3_active)
     .setColorLabel(knob3_fore) 
     .setColorValue(knob3_fore) 
     .setCaptionLabel("freeze");
}


void draw(){
  background(mainColor);
  stroke(#000000);
  
  //Granulator section
  fill(mainColor);
  rect(0, 0, width, 450);
  textSize(120);
  textFont(createFont("halfelven.ttf", 40));
  fill(0, 0, 0);
  text("Granulator", 387, 60);
  
  //Ringo modulator section
  fill(secondColor);
  rect(0, 450, 600, 350);
  textSize(120);
  textFont(createFont("halfelven.ttf", 30));
  fill(0, 0, 0);
  text("   Ringo\nModulator", 225, 490);
  
  //Reverb section
  fill(thirdColor);
  rect(600, 450, 400, 350);
  textSize(120);
  textFont(createFont("halfelven.ttf", 30));
  fill(0, 0, 0);
  text("Reverb", 740, 490);
  
  imageMode(CENTER);
  tint(255, 20);
  image(ring, 500,400);
  
  
  if (filepath!=null &&  spectra!=null) {
    //--Draws waveform, after the filepath is set via osc message--
    
    stroke(knob1_back);
    fill(mainColor);
    rect(300, 250, 400, 125);
    float scaleMod = (float(400) / float(spectra.length)); //remapping
    
    for(int s = 0; s < spectra.length; s++)
    {
      float total = 0; 
      for(int i = 0; i < spectra[s].length-1; i++)
      {
          total += spectra[s][i];
      }
      total = total/(norm*100)  ; //normalization
      stroke(0);
      line(s*scaleMod+300,total+125/2+250,s*scaleMod+300,-total+125/2+250);
    }
  }
}


void analyzeSample() {
  //--Calculates spectrum to later draw the waveform--
  
  sound = minim.loadSample(filepath, 512);
  float[] leftChannel = sound.getChannel(AudioSample.LEFT);
  norm = max(leftChannel);
  int fftSize = 1024;
  float[] fftSamples = new float[fftSize];
  FFT fft = new FFT(fftSize, sound.sampleRate());
  int totalChunks = (leftChannel.length / fftSize) + 1;
  spectra = new float[totalChunks][fftSize/2];
  for(int chunkIdx = 0; chunkIdx < totalChunks; ++chunkIdx)
  {
    int chunkStartIndex = chunkIdx * fftSize;
    int chunkSize = min( leftChannel.length - chunkStartIndex, fftSize );
    arraycopy( leftChannel, chunkStartIndex, fftSamples, 0, chunkSize);

    if (chunkSize < fftSize) {
      Arrays.fill( fftSamples, chunkSize, fftSamples.length - 1, 0.0 );
    }
    fft.forward( fftSamples );
   
    for(int i = 0; i < 512; ++i) {
      spectra[chunkIdx][i] = fft.getBand(i);
    }
  }
  sound.close(); 
}


void controlEvent(ControlEvent theEvent){
  
  //--Sends Osc messages to SuperCollider--
  
  OscMessage message_synth = new OscMessage("/parameters_synth");
  OscMessage message_fx = new OscMessage("/parameters_fx");
  
  //to granulizer
  message_synth.add(g_density);
  message_synth.add(g_duration);
  message_synth.add(g_durrand);
  message_synth.add(g_pitch);
  message_synth.add(g_position);
  message_synth.add(g_randpos);
  message_synth.add(g_db);
  message_synth.add(g_trigger);
  message_synth.add(g_pan);
  message_synth.add(g_panfreq);
  message_synth.add(g_panamt);
  

  //to ring modulator
  message_fx.add(ri_modrate);
  message_fx.add(ri_freq);
  message_fx.add(ri_lfomode); 
  message_fx.add(ri_width);
  message_fx.add(ri_blend);
  
  //to reverb
  message_fx.add(re_roomsize);
  message_fx.add(re_damping);
  message_fx.add(re_drywet);
  message_fx.add(re_width);
  message_fx.add(re_freeze); 
  
  oscP5.send(message_synth, remoteLocation);
  oscP5.send(message_fx, remoteLocation);
  message_synth.print();
  message_fx.print();
}


void oscEvent(OscMessage theOscMessage) {

      //--Handles incoming Osc messages from SuperCollider--
      
      theOscMessage.print();
       
      if (theOscMessage.checkAddrPattern("/sensors")) {
       arduino1 = theOscMessage.get(0).intValue();
       arduino2 = theOscMessage.get(1).intValue();
       midi = theOscMessage.get(2).intValue();
   
       if (arduino1 != 0) {
         //disable gran_randpos, aka 'random position'
         gran_randpos.setLock(true);
         gran_randpos.setColorForeground(#bdbdbd);
         gran_randpos.setColorBackground(#e3e3e3);
         gran_randpos.setColorActive(#bdbdbd);
         gran_randpos.setColorLabel(#bdbdbd);
         gran_randpos.setColorValue(#bdbdbd);
         
         //disable gran_trigger, aka 'trigger'
         gran_trigger.setLock(true);
         gran_trigger.setColorForeground(#bdbdbd);
         gran_trigger.setColorBackground(#e3e3e3);
         gran_trigger.setColorActive(#bdbdbd);
         gran_trigger.setColorLabel(#bdbdbd);
         gran_trigger.setColorValue(#bdbdbd);
       }
       
       else {
         gran_randpos.setLock(false);
         gran_randpos.setColorForeground(knob1_fore);
         gran_randpos.setColorBackground(knob1_back);
         gran_randpos.setColorActive(knob1_active);
         gran_randpos.setColorLabel(#000000);
         gran_randpos.setColorValue(knob1_fore);
         
         gran_trigger.setLock(false);
         gran_trigger.setColorForeground(knob1_fore);
         gran_trigger.setColorBackground(knob1_back);
         gran_trigger.setColorActive(knob1_fore);
         gran_trigger.setColorLabel(#000000);
         gran_trigger.setColorValue(knob1_fore);
       }
       
       if (arduino2 != 0) {
         //disable gran_db, aka 'volume'
         gran_db.setLock(true);
         gran_db.setColorForeground(#bdbdbd);
         gran_db.setColorBackground(#e3e3e3);
         gran_db.setColorActive(#bdbdbd);
         gran_db.setColorLabel(#bdbdbd);
         gran_db.setColorValue(#bdbdbd);
       }
       
       else {
         gran_db.setLock(false);
         gran_db.setColorForeground(knob1_fore);
         gran_db.setColorBackground(knob1_back);
         gran_db.setColorActive(knob1_active);
         gran_db.setColorLabel(#000000);
         gran_db.setColorValue(knob1_fore);
       }
       
       if (midi != 0) {
         //disable gran_pitch, aka 'pitch'
         gran_pitch.setLock(true);
         gran_pitch.setColorForeground(#bdbdbd);
         gran_pitch.setColorBackground(#e3e3e3);
         gran_pitch.setColorActive(#bdbdbd);
         gran_pitch.setColorLabel(#bdbdbd);
         gran_pitch.setColorValue(#bdbdbd);
       }
       
       else {
         gran_pitch.setLock(false);
         gran_pitch.setColorForeground(knob1_fore);
         gran_pitch.setColorBackground(knob1_back);
         gran_pitch.setColorActive(knob1_active);
         gran_pitch.setColorLabel(#000000);
         gran_pitch.setColorValue(knob1_fore);
       }
     }
     
     else if (theOscMessage.checkAddrPattern("/arduino1Update")) {
       // -- Updates the values shown on relative controls --
       pot = theOscMessage.get(0).floatValue();
       touch = theOscMessage.get(1).intValue();
    
       gran_randpos.setValue(pot);
       gran_trigger.setValue(touch);
     }
 
      else if (theOscMessage.checkAddrPattern("/arduino2Update")) {
       // -- Updates the values shown on relative controls --
       breath = theOscMessage.get(0).intValue();
       
       gran_db.setValue(breath);
     }

      else if (theOscMessage.checkAddrPattern("/filepath")) {
       // -- Assigns the correct path to the variable filepath --
       // -- Calls function to calculate spectra to draw waveform --
       filepath = theOscMessage.get(0).stringValue();
       filepath = "../wav/"+filepath;
       analyzeSample();
      }
 
}
