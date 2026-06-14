import math
import wave
import struct
import os

os.makedirs('assets/audio', exist_ok=True)

def generate_tone(filename, freq, duration, volume=0.5):
    sample_rate = 44100
    num_samples = int(sample_rate * duration)
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for i in range(num_samples):
            fade = 1.0 - (i / num_samples)
            value = int(volume * fade * 32767.0 * math.sin(2.0 * math.pi * freq * i / sample_rate))
            data = struct.pack('<h', value)
            wav_file.writeframesraw(data)

generate_tone('assets/audio/move.wav', 800, 0.1, 0.3)

def generate_win_tone(filename):
    sample_rate = 44100
    duration_per_note = 0.15
    notes = [523.25, 659.25, 783.99, 1046.50]
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(sample_rate)
        for freq in notes:
            num_samples = int(sample_rate * duration_per_note)
            for i in range(num_samples):
                fade = 1.0 - (i / num_samples)
                value = int(0.4 * fade * 32767.0 * math.sin(2.0 * math.pi * freq * i / sample_rate))
                data = struct.pack('<h', value)
                wav_file.writeframesraw(data)

generate_win_tone('assets/audio/win.wav')
