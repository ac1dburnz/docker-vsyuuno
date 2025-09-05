FROM archlinux:latest

# -----------------------------
# Base system + user
# -----------------------------
RUN pacman -Syu --needed --noconfirm \
        sudo git base-devel python python-pip ffms2 vim wget gcc \
        vapoursynth ffmpeg x264 \
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
# Install vs-jetpack and vs-muxtools via pip + git
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
# Add test VapourSynth script & notebook
# -----------------------------
USER user
WORKDIR /home/user/test

# Simple test.vpy script
RUN echo 'import vapoursynth as vs\n\
core = vs.core\n\
clip = core.std.BlankClip(width=1280, height=720, length=240, fpsnum=24, fpsden=1, color=[128])\n\
clip = core.text.Text(clip, "Hello VapourSynth in Docker!")\n\
clip.set_output()' > test.vpy

# Simple test Jupyter notebook
RUN echo '{"cells":[{"cell_type":"code","metadata":{},"source":["!vspipe /home/user/test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4"],"execution_count":null,"outputs":[]}],"metadata":{"kernelspec":{"display_name":"Python 3","language":"python","name":"python3"}},"nbformat":4,"nbformat_minor":5}' > test_vapoursynth.ipynb

# -----------------------------
# Cleanup
# -----------------------------
WORKDIR /
RUN rm -rf /tmp/* /var/cache/pacman/pkg/* /root/.cache /home/user/.cache

# -----------------------------
# Expose Jupyter and run
# -----------------------------
EXPOSE 8888
CMD ["jupyter", "lab", "--allow-root", "--port=8888", "--no-browser", "--ip=0.0.0.0"]
