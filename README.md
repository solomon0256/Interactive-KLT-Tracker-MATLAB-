# Interactive KLT Tracker (MATLAB)

**TL;DR**: An interactive MATLAB demo for **sparse point tracking** using **KLT (vision.PointTracker)**. Users select a target ROI on the first frame; the tracker follows its feature points in real time. The app provides a dual‑panel GUI, FPS/valid‑points overlay, and robust input fallback (webcam → videoinput → local video).

> This is a teaching/demo project, not a production‑grade tracker.

## PCB Preview

Here is the PCB layout:

![PCB Layout](result/pcb%20(1).png)

---

## Features

* 🎯 **Interactive ROI**: click the button, then two mouse clicks to define a rectangle.
* 🔗 **KLT tracking**: `vision.PointTracker(MaxBidirectionalError=1)` on detected corner features.
* ♻️ **Auto re‑init**: when valid points drop below a threshold, the tracker re‑initializes from the seed features.
* 🪟 **Dual views**: left = live tracking view; right = ROI feature preview.
* 📈 **HUD overlay**: FPS and valid point count drawn on the live view.
* 🧯 **Graceful fallback**: webcam → Image Acquisition (`winvideo`) → local file `samples/sample.mp4`.

---

## Repository Layout (suggested)

```
Interactive-KLT-Tracker/
├─ src/
│  └─ findme.m                 # main app (this repo)
├─ samples/
│  └─ sample.mp4               # optional fallback video (add your own)
├─ output/
│  └─ teaser.png               # saved frame for README/demo
└─ README.md
```

---

## Requirements

* MATLAB **R2021b+**
* **Computer Vision Toolbox** (required)
* One of the following for live capture (optional):

  * *MATLAB Support Package for USB Webcams* (for `webcam` API), or
  * *Image Acquisition Toolbox* + *OS Generic Video Interface* (for `videoinput('winvideo',...)`).

Without support packages, place a short video at `samples/sample.mp4` to run the demo.

---

## Quick Start

```matlab
addpath('src');
findme;                    % launches the GUI
```

**Controls**

* Click **“锁定目标 / Lock Target”**, then click **two corners** on the left view to define ROI.
* Press **`q`** to exit.

**Data Sources (auto‑selected)**

1. `webcam` (if the USB Webcam support package is installed)
2. `videoinput('winvideo',...)` (if IAT + OS Generic adaptor is installed)
3. Local file `samples/sample.mp4` (if neither capture method is available)

---

## How It Works (High Level)

1. Grabs the first frame from the chosen source and shows it in the left view.
2. When ROI is set, detects seed features with `detectMinEigenFeatures`.
3. Initializes `vision.PointTracker` on a downsampled frame for stability.
4. For each new frame: track → filter valid points → re‑init if points are too few → render markers and HUD.

---

## Output

* Live view with green `+` markers on tracked features.
* HUD text: `FPS` and `valid` point count.
* You can save a frame for the README:

  ```matlab
  frame = getframe(gcf);
  imwrite(frame.cdata, 'output/teaser.png');
  ```

---

## Limitations

* Basic KLT demo: no drift suppression, occlusion handling, or long‑term model updates.
* Platform differences: live capture depends on support packages/drivers.
* ROI with low texture yields few/lost points; pick high‑contrast textured regions.

---

## Citation (optional)

If this demo helps your coursework or documentation:

```bibtex
@software{interactive_klt_tracker,
  title  = {Interactive KLT Tracker (MATLAB)},
  author = {Your Name},
  year   = {2025},
  url    = {https://github.com/<you>/interactive-klt-tracker}
}
```

## License

MIT (add a `LICENSE` file if you plan to publish).
# Interactive-KLT-Tracker-MATLAB-
