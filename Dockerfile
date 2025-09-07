# -----------------------------
# Set working user
# -----------------------------
USER root

# -----------------------------
# Create /repos safely
# -----------------------------
RUN mkdir -p /repos && chown user:user /repos

# Switch to unprivileged user for git clones
USER user
WORKDIR /repos

# -----------------------------
# Clone encoding repositories (skip failures)
# -----------------------------
RUN for repo in \
        https://github.com/OpusGang/EncodeScripts.git \
        https://github.com/Ichunjo/encode-scripts.git \
        https://github.com/LightArrowsEXE/Encoding-Projects.git \
        https://github.com/Beatrice-Raws/encode-scripts.git \
        https://github.com/Setsugennoao/Encoding-Scripts.git \
        https://github.com/RivenSkaye/Encoding-Progress.git \
        https://github.com/Moelancholy/Encode-Scripts.git; do \
        repo_name=$(basename "$repo" .git); \
        if [ ! -d "$repo_name" ]; then \
            echo "Cloning $repo ..."; \
            git clone "$repo" || echo "Failed to clone $repo, skipping."; \
        else \
            echo "$repo_name already exists, skipping."; \
        fi; \
    done

# -----------------------------
# Create /test safely
# -----------------------------
USER root
RUN mkdir -p /test && chown user:user /test

USER user
WORKDIR /test

# -----------------------------
# Create VapourSynth example files
# -----------------------------
RUN echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > test_vapoursynth.ipynb