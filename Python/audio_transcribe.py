# transcribe audio example

import time

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


def main():
    """execution starts here"""
    print("main()")

    print(f"PyTorch version: {torch.__version__}")
    print(f"Is CUDA available? {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        torch.cuda.init()

    # tiny.en, base.en, small.en, medium.en
    model = whisper.load_model("tiny.en")

    start_time = time.time()

    result = model.transcribe(
        r"C:\Users\james\Library\AutoPkg\Cache\com.github.jgstew.download.BigFix-Podcast\downloads\podcast_episode.mp3"
    )

    print(result["text"])

    print(f"--- {time.time() - start_time} seconds ---")


if __name__ == "__main__":
    main()
