/*------------------------ Setup instructions -----------------------------*/

/* ----reduce latency instructions ------ */
s.quit;
s.options.blockSize = 1024;
s.options.numBuffers = 64;
s.options.numWireBufs = 128;
s.options.hardwareBufferSize = 2048;

s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;
s.options.memSize = 8192;
s.options.sampleRate = 48000;
s.latency = 0;

s.boot;

/*------------------------ Stop everything -----------------------------*/
Server.killAll;

/*----------------------- Choice of song --------------------------------*/
//audio files have to be placed into wav folder in order to work with processing too.

(
~selectedpath = "/Users/filippo/Library/CloudStorage/OneDrive-PolitecnicodiMilano/Corsi/Computer Music - Languages and Systems 💽/Progetto/CMLS-2024/wav/test.wav";
~buf = Buffer.readChannel(s, ~selectedpath, channels:[0]);
)

// buffer testing instruction
~buf.play;
~buf.numChannels;

/*----------------------- Busses -------------------------------------------*/
~audioBus = Bus.audio(s,2);
~audioBus.scope;

/*-------------- use of a plugin written in juce (ring modulator / reverb) --------*/
VSTPlugin.search;

(
SynthDef(\vstPlugin,{
	arg in,out;
	var sig;

	sig = In.ar(in,2);
	sig = VSTPlugin.ar(sig,2);
	ReplaceOut.ar(out, sig);
}).add;
)

~vstSynth = Synth(\vstPlugin,[\in,~audioBus,\out,0]);
~plugin = VSTPluginController(~vstSynth).open("TheOneRing.vst3", verbose:true);

/*---------------------- SynthDef granulator -------------------------------*/

/*-- Parameter ranges -- */

// dens -> (5,25)
// index (selection of the trigger type)-> 0 -> Dust  1-> Impulse
// grainDur (grain size in seconds) -> (0.80,3)
// durRand (randomness linked to duration) -> (1,2)
// semitons (semitone difference compared to the original pitch) -> (-24,+24)
// curPos -> (0,1)
// varRand (randomness linked to position) -> (0,1)
// panRate (rate of pan lfo in Hz, 0 is off)-> (0,20)
// panPos (it's the add passed to pan) -> (-1,1)
// panAmt (level of pan lfo, 0 is off) -> (0,1)
// atk, decay, sus, rel (values ​​for creating the envelope)
// amp (out volume of signal) -> (0,1)

(
SynthDef.new(\granulator, {

	arg buf,out,
	dens=10, index = 1,
	grainDur=1, durRand=1,
	semitons=0,
	curPos = 0, varRand = 0,
	panRate = 0, panPos = 0, panAmt = 0,
	atk=2, decay=0.1, sus=1, rel=2,
	amp=0;

	var sig;

	var trigger = Select.ar(index, [Dust.ar(dens), Impulse.ar(dens)]);
	var len = grainDur * LFNoise1.kr(100).range(1/durRand, durRand);
	var rate = semitons.midiratio;
	var position = (curPos + LFNoise1.kr(100).range((varRand.neg)/2, varRand/2)) % (1);
	var env = EnvGen.ar(Env.adsr(atk, decay, sus, rel));

	var pan = SinOsc.ar(freq: panRate, phase: 0.0, mul: panAmt, add: panPos);

	sig = GrainBuf.ar(
		2,
		trigger,
		len,
		buf,
		rate,
		position,
		2,
		pan,
		-1,
		512,
		1,
		0,
	);

	sig = sig * env * amp;
	Out.ar(out, sig);

}).add;
)

//----- let's play! ------*/
~granulator = Synth(\granulator,[\buf,~buf ,\out,~audioBus]);
~granulator.free;


/*------------------------------- Midi connection -----------------------------------*/

/*----- Setup ------- */
MIDIClient.init;
MIDIIn.connectAll;

(
~noteOn = {arg src, chan, num, vel;
	~granulator.set(\semitons, num/4.0);
};
MIDIIn.addFuncTo(\noteOn, ~noteOn);
)

/*------- stop the connection -------*/
MIDIIn.removeFuncFrom(\noteOn, ~noteOn);
MIDIIn.disconnectAll;


/*----------------------------- Processing connection --------------------------------*/
~addrsend = NetAddr.new("127.0.0.1", 12000);

/*---- sensor management --- */
~arduino1 = 1; //random position, trigger
~arduino2 = 1; //volume
~midi = 1; //pitch

(
~controlConnected = Routine.new({
	{
		~addrsend.sendMsg("/sensors", ~arduino1, ~arduino2, ~midi);
		0.01.wait;
	}.loop;
}).play;
)

/*---- waveform management --- */
(
~patharray = ~selectedpath.split($\/);
~path = ~patharray[~patharray.size-1];
~addrsend.sendMsg("/filepath", ~path);
)


/*---- synth and effects management --- */

NetAddr.localAddr;

(
OSCdef(\parameters_synth,
	{
		arg msg;

		var p1 = msg[1];
		var p2 = msg[2];
		var p3 = msg[3];
		var p4 = msg[4];
		var p5 = msg[5];
		var p6 = msg[6];
		var p7 = msg[7];
		var p8 = msg[8];
		var p9 = msg[9];
		var p10 = msg[10];
		var p11 = msg[11];

		postln("density"+p1+ "duration" +p2 + "durRand" + p3);
		postln("rate"+p4+ "position" +p5 + "posRand" + p6);
		postln("amp" +p7 + "trigger" + p8);
		postln("panPos"+p9 + "panRate" +p10 + "panAmt" +p11 );

		~granulator.set(\dens, p1);
		~granulator.set(\grainDur, p2);
		~granulator.set(\durRand, p3 +1);
		if(~midi == 0,{
			~granulator.set(\semitons, p4/4.0);
		});
		~granulator.set(\curPos, p5/100);
		if(~arduino1 == 0,{
			~granulator.set(\varRand, p6/100);
		});
		if(~arduino2 == 0,{
			~granulator.set(\amp, p7/100);
		});
		if(~arduino1 == 0,{
			~granulator.set(\index, p8);
		});
		~granulator.set(\panPos, p9);
		~granulator.set(\panRate, p10);
		~granulator.set(\panAmt, p11/100);
	},
	"/parameters_synth");
)

(
OSCdef(\parameters_fx,
	{
		arg msg;

		var p1 = msg[1];
		var p2 = msg[2];
		var p3 = msg[3];
		var p4 = msg[4];
		var p5 = msg[5];
		var p6 = msg[6];
		var p7 = msg[7];
		var p8 = msg[8];
		var p9 = msg[9];
		var p10 = msg[10];

		var modemap = Dictionary.new;
		var freezemap = Dictionary.new;

		modemap.putPairs([0.0, "Sine", 1.0, "Step squared", 2.0, "Squared", 3.0, "Random", 4.0, "Envelope Follower"]);
		freezemap.putPairs([false, 0, true, 1]); //freeze di default: false


		postln("Rate"+p1+ "Frequency" +p2 + "Mode" + modemap.at(p3));
		postln("Width"+p4+ "Blend" +p5 + "Room_size" + p6);
		postln("Damping"+p7 + "Reverb_Dry" +p8+ "" +"Reverb_width"+p9);
		postln("Freeze_mode"+p10);



		~plugin.set(\Rate, p1);
		~plugin.set(\Frequency, p2);
		~plugin.set(\Mode, modemap.at(p3));
		~plugin.set(\Width, p4);
		~plugin.set(\Blend, p5);
		~plugin.set(\Room_size, p6);
		~plugin.set(\Damping, p7);
		~plugin.set(\Reverb_Dry_Wet, p8);
		~plugin.set(\Reverb_width, p9);
		~plugin.set(\Freeze_mode, freezemap.at(p10));
	},
	"/parameters_fx");
)


/* ---------------------------------- Arduino connection ----------------------------- */

/*---- setup -------*/
SerialPort.devices;
~port1 = SerialPort.new("/dev/tty.usbmodem1401", 9600);
~port2 = SerialPort.new("/dev/tty.usbmodem1201", 9600);


/* ------ getting values from ~port1 -------*/
~intArray = [];
(
~getValues1 = Routine.new({
	var ascii;
	{
		ascii = ~port1.read.asAscii;
		if(ascii.isDecDigit,
			{~intArray = ~intArray.add(ascii)},
			{
				~pot = ~intArray.collect(_.digit).convertDigits;
				~intArray = [];
				if(ascii == $L,{
					~touch = 0;
				},{
					~touch = 1;
				});
			}
		);
	}.loop;

}).play;
)


/* ------ getting values from ~port2 -------*/
~floatArray = [];
(
~getValues2 = Routine.new({
	var ascii;
	{
		ascii = ~port2.read.asAscii;
		if(ascii.isDecDigit,
			{~floatArray = ~floatArray.add(ascii)},
			{
				~breath = ~floatArray.collect(_.digit).convertDigits;
				~floatArray = [];

			}
		);
	}.loop;

}).play;
)

/*---- setting values ----- */

(
~controlValues = Routine.new({
	{
		if ((~arduino1 == 1), {
			~granulator.set(\varRand, ~pot/1023);
			~granulator.set(\index, ~touch);
			~addrsend.sendMsg("/arduino1Update", ~pot/10.23, ~touch);
		});

		if ((~arduino2 == 1), {
			~granulator.set(\amp, ~breath/100);
			~addrsend.sendMsg("/arduino2Update", ~breath);
		});

		0.01.wait;
	}.loop;
}).play;
)


/*------- stop the connection -------*/
~getValues1.stop;
~getValues2.stop;
~controlConnected.stop;
~controlValues.stop;
~port1.close;
~port2.close;