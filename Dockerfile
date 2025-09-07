# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

# -----------------------------
# Install essential system packages
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv x11vnc xorg-server-xvfb unzip cabextract wine \
        rust cargo unrar \
    && pacman -Sc --noconfirm

# -----------------------------
# Create system user (optional, not used)
# -----------------------------
RUN useradd user --system --shell /bin/bash --create-home --home-dir /var/user \
    && passwd --lock user \
    && echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_to_pacman \
    && echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_Chdir_Spec

# -----------------------------
# Working directory
# -----------------------------
WORKDIR /

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
RUN set -e; \
    for i in 1 2 3 4 5; do \
        echo "Attempt $i to clone yay..."; \
        git clone https://aur.archlinux.org/yay.git /tmp/yay && break || sleep 5; \
    done; \
    cd /tmp/yay && makepkg -si --noconfirm --noprogressbar; \
    cd /tmp && rm -rf /tmp/yay

# -----------------------------
# Install VapourSynth plugins
# -----------------------------
RUN yay -Syu --overwrite "*" --needed --noconfirm \
        vapoursynth-plugin-bestsource-git \
        vapoursynth-plugin-mvtools-git \
        vapoursynth-plugin-removegrain-git \
        vapoursynth-plugin-rekt-git \
        vapoursynth-plugin-remapframes-git \
        vapoursynth-plugin-fillborders-git \
        vapoursynth-plugin-havsfunc-git \
        vapoursynth-plugin-awsmfunc-git \
        vapoursynth-plugin-eedi3m-git \
        vapoursynth-plugin-continuityfixer-git \
        vapoursynth-plugin-d2vsource-git \
        vapoursynth-plugin-subtext-git \
        vapoursynth-plugin-imwri-git \
        vapoursynth-plugin-misc-git \
        vapoursynth-plugin-ocr-git \
        vapoursynth-plugin-vivtc-git \
        vapoursynth-plugin-lsmashsource-git \
    && yay -Sc --noconfirm

# -----------------------------
# Install Python packages
# -----------------------------
RUN pip install --no-cache-dir --break-system-packages --upgrade \
        pip setuptools \
        yuuno jupyterlab deew \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/muxtools.git \
        git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git

# -----------------------------
# Install eac3to from local repo
# -----------------------------
# Make sure eac3to_3.52.rar is in the same folder as the Dockerfile
COPY eac3to_3.52.rar /opt/eac3to/

RUN mkdir -p /opt/eac3to \
    && unrar x /opt/eac3to/eac3to_3.52.rar /opt/eac3to/ \
    && rm /opt/eac3to/eac3to_3.52.rar \
    && echo '#!/bin/bash\nwine /opt/eac3to/eac3to.exe "$@"' > /usr/local/bin/eac3to \
    && chmod +x /usr/local/bin/eac3to

# -----------------------------
# Clone encoding scripts
# -----------------------------
RUN mkdir -p /repos && cd /repos && \
    for repo in \
        https://github.com/OpusGang/EncodeScripts.git \
        https://github.com/Ichunjo/encode-scripts.git \
        https://github.com/LightArrowsEXE/Encoding-Projects.git \
        https://github.com/Beatrice-Raws/encode-scripts.git \
        https://github.com/Setsugennoao/Encoding-Scripts.git \
        https://github.com/RivenSkaye/Encoding-Progress.git \
        https://github.com/Moelancholy/Encode-Scripts.git; do \
        git clone "$repo" || true; \
    done

# -----------------------------
# Add test VapourSynth script & notebook
# -----------------------------
RUN mkdir -p /test && \
    echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > /test/test.vpy && \
    echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /var/user/.cache || true

# -----------------------------
# Default working dir and CMD
# -----------------------------
WORKDIR /
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
