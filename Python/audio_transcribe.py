# transcribe audio example

import errno
import time
import os.path
import sys

# install ffmpeg using OS package manager (choco install ffmpeg)
# pip install -U setuptools-rust
# pip install -U openai-whisper
import whisper
import torch

# to get CUDA working:
# install NVidia CUDA Toolkit: https://developer.nvidia.com/cuda-downloads?target_os=Windows&target_arch=x86_64&target_version=11&target_type=exe_local
# pip uninstall torch
# pip cache purge
# pip install -U cuda-python
# install CUDA torch where cu121 is the CUDA version:
# pip install -U torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121
# pip install -U openai-whisper

# References:
# - https://github.com/openai/whisper/discussions/47
# - https://stackoverflow.com/questions/75775272/cuda-and-openai-whisper-enforcing-gpu-instead-of-cpu-not-working

# command equivalent:
# whisper "podcast_episode.mp3" --model small.en --device cuda


def main(audio_file_path="podcast_episode.mp3"):
    """execution starts here"""
    print("main()")

    if not os.path.exists(audio_file_path):
        raise FileNotFoundError(
            errno.ENOENT, os.strerror(errno.ENOENT), audio_file_path
        )

    # PyTorch version should contain +cu### and not +cpu for CUDA
    print(
        f"INFO: PyTorch version: {torch.__version__} (should contain +cu### and not +cpu for CUDA)"
    )
    print(f"INFO: Is CUDA available? {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        # not sure this is required:
        torch.cuda.init()

    print("INFO: Loading Model, will take longer if not already cached.")

    # tiny.en, base.en, small.en, medium.en
    model = whisper.load_model("tiny.en")

    print("INFO: Starting transcription, could take minutes or hours!")

    start_time = time.time()

    result = model.transcribe(
        audio_file_path,
        # word_timestamps=True,
    )

    print(result["text"])

    print(f"--- Transcription Time: {time.time() - start_time} seconds ---")


if __name__ == "__main__":
    try:
        # get first arg as file path to audio:
        audio_file = sys.argv[1]
        main(audio_file)
    except IndexError:
        # use default path:
        print("INFO: using default path `podcast_episode.mp3`")
        main()
