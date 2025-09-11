# docker-vsyuuno
A VapourSynth/Yuuno Docker Image, with some additional goodies

Based on:
- https://github.com/irrational-encoding-wizardry/yuuno
- https://github.com/vapoursynth/vapoursynth

===========================================================
HELP_ME.txt
Comprehensive Guide to Your Encoding & Remuxing Docker
===========================================================

Welcome! This Docker image provides a full CPU-based encoding and remuxing environment. 
It includes VapourSynth, Python tools, encoding scripts, GUI utilities, and a pre-configured user environment.

-----------------------------------------------------------
1. Starting the Environment
-----------------------------------------------------------
The container automatically launches:
- JupyterLab (accessible at port 8888)
- MKVToolNix GUI

To start the container:
docker run -it --rm -p 8888:8888 <image_name>

-----------------------------------------------------------
2. Users and Paths
-----------------------------------------------------------
- Default user: 'user'
- Home directory: /home/user
- Test scripts and notebooks: /home/user/test
- Documentation: /home/user/docs/HELP_ME.txt
- Repositories (if added): /home/user/repos

-----------------------------------------------------------
3. VapourSynth
-----------------------------------------------------------
- Core package installed along with essential plugins:
    bestsource, mvtools, removegrain, rekt, remapframes, fillborders, havsfunc,
    awsmfunc, eedi3m, continuityfixer, d2vsource, subtext, imwri, misc, ocr,
    vivtc, lsmashsource
- Test script: /home/user/test/test.vpy
- To run manually:
    vspipe /home/user/test/test.vpy - | ffmpeg -y -i - -c:v libx264 -preset veryfast -crf 18 output.mp4

-----------------------------------------------------------
4. Python Tools
-----------------------------------------------------------
Installed via pip:
- yuuno
- vs-jetpack
- vs-muxtools
- muxtools
- jupyterlab

-----------------------------------------------------------
5. Encoding & Remuxing Tools
-----------------------------------------------------------
- ffmpeg, x264, x265
- mkvtoolnix-gui (auto-launched)
- mplayer, mpv
- audio tools: lame, flac, opus-tools, sox

-----------------------------------------------------------
6. Adding Your Scripts
-----------------------------------------------------------
- Clone any additional repositories into /home/user/repos
- Python scripts, VapourSynth scripts, and notebooks can be run directly
- All tools are CPU-based

-----------------------------------------------------------
7. Tips
-----------------------------------------------------------
- Avoid running multiple heavy encoding tasks simultaneously in the container if memory is limited
- Test your VapourSynth scripts using the provided test.vpy
- Use JupyterLab for interactive notebooks and easier experimentation

===========================================================
Happy encoding and remuxing!

