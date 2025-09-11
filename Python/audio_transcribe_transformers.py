# transcribe audio example

import errno
import os.path
import sys
import time

import torch

# using HuggingFace improved Whisper:
# https://billtcheng2013.medium.com/faster-audio-transcribing-with-openai-whisper-and-huggingface-transformers-dc088243803d
# Install: pip install transformers
from transformers import pipeline

# Install: pip install optimum
# https://github.com/huggingface/optimum
# from optimum.bettertransformer import BetterTransformer

# to get CUDA working:
# install NVidia CUDA Toolkit: https://developer.nvidia.com/cuda-downloads?target_os=Windows&target_arch=x86_64&target_version=11&target_type=exe_local
# pip uninstall torch
# pip cache purge
# pip install -U cuda-python
# install CUDA torch where cu121 is the CUDA version:
# pip install -U torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu121


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

    # use GPU if available:
    device = "cuda:0" if torch.cuda.is_available() else "cpu"

    # this will improve performance on GPUs:
    torch_dtype = torch.float16 if torch.cuda.is_available() else torch.float32

    # "openai/whisper-large-v2", "distil-whisper/distil-large-v2"
    model_id = "distil-whisper/distil-large-v2"
    whisper = pipeline(
        "automatic-speech-recognition",
        model_id,
        torch_dtype=torch_dtype,
        device=device,
    )

    # use the optimum faster transformer:
    # whisper.model = BetterTransformer.transform(whisper.model)

    print("INFO: Starting transcription, could take minutes or hours!")

    start_time = time.time()

    transcription = whisper(
        audio_file_path, chunk_length_s=30, stride_length_s=10, batch_size=10
    )

    # print the first 500 characters:
    print(transcription["text"][:500])

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
