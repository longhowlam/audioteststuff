from __future__ import print_function
import numpy as np

import matplotlib
matplotlib.use('pdf')

# matplotlib for displaying the output
import matplotlib.pyplot as plt
import matplotlib.style as ms
ms.use('seaborn-muted')

# and IPython.display for audio output
import IPython.display

# Librosa for audio
import librosa
# And the display module for visualization
import librosa.display

audio_path = '/home/longhowlam/RProjects/MusicTest/test.mp3'

y, sr = librosa.load(audio_path)
y

# Let's make and display a mel-scaled power (energy-squared) spectrogram
S = librosa.feature.melspectrogram(y, sr=sr, n_mels=128)

# Convert to log scale (dB). We'll use the peak power (max) as reference.
log_S = librosa.power_to_db(S, ref=np.max)

# Make a new figure
plt.figure(figsize=(12,4))

# Display the spectrogram on a mel scale
# sample rate and hop length parameters are used to render the time axis
librosa.display.specshow(log_S, sr=sr, x_axis='time', y_axis='mel')

# Put a descriptive title on the plot
plt.title('mel power spectrogram')

# draw a color bar
plt.colorbar(format='%+02.0f dB')

# Make the figure layout compact
plt.tight_layout()
plt.savefig('/home/longhowlam/RProjects/MusicTest/mel.pdf')

# save me to file
melgram = librosa.logamplitude(librosa.feature.melspectrogram(y, sr=sr, n_mels=96),ref_power=1.0)[np.newaxis,np.newaxis,:,:]
outfile = '/home/longhowlam/RProjects/MusicTest/mel.npy'
np.save(outfile,melgram)

melgram
