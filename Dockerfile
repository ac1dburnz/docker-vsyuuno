FROM archlinux:latest

# -----------------------------
# Base system + user
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 x265 lame flac opus-tools sox \
        mplayer mpv deew mkvtoolnix-gui \
    && pacman -Sc --noconfirm

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
# Install Python tools via pip+git
# -----------------------------
USER root
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-jetpack.git
RUN pip install --no-cache-dir --break-system-packages git+https://github.com/Jaded-Encoding-Thaumaturgy/vs-muxtools.git
RUN pip install --no-cache-dir --break-system-packages yuuno jupyterlab --upgrade --break-system-packages

# -----------------------------
# Clone encoding scripts & docs
# -----------------------------
USER user
RUN mkdir -p /home/user/repos /home/user/docs
WORKDIR /home/user/repos

# VapourSynth encode scripts
RUN git clone https://git.concertos.live/OpusGang/EncodeScripts.git && \
    git clone https://github.com/Ichunjo/encode-scripts.git && \
    git clone https://github.com/LightArrowsEXE/Encoding-Projects.git && \
    git clone https://github.com/Beatrice-Raws/encode-scripts.git && \
    git clone https://github.com/Setsugennoao/Encoding-Scripts.git && \
    git clone https://github.com/RivenSkaye/Encoding-Progress.git && \
    git clone https://github.com/Moelancholy/Encode-Scripts.git

# Download guides/docs
WORKDIR /home/user/docs
RUN wget -O vs_scriptorium.html https://silentaperture.gitlab.io/mdbook-guide/scriptorium.html && \
    wget -O jet_guide.html https://jaded-encoding-thaumaturgy.github.io/JET-guide/ && \
    wget -O silentaperture_guide.html https://silentaperture.gitlab.io/mdbook-guide && \
    wget -O ie_wizardry_guide.html https://guide.encode.moe/encoding/preparation.html && \
    wget -O x264_guide.html https://passthepopcorn.me/wiki.php?action=article&id=272

# -----------------------------
# Setup test folder & scripts
# -----------------------------
WORKDIR /home/user/test
RUN echo 'import vapoursynth as vs\ncore=vs.core\nclip=core.std.BlankClip(width=1280,height=720,length=240,fpsnum=24,fpsden=1,color=[128])\nclip.set_output()' > test.vpy

# -----------------------------
# Cleanup
# -----------------------------
USER root
RUN pacman -Scc --noconfirm && \
    rm -rf /tmp/* /root/.cache /home/user/.cache || true

# -----------------------------
# Expose Jupyter and GUI (if needed)
# -----------------------------
WORKDIR /home/user
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]