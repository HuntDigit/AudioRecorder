# **macOS Audio Recorder**

This project is a basic audio recording application for macOS, developed as a technical assessment. The application captures system audio, saves it in sequential chunks, and allows for seamless playback.

## **Environment Requirements**

* **macOS:** Sonoma 14.0 or later  
* **Xcode:** 15.0 or later  
* **Language:** Swift 6  
* **Frameworks:** SwiftUI, AVFoundation ,AVAudioEngine, CoreMedia, ScreenCaptureKit

## **Core Features**

* **System Audio Capture:** Records audio output from the entire system (requires Screen Capture permission).  
* **Audio Chunking:** Automatically splits the recording into separate audio files of a configurable duration.  
* **Continuous Saving:** Writes audio chunks to disk in real-time during the recording session without interruption.  
* **Configurable Chunk Duration:** The duration of each audio chunk can be adjusted from the app's `MenuBarExtra` (default is 10 seconds).  
* **Standard Naming Convention:** Saved files follow the format audio_system\_\[number\].wav.  
* **Minimalist UI:** A clean interface providing essential controls: Record, Stop, and Playback.  
* **Sequential Playback:** Plays the recorded audio chunks back-to-back, no audible gaps between files.
* 
## **Setup and Build Instructions**

1. **Clone the Repository:**
```
git clone https://github.com/HuntDigit/AudioRecorder.git
```
```
cd AudioRecorder
```

2. Open in Xcode:  
   Open the .xcodeproj file in Xcode 15 or later.

or
```
open AudioRecorder.xcodeproj
```
3. Make sure you have a valid bundle ID and select `Signing Certificate` -> `Sign to Run Locally`.
  
4. Run the Application:  
   Select the target device (My Mac) and press the "Run" button (or Cmd+R).
   
5. Grant Permissions:  
   The first time you run the application and start a recording, macOS will prompt you to grant "Screen Recording" permissions.
   This is required for capturing system audio. Please grant access and restart the app if prompted.
   
## **Architecture and Design Overview**

The application is built using a modern SwiftUI lifecycle and relies on the AVFoundation framework for all audio processing.
A simplified `MVVM` architecture with dedicated `Services` and `Managers` to clearly separate responsibilities across classes.

* **SystemAudioRecorder:** This is the core class that encapsulates all audio-related logic. It manages the AVAudioEngine, handles the setup for system audio capture, and processes the incoming audio buffers. It exposes published properties (@Published) to update the SwiftUI view with the current recording state (e.g., isRecording, isPlaying).  
* Audio Tapping and Chunking:  
  The AVAudioEngine's main mixer node is tapped to install a callback that receives raw audio buffers. A custom `SegmentedAudioWriter` is responsible for accumulating these buffers. Once the accumulated audio data reaches the user-defined chunk duration (10,20,30 seconds), the manager writes the data to a .wav file and immediately starts a new chunk. This ensures that file I/O happens without interrupting the live audio capture.

For macOS 15 and later, `.microphone` capture is also available through *ScreenCaptureKit*, providing direct access to microphone input  
* Playback:  
  The playback functionality is handled by a separate `AudioPlayer`, which is ideal for playing multiple items sequentially. When playback is initiated, all recorded .wav files for the session are loaded into the queue, providing a continuous listening experience as required.

## **Known Limitations and Potential Improvements**

* **No Input Device Selection:** The app defaults to system audio capture and the default microphone, and does not currently allow selecting other input sources such as external devices.
* **Error Handling:** Error handling is minimal. The app could be improved with more robust error reporting for scenarios like disk-full errors, permission denial, or audio hardware failures.  
* **Basic Playback Controls:** Playback is sequential only. There are no controls for pausing, seeking, or viewing the playlist of chunks.  
* **No Visual Feedback:** A real-time waveform or audio level meter would significantly improve the user experience by providing visual confirmation that audio is being captured.  
* **File Management:** Recordings from previous sessions are not managed. An interface to browse, name, and delete past recording sessions would be a valuable addition.
