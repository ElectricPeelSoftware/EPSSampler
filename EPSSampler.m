//
//  EPSSampler.m
//
//  Created by Peter Stuart on 02/10/13.
//  Copyright (c) 2013 Electric Peel Software. All rights reserved.
//

#import "EPSSampler.h"

#import <AssertMacros.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreAudio/CoreAudioTypes.h>

enum
{
	kMIDIMessage_NoteOn  = 0x9,
	kMIDIMessage_NoteOff = 0x8,
};

#define kMidiVelocityMinimum 0
#define kMidiVelocityMaximum 127

@interface EPSSampler ()

@property (readwrite) Float64 graphSampleRate;
@property (readwrite) AUGraph processingGraph;
@property (readwrite) AudioUnit samplerUnit;
@property (readwrite) AudioUnit ioUnit;

- (OSStatus)loadSynthFromPresetURL:(NSURL *)presetURL;
- (BOOL)createAUGraph;
- (void)configureAndStartAudioProcessingGraph:(AUGraph)graph;
- (void)stopAudioProcessingGraph;
- (void)restartAudioProcessingGraph;

@end

@implementation EPSSampler

@synthesize graphSampleRate = _graphSampleRate;
@synthesize samplerUnit = _samplerUnit;
@synthesize ioUnit = _ioUnit;
@synthesize processingGraph = _processingGraph;

#pragma mark - Public Methods

- (id)initWithPresetURL:(NSURL *)url {
	self = [super init];
	if (self) {
		[self createAUGraph];
		[self configureAndStartAudioProcessingGraph:self.processingGraph];
		[self loadSynthFromPresetURL:url];
	}
	
	return self;
}

- (void)startPlayingNote:(UInt32)note withVelocity:(double)velocity {
	UInt32 noteNum    = note;
	UInt32 onVelocity = kMidiVelocityMinimum + (kMidiVelocityMaximum - kMidiVelocityMinimum) * velocity;
	
	UInt32 noteCommand = kMIDIMessage_NoteOn << 4 | 0;
	
	OSStatus result = noErr;
	require_noerr(result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, onVelocity, 0), logTheError);
	
logTheError:
	
	if (result != noErr)
	{
		NSLog(@"Unable to start playing the low note. Error code: %d '%.4s'\n", (int)result, (const char *)&result);
	}
}

- (void)stopPlayingNote:(UInt32)note
{
	UInt32 noteNum     = note;
	UInt32 noteCommand = kMIDIMessage_NoteOff << 4 | 0;
	
	OSStatus result = noErr;
	
	require_noerr(result = MusicDeviceMIDIEvent(self.samplerUnit, noteCommand, noteNum, 0, 0), logTheError);
	
logTheError:
	
	if (result != noErr)
	{
		NSLog(@"Unable to stop playing the low note. Error code: %d '%.4s'\n", (int)result, (const char *)&result);
	}
}

#pragma mark - Private Methods

- (BOOL)createAUGraph {
	OSStatus result = noErr;
	AUNode   samplerNode, ioNode;

	AudioComponentDescription cd = {};

	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags        = 0;
	cd.componentFlagsMask    = 0;

	result = NewAUGraph(&_processingGraph);
	NSCAssert(result == noErr, @"Unable to create an AUGraph object. Error code: %d '%.4s'", (int)result, (const char *)&result);

	cd.componentType    = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_Sampler;

	result = AUGraphAddNode(self.processingGraph, &cd, &samplerNode);
	NSCAssert(result == noErr, @"Unable to add the Sampler unit to the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);

	cd.componentType    = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_RemoteIO;

	result = AUGraphAddNode(self.processingGraph, &cd, &ioNode);
	NSCAssert(result == noErr, @"Unable to add the Output unit to the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);

	result = AUGraphOpen(self.processingGraph);
	NSCAssert(result == noErr, @"Unable to open the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);

	result = AUGraphConnectNodeInput(self.processingGraph, samplerNode, 0, ioNode, 0);
	NSCAssert(result == noErr, @"Unable to interconnect the nodes in the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);

	result = AUGraphNodeInfo(self.processingGraph, samplerNode, 0, &_samplerUnit);
	NSCAssert(result == noErr, @"Unable to obtain a reference to the Sampler unit. Error code: %d '%.4s'", (int)result, (const char *)&result);

	result = AUGraphNodeInfo(self.processingGraph, ioNode, 0, &_ioUnit);
	NSCAssert(result == noErr, @"Unable to obtain a reference to the I/O unit. Error code: %d '%.4s'", (int)result, (const char *)&result);

	return YES;
}

- (void)configureAndStartAudioProcessingGraph:(AUGraph)graph {
	OSStatus result = noErr;
	if (graph)
	{
		// Initialize the audio processing graph.
		result = AUGraphInitialize(graph);
		NSAssert(result == noErr, @"Unable to initialze AUGraph object. Error code: %d '%.4s'", (int)result, (const char *)&result);

		// Start the graph
		result = AUGraphStart(graph);
		NSAssert(result == noErr, @"Unable to start audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);

		// Print out the graph to the console
		CAShow(graph);
	}
}

- (OSStatus)loadSynthFromPresetURL:(NSURL *)presetURL {
	CFDataRef propertyResourceData = 0;
	Boolean   status;
	SInt32    errorCode = 0;
	OSStatus  result    = noErr;

	status = CFURLCreateDataAndPropertiesFromResource(
		kCFAllocatorDefault,
		(__bridge CFURLRef)presetURL,
		&propertyResourceData,
		NULL,
		NULL,
		&errorCode
		);

	NSAssert(status == YES && propertyResourceData != 0, @"Unable to create data and properties from a preset. Error code: %d '%.4s'", (int)errorCode, (const char *)&errorCode);

	CFPropertyListRef    presetPropertyList = 0;
	CFPropertyListFormat dataFormat         = 0;
	CFErrorRef           errorRef           = 0;
	presetPropertyList = CFPropertyListCreateWithData(
		kCFAllocatorDefault,
		propertyResourceData,
		kCFPropertyListImmutable,
		&dataFormat,
		&errorRef
		);

	if (presetPropertyList != 0) {
		result = AudioUnitSetProperty(
			self.samplerUnit,
			kAudioUnitProperty_ClassInfo,
			kAudioUnitScope_Global,
			0,
			&presetPropertyList,
			sizeof(CFPropertyListRef)
			);

		CFRelease(presetPropertyList);
	}

	if (errorRef) {
		CFRelease(errorRef);
	}

	CFRelease(propertyResourceData);

	return result;
}

- (void)stopAudioProcessingGraph {
	OSStatus result = noErr;

	if (self.processingGraph) {
		result = AUGraphStop(self.processingGraph);
	}

	NSAssert(result == noErr, @"Unable to stop the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);
}

- (void)restartAudioProcessingGraph {
	OSStatus result = noErr;

	if (self.processingGraph) {
		result = AUGraphStart(self.processingGraph);
	}

	NSAssert(result == noErr, @"Unable to restart the audio processing graph. Error code: %d '%.4s'", (int)result, (const char *)&result);
}

@end