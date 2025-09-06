# -----------------------------
# Base image
# -----------------------------
FROM archlinux:latest

# -----------------------------
# Update and install base packages
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv mkvtoolnix-gui \
    && pacman -Sc --noconfirm

# -----------------------------
# Create non-root user
# -----------------------------
RUN useradd -m -d /home/user -s /bin/bash user \
    && passwd --lock user \
    && echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_pacman \
    && echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_chdir

USER user
WORKDIR /tmp

# -----------------------------
# Install yay (AUR helper)
# -----------------------------
RUN git clone https://aur.archlinux.org/yay.git /tmp/yay && \
    cd /tmp/yay && \
    makepkg -si --noconfirm --noprogressbar && \
    cd /tmp && rm -rf /tmp/yay

# -----------------------------
# Install AUR packages
# -----------------------------
RUN yay -Syu --needed --noconfirm \
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
        deew \
    && yay -Sc --noconfirm

# -----------------------------
# Clone important repos
# -----------------------------
RUN git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git /home/user/repos/vs-jetpack && \
    git clone https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git /home/user/repos/vs-muxtools && \
    git clone https://github.com/Jaded-Encoding-Thaumaturgy/muxtools.git /home/user/repos/muxtools

# -----------------------------
# Install Python packages
# -----------------------------
USER root
RUN pip install --no-cache-dir --upgrade pip setuptools --break-system-packages
RUN pip install --no-cache-dir --break-system-packages \
        /home/user/repos/vs-jetpack \
        /home/user/repos/vs-muxtools \
        /home/user/repos/muxtools \
        yuuno jupyterlab

# -----------------------------
# Setup test VapourSynth script & notebook
# -----------------------------
USER user
WORKDIR /home/user/test
RUN mkdir -p /home/user/test

# Simple test.vpy script
RUN echo 'import vapoursynth as vs\n\
core = vs.core\n\
clip = core.std.BlankClip(width=1280, height=720, length=240, fpsnum=24, fpsden=1, color=[128])\n\
clip = core.text.Text(clip, "Hello VapourSynth in Docker!")\n\
clip.set_output()' > /home/user/test/test.vpy

# Simple test Jupyter notebook
RUN echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /home/user/test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > /home/user/test/test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
USER root
RUN pacman -Scc --noconfirm && \
    rm -rf /tmp/* /root/.cache /home/user/.cache

# -----------------------------
# Expose Jupyter and mkvtoolnix-gui
# -----------------------------
USER user
WORKDIR /home/user
EXPOSE 8888

# -----------------------------
# Launch Jupyter Lab & mkvtoolnix-gui (can be auto-launched)
# -----------------------------
CMD jupyter lab --allow-root --port=8888 --no-browser --ip=0.0.0.0 & mkvtoolnix-gui