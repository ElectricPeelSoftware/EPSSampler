# EPSSampler

`EPSSampler` is a wrapper around `AUSampler` functionality, based on Apple’s [Sampler Unit Presets][sample] sample code.

## Requirements

- iOS 5.0 or later

## Setup

1. Add `AudioToolbox`, `AVFoundation`, and `CoreAudio` to your project’s linked libraries.
2. Add `EPSSampler.h` and `EPSSampler.m` to your project.

## Usage

Create an `aupreset` file in AU Lab and add it to your project. (See Session 411 from WWDC 2011 for more details.) Add all the sound files needed by the preset to a folder named `Sounds` in your project. Create an instance of `EPSSampler` with the preset file:

    NSURL *presetURL = [[NSBundle mainBundle] URLForResource:@"Preset" withExtension:@"aupreset"];
    EPSSampler *sampler = [[EPSSampler alloc] initWithPresetURL:presetURL];

To play and stop notes, use these methods:

`- (void)startPlayingNote:(UInt32)note withVelocity:(double)velocity`
`- (void)stopPlayingNote:(UInt32)note`

The `note` parameters should be the MIDI index of the note you want to start/stop. The `velocity` parameter should be a value between `0` and `1`.

## Notes

AU Lab is no longer included with Xcode. It can be downloaded by choosing Xcode->Open Developer Tools->More Developer Tools… in Xcode, and then choosing Audio Tools for Xcode. There isn’t much document on `AUSampler`—watch Session 411 from WWDC 2011, and read [Technical Note TN2283][tech-note] for more information.

[sample]: https://developer.apple.com/library/ios/samplecode/LoadPresetDemo/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011214
[tech-note]: https://developer.apple.com/library/ios/samplecode/LoadPresetDemo/Introduction/Intro.html#//apple_ref/doc/uid/DTS40011214