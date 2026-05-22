# Fuzzy-logic-based Relevant Color Extractor

### [![Project page](https://img.shields.io/badge/-Project%20page-blue)](https://graphics.unizar.es/projects/fuzzy_palette_extractor_2026/) | [![Paper](https://img.shields.io/badge/Paper-PDF-red)](https://graphics.unizar.es/papers/subias_relevant_colors_2026.pdf) 

The official **MATLAB** implementation of a fuzzy-logic and clustering based algorithm for extracting perceptually relevant color palettes from images.

[J. Daniel Subias](https://dsubias.github.io/)<sup>1\*</sup>, [Ramon Fernandez-Gualda]()<sup>2</sup>, [Samuel Morillas]()<sup>3</sup> & [Juan Luis Nieves]()<sup>2</sup>

<sup>1</sup>**Universidad de Zaragoza, I3A, Spain**  
<sup>2</sup>**University Institute of Pure and Applied Mathematics, Universitat Politècnica de València, Spain**  
<sup>3</sup>**Universidad de Granada, Spain**  
<sup>\*</sup>[dsubias@unizar.es](mailto:dsubias@unizar.es)

In **CEIG - Spanish Computer Graphics Conference (2026)**

---

<img src='imgs/teaser.png' alt='Teaser Image' width='600'/>

## TL;DR Quickstart
```bash
# 1. Clone the repository and navigate into it
git clone https://github.com/dsubias/Relevat_colors_2026.git
cd Relevat_colors_2026
```
```matlab
% 2. Open MATLAB and ensure you are in the repository folder

% 3. Place your test images in the input directory
% By default, the script looks in: ./Test_Images

% 4. Run the main extraction script
run fuzzy_palette_extractor.m
```

**Alternative (Run directly from Linux/Mac Terminal):**
```bash
matlab -batch "fuzzy_palette_extractor"
```

If everything works without errors, you can check the output directories (e.g., `adaptive_2_iters`) to find your `color_palettes`, `k_means` segmentations, and `reconstruction` results!

## Execution Scripts
The repository provides the main entry point for the extraction pipeline:

- `fuzzy_palette_extractor.m`: Automatically reads `.jpg` and `.png` files from `./Test_Images`, computes color relevances using the fuzzy logic engine, and exports `256x256` pixel continuous color palette strips.

### Key Parameters in `fuzzy_palette_extractor.m`:
- `maxIterations`: Maximum number of pruning iterations (Default: 5).
- `experimentName`: Output directory name where results are saved.
- `useAdaptive`: If `true`, stops dynamically when `<30` colors remain.
- `numInitialColors`: Initial number of clusters for the K-Means algorithm (Default: 50).
- `plotFigures`: If `true`, saves scatter plots mapping color spaces.

## MATLAB Dependencies
The algorithm relies on standard MATLAB Toolboxes. Ensure you have the following installed:

* **MATLAB R2021a or newer** (Recommended)
* **Image Processing Toolbox** (For `imsegkmeans`, `rgb2lab`, `immse`, `psnr`, `ssim`)
* **Statistics and Machine Learning Toolbox** (For `makedist` and `cdf`)
* **Parallel Computing Toolbox** (Optional, but recommended as the script utilizes `gpuDevice(1)` for faster computation)

## Organization of the Code
* `fuzzy_palette_extractor.m`: Main execution pipeline.
* `compute_perceptual_metrics.m`: Calculates quantitative perceptual distances between extracted palettes and human observations.
* `lib/`: Directory containing helper functions and the logic engine:
  * `fuzzy_system.m`: The core fuzzy logic engine evaluating IF-THEN rules combining Probability, Lightness, and Chroma.
  * `gaussian_membership.m`, `fuzzy_triangle.m`, `fuzzy_left_shoulder.m`, `fuzzy_right_shoulder.m`: Implementations of distinct fuzzy membership curve shapes used during defuzzification.
  * `fisher_discriminant.m`: Computes Fisher's Linear Discriminant to find the optimal "knee" cut-off point for separating relevant vs. irrelevant colors.
  * `paint_image.m`: Reconstructs the input image using the newly extracted subset of relevant colors.
  * `deltaE00_mod.m`, `immse.m`, `meanAbsoluteError.m`: Evaluation metrics used by the system.

## Image Format
To process your own images, place them inside the `./Test_Images` folder.
- Supported formats: `.jpg`, `.JPG`, `.png`, `.PNG`.
- The script automatically skips grayscale/black-and-white images.

## Cite
If you use this work, please consider citing our paper:

```bibtex
% Coming Soon
```

## Acknowledgements
This work has been supported by grant PID2022-141539NB-I00, funded by MICIU/AEI/10.13039/501100011033 and by ERDF, EU, and by the Government of Aragon’s Departamento de Ciencia, Universidad y Sociedad del Conocimiento through the Reference Research Group "Graphics and Imaging Lab". Samuel Morillas acknowledges the support of Generalitat Valenciana under grant IMaLeVICS CIAICO-2022-051 and Spanish Agencia Estatal de Investigación under grants PID2022-140189OB-C21 and PID2023-152301OB-I00. J. Daniel Subias was supported by the CUS/702/2022 predoctoral grant. Juan Luis Nieves also ackowledges the Erasmus+ master Computational Colur and Spectral Imaging for supporting this work at the University of Granada. We would like to thank all the members of the Graphics and Imaging Laboratory who helped proofread the text.

## Contact
```
dsubias@unizar.es (Daniel Subías)
```

## Disclaimer
The code from this repository is from a research project, under active development. Please use it with caution and contact us if you encounter any issue.

## License
This software is under GNU General Public License Version 3 (GPLv3), please see GNU License For commercial purposes, please contact the authors.
