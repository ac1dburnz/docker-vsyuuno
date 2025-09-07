FROM archlinux:latest

# -----------------------------
# Base system + user
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv mkvtoolnix-cli x11vnc xvfb novnc websockify \
    && pacman -Sc --noconfirm

RUN useradd -m -d /home/user -s /bin/bash user \
    && passwd --lock user \
    && echo "user ALL=(ALL) NOPASSWD: /usr/bin/pacman" > /etc/sudoers.d/allow_user_pacman \
    && echo "root ALL=(ALL) CWD=* ALL" > /etc/sudoers.d/permissive_root_chdir

USER user
WORKDIR /tmp

# -----------------------------
# Install yay (AUR helper) with retries
# -----------------------------
RUN set -e; \
    for i in 1 2 3 4 5; do \
        echo "Attempt $i to clone yay..."; \
        git clone https://aur.archlinux.org/yay.git /tmp/yay && break || sleep 5; \
    done; \
    cd /tmp/yay && \
    makepkg -si --noconfirm --noprogressbar && \
    cd /tmp && rm -rf /tmp/yay

# -----------------------------
# Install VapourSynth plugins from AUR
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
        vapoursynth-plugin-lsmashsource-git && \
    yay -Sc --noconfirm

# -----------------------------
# Clone and install vs-jetpack, vs-muxtools, muxtools
# -----------------------------
USER root
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/Jaded-Encoding-Thaumaturgy/muxtools.git
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git

# -----------------------------
# Install Python packages (yuuno, JupyterLab)
# -----------------------------
RUN pip install --no-cache-dir --upgrade pip setuptools yuuno jupyterlab --break-system-packages

# -----------------------------
# Optional: clone encoding scripts & documentation repos
# -----------------------------
USER user
WORKDIR /home/user/repos
RUN git clone https://github.com/OpusGang/EncodeScripts.git || true
RUN git clone https://github.com/Ichunjo/encode-scripts.git || true
RUN git clone https://github.com/LightArrowsEXE/Encoding-Projects.git || true
RUN git clone https://github.com/Beatrice-Raws/encode-scripts.git || true
RUN git clone https://github.com/Setsugennoao/Encoding-Scripts.git || true
RUN git clone https://github.com/RivenSkaye/Encoding-Progress.git || true
RUN git clone https://github.com/Moelancholy/Encode-Scripts.git || true

# -----------------------------
# Add test VapourSynth script & notebook
# -----------------------------
WORKDIR /home/user/test
RUN echo 'import vapoursynth as vs\ncore = vs.core\nclip = core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip = core.text.Text(clip,"Hello VapourSynth in Docker!")\nclip.set_output()' > test.vpy

RUN echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /home/user/test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > test_vapoursynth.ipynb

# -----------------------------
# Setup Xvfb + x11vnc + noVNC
# -----------------------------
USER root
RUN mkdir -p /opt/novnc/utils/websockify \
    && git clone https://github.com/novnc/noVNC.git /opt/novnc \
    && git clone https://github.com/novnc/websockify.git /opt/novnc/utils/websockify

RUN echo '#!/bin/bash\n\
export DISPLAY=:1\n\
Xvfb :1 -screen 0 1920x1080x24 &\n\
x11vnc -display :1 -nopw -forever -shared &\n\
/opt/novnc/utils/launch.sh --vnc localhost:5900 &\n\
exec "$@"' > /usr/local/bin/start-gui.sh && chmod +x /usr/local/bin/start-gui.sh

# -----------------------------
# Cleanup
# -----------------------------
RUN pacman -Scc --noconfirm && rm -rf /tmp/* /root/.cache /home/user/.cache || true

# -----------------------------
# Expose ports for Jupyter and GUI
# -----------------------------
WORKDIR /home/user
EXPOSE 8888 6080

# -----------------------------
# Default CMD
# -----------------------------
CMD ["bash", "-c", "/usr/local/bin/start-gui.sh && jupyter lab --allow-root --port=8888 --no-browser --ip=0.0.0.0"]
