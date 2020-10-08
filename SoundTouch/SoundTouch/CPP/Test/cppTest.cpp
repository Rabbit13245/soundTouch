#include <iostream>
#include <fstream>
#include <stdexcept>
#include <stdio.h>
#include <string.h>
#include <time.h>

#include "cppTest.hpp"
#include "../SoundStretchPort/RunParameters.h"
#include "../SoundStretchPort/WavFile.h"
#include "../include/SoundTouch.h"
#include "../include/BPMDetect.h"

// Processing chunk size (size chosen to be divisible by 2, 4, 6, 8, 10, 12, 14, 16 channels ...)
#define BUFF_SIZE           6720

#if _WIN32
    #include <io.h>
    #include <fcntl.h>

    // Macro for Win32 standard input/output stream support: Sets a file stream into binary mode
    #define SET_STREAM_TO_BIN_MODE(f) (_setmode(_fileno(f), _O_BINARY))
#else
    // Not needed for GNU environment...
    #define SET_STREAM_TO_BIN_MODE(f) {}
#endif

void cppTest::hello_world_cpp(){
    std::cout << "Hello from c++" << std::endl;
}

int cppTest::sum_cpp(int a, int b){
    return a + b;
}

void openFiles(WavInFile **inFile, WavOutFile **outFile, const RunParameters *params)
{
    int bits, samplerate, channels;

    if (strcmp(params->inFileName, "stdin") == 0)
    {
        // used 'stdin' as input file
        SET_STREAM_TO_BIN_MODE(stdin);
        *inFile = new WavInFile(stdin);
    }
    else
    {
        // open input file...
        *inFile = new WavInFile(params->inFileName);
    }

    // ... open output file with same sound parameters
    bits = (int)(*inFile)->getNumBits();
    samplerate = (int)(*inFile)->getSampleRate();
    channels = (int)(*inFile)->getNumChannels();

    if (params->outFileName)
    {
        if (strcmp(params->outFileName, "stdout") == 0)
        {
            SET_STREAM_TO_BIN_MODE(stdout);
            *outFile = new WavOutFile(stdout, samplerate, bits, channels);
        }
        else
        {
            *outFile = new WavOutFile(params->outFileName, samplerate, bits, channels);
        }
    }
    else
    {
        *outFile = NULL;
    }
}

void detectBPM(WavInFile *inFile, RunParameters *params)
{
    float bpmValue;
    int nChannels;
    soundtouch::BPMDetect bpm(inFile->getNumChannels(), inFile->getSampleRate());
    soundtouch::SAMPLETYPE sampleBuffer[BUFF_SIZE];

    // detect bpm rate
    fprintf(stderr, "Detecting BPM rate...");
    fflush(stderr);

    nChannels = (int)inFile->getNumChannels();
    int readSize = BUFF_SIZE - BUFF_SIZE % nChannels;   // round read size down to multiple of num.channels

    // Process the 'inFile' in small blocks, repeat until whole file has
    // been processed
    while (inFile->eof() == 0)
    {
        int num, samples;

        // Read sample data from input file
        num = inFile->read(sampleBuffer, readSize);

        // Enter the new samples to the bpm analyzer class
        samples = num / nChannels;
        bpm.inputSamples(sampleBuffer, samples);
    }

    // Now the whole song data has been analyzed. Read the resulting bpm.
    bpmValue = bpm.getBpm();
    fprintf(stderr, "Done!\n");

    // rewind the file after bpm detection
    inFile->rewind();

    if (bpmValue > 0)
    {
        fprintf(stderr, "Detected BPM rate %.1f\n\n", bpmValue);
    }
    else
    {
        fprintf(stderr, "Couldn't detect BPM rate.\n\n");
        return;
    }

    if (params->goalBPM > 0)
    {
        // adjust tempo to given bpm
        params->tempoDelta = (params->goalBPM / bpmValue - 1.0f) * 100.0f;
        fprintf(stderr, "The file will be converted to %.1f BPM\n\n", params->goalBPM);
    }
}

void process(soundtouch::SoundTouch *pSoundTouch, WavInFile *inFile, WavOutFile *outFile)
{
    int nSamples;
    int nChannels;
    int buffSizeSamples;
    soundtouch::SAMPLETYPE sampleBuffer[BUFF_SIZE];

    if ((inFile == NULL) || (outFile == NULL)){
        std::cout << "(inFile == NULL) || (outFile == NULL)" << std::endl;
        return;
    };  // nothing to do.

    nChannels = (int)inFile->getNumChannels();
    assert(nChannels > 0);
    buffSizeSamples = BUFF_SIZE / nChannels;

    // Process samples read from the input file
    while (inFile->eof() == 0)
    {
        int num;

        // Read a chunk of samples from the input file
        num = inFile->read(sampleBuffer, BUFF_SIZE);
        nSamples = num / (int)inFile->getNumChannels();

        // Feed the samples into SoundTouch processor
        pSoundTouch->putSamples(sampleBuffer, nSamples);

        // Read ready samples from SoundTouch processor & write them output file.
        // NOTES:
        // - 'receiveSamples' doesn't necessarily return any samples at all
        //   during some rounds!
        // - On the other hand, during some round 'receiveSamples' may have more
        //   ready samples than would fit into 'sampleBuffer', and for this reason
        //   the 'receiveSamples' call is iterated for as many times as it
        //   outputs samples.
        do
        {
            nSamples = pSoundTouch->receiveSamples(sampleBuffer, buffSizeSamples);
            outFile->write(sampleBuffer, nSamples * nChannels);
        } while (nSamples != 0);
    }
    
    // Now the input file is processed, yet 'flush' few last samples that are
    // hiding in the SoundTouch's internal processing pipeline.
    pSoundTouch->flush();
    do
    {
        nSamples = pSoundTouch->receiveSamples(sampleBuffer, buffSizeSamples);
        
        outFile->write(sampleBuffer, nSamples * nChannels);
    } while (nSamples != 0);
}

void setup(soundtouch::SoundTouch *pSoundTouch, const WavInFile *inFile, const RunParameters *params)
{
    std::cout << params->pitchDelta << std::endl;
    
    int sampleRate;
    int channels;

    sampleRate = (int)inFile->getSampleRate();
    channels = (int)inFile->getNumChannels();
    pSoundTouch->setSampleRate(sampleRate);
    pSoundTouch->setChannels(channels);

    pSoundTouch->setTempoChange(params->tempoDelta);
    pSoundTouch->setPitchSemiTones(params->pitchDelta);
    pSoundTouch->setRateChange(params->rateDelta);

    pSoundTouch->setSetting(SETTING_USE_QUICKSEEK, params->quick);
    pSoundTouch->setSetting(SETTING_USE_AA_FILTER, !(params->noAntiAlias));

    if (params->speech)
    {
        // use settings for speech processing
        pSoundTouch->setSetting(SETTING_SEQUENCE_MS, 40);
        pSoundTouch->setSetting(SETTING_SEEKWINDOW_MS, 15);
        pSoundTouch->setSetting(SETTING_OVERLAP_MS, 8);
        fprintf(stderr, "Tune processing parameters for speech processing.\n");
    }

    // print processing information
    if (params->outFileName)
    {
#ifdef SOUNDTOUCH_INTEGER_SAMPLES
        fprintf(stderr, "Uses 16bit integer sample type in processing.\n\n");
#else
    #ifndef SOUNDTOUCH_FLOAT_SAMPLES
        #error "Sampletype not defined"
    #endif
        fprintf(stderr, "Uses 32bit floating point sample type in processing.\n\n");
#endif
        // print processing information only if outFileName given i.e. some processing will happen
        fprintf(stderr, "Processing the file with the following changes:\n");
        fprintf(stderr, "  tempo change = %+g %%\n", params->tempoDelta);
        fprintf(stderr, "  pitch change = %+g semitones\n", params->pitchDelta);
        fprintf(stderr, "  rate change  = %+g %%\n\n", params->rateDelta);
        fprintf(stderr, "Working...");
    }
    else
    {
        // outFileName not given
        fprintf(stderr, "Warning: output file name missing, won't output anything.\n\n");
    }

    fflush(stderr);
}

void cppTest::testLaunch(int pitchDelta){
    WavInFile *inFile;
    WavOutFile *outFile;
    RunParameters *params;
    soundtouch::SoundTouch soundTouch;
    
    char input[256], output[256];
    //HOME is the home directory of your application
    //points to the root of your sandbox
    strcpy(input,getenv("HOME"));
    //concatenating the path string returned from HOME
    strcat(input,"/Documents/input.wav");
    
    strcpy(output,getenv("HOME"));
    //concatenating the path string returned from HOME
    strcat(output,"/Documents/output.wav");
    
    params = new RunParameters(input, output, pitchDelta);
    
    // Open input & output files
    openFiles(&inFile, &outFile, params);

    if (params->detectBPM == true)
    {
        // detect sound BPM (and adjust processing parameters
        //  accordingly if necessary)
        detectBPM(inFile, params);
    }
    
    // Setup the 'SoundTouch' object for processing the sound
    setup(&soundTouch, inFile, params);
    
    std::cout << "Begin work" << std::endl;
    
    // Process the sound
    process(&soundTouch, inFile, outFile);
    
    delete inFile;
    delete outFile;
    delete params;
    
    std::cout << "End work" << std::endl;
}
