#!/usr/bin/env python3
"""
Apple Motion Graphics — Parametric Cinematic Sound Synthesizer
Generates studio-grade 48kHz stereo WAV soundtrack with sub-bass risers,
subtle air sweeps, harmonic chimes, and tactile UI micro-clicks.
"""

import sys
import os
import math
import struct
import wave
import argparse

def clamp(v, minv, maxv):
    return max(minv, min(maxv, v))

class AppleSoundSynthesizer:
    def __init__(self, sample_rate=48000, total_seconds=40.0):
        self.sample_rate = sample_rate
        self.total_seconds = total_seconds
        self.total_samples = int(sample_rate * total_seconds)
        self.left = [0.0] * self.total_samples
        self.right = [0.0] * self.total_samples

    def add_tone(self, start_time, duration, freq, amp, fade_in=0.05, fade_out=0.05, pan=0.0, harmonic=0.0):
        start_sample = int(start_time * self.sample_rate)
        num_samples = int(duration * self.sample_rate)
        for i in range(num_samples):
            idx = start_sample + i
            if idx >= self.total_samples:
                break
            t = i / float(self.sample_rate)
            
            env = 1.0
            if t < fade_in and fade_in > 0:
                env = t / fade_in
            elif t > duration - fade_out and fade_out > 0:
                env = (duration - t) / fade_out
            env = clamp(env, 0.0, 1.0)
            
            val = math.sin(2.0 * math.pi * freq * t) * (1.0 - harmonic)
            if harmonic > 0:
                val += math.sin(4.0 * math.pi * freq * t) * harmonic * 0.5
                val += math.sin(6.0 * math.pi * freq * t) * harmonic * 0.25
            
            s = val * amp * env
            l_gain = math.sqrt(0.5 * (1.0 - pan))
            r_gain = math.sqrt(0.5 * (1.0 + pan))
            self.left[idx] += s * l_gain
            self.right[idx] += s * r_gain

    def add_sweep(self, start_time, duration, start_freq, end_freq, amp, fade_in=0.1, fade_out=0.1, pan=0.0):
        start_sample = int(start_time * self.sample_rate)
        num_samples = int(duration * self.sample_rate)
        phase = 0.0
        for i in range(num_samples):
            idx = start_sample + i
            if idx >= self.total_samples:
                break
            t = i / float(self.sample_rate)
            prog = t / duration
            curr_freq = start_freq + (end_freq - start_freq) * (prog ** 1.5)
            phase += 2.0 * math.pi * curr_freq / self.sample_rate
            
            env = 1.0
            if t < fade_in and fade_in > 0:
                env = t / fade_in
            elif t > duration - fade_out and fade_out > 0:
                env = (duration - t) / fade_out
            env = clamp(env, 0.0, 1.0)
            
            s = math.sin(phase) * amp * env
            l_gain = math.sqrt(0.5 * (1.0 - pan))
            r_gain = math.sqrt(0.5 * (1.0 + pan))
            self.left[idx] += s * l_gain
            self.right[idx] += s * r_gain

    def add_click(self, start_time, freq=2200, amp=0.18):
        start_sample = int(start_time * self.sample_rate)
        num_samples = int(0.025 * self.sample_rate)
        for i in range(num_samples):
            idx = start_sample + i
            if idx >= self.total_samples:
                break
            t = i / float(self.sample_rate)
            env = math.exp(-t * 220.0)
            val = math.sin(2.0 * math.pi * freq * t) * amp * env
            self.left[idx] += val
            self.right[idx] += val

    def add_ambient_bed(self):
        for i in range(self.total_samples):
            t = i / float(self.sample_rate)
            master_env = 1.0
            if t < 2.0:
                master_env = t / 2.0
            elif t > self.total_seconds - 2.0:
                master_env = (self.total_seconds - t) / 2.0
            master_env = clamp(master_env, 0.0, 1.0)
            
            sub_l = (math.sin(2 * math.pi * 54.8 * t) * 0.12 + math.sin(2 * math.pi * 109.6 * t) * 0.04) * master_env
            sub_r = (math.sin(2 * math.pi * 55.2 * t) * 0.12 + math.sin(2 * math.pi * 110.4 * t) * 0.04) * master_env
            air = (math.sin(2 * math.pi * 220 * t) * 0.02 + math.sin(2 * math.pi * 330 * t) * 0.015) * master_env
            
            self.left[i] += sub_l + air * 0.9
            self.right[i] += sub_r + air * 1.1

    def export_wav(self, out_path):
        self.add_ambient_bed()
        
        # Master normalization
        max_val = 0.0
        for i in range(self.total_samples):
            max_val = max(max_val, abs(self.left[i]), abs(self.right[i]))
        
        gain = 0.88 / max(max_val, 1e-6)
        
        with wave.open(out_path, 'w') as wf:
            wf.setnchannels(2)
            wf.setsampwidth(2)
            wf.setframerate(self.sample_rate)
            
            out_frames = bytearray()
            for i in range(self.total_samples):
                l_samp = int(clamp(self.left[i] * gain, -1.0, 1.0) * 32767.0)
                r_samp = int(clamp(self.right[i] * gain, -1.0, 1.0) * 32767.0)
                out_frames.extend(struct.pack('<hh', l_samp, r_samp))
            wf.writeframes(out_frames)
        print(f"Audio soundtrack generated: {out_path} ({self.total_seconds:.1f}s, {self.sample_rate}Hz stereo)")

def main():
    parser = argparse.ArgumentParser(description="Apple Launch Film Audio Synthesizer")
    parser.add_argument("--duration", type=float, default=40.0, help="Duration in seconds")
    parser.add_argument("--output", type=str, default="/tmp/soundtrack.wav", help="Output WAV path")
    args = parser.parse_args()

    synth = AppleSoundSynthesizer(total_seconds=args.duration)
    
    # Reveal accents
    synth.add_sweep(0.6, 2.2, 80, 580, 0.18, fade_in=0.3, fade_out=0.4, pan=-0.3)
    synth.add_tone(2.0, 3.5, 440.0, 0.12, fade_in=0.1, fade_out=2.0, harmonic=0.3)
    synth.add_tone(2.0, 3.5, 880.0, 0.08, fade_in=0.05, fade_out=1.8, harmonic=0.4)
    synth.add_sweep(2.8, 2.0, 55, 45, 0.22, fade_in=0.2, fade_out=1.2)
    
    synth.export_wav(args.output)

if __name__ == "__main__":
    main()
