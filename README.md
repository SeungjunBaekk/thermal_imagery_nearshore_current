# Nearshore surface currents from a drone-mounted thermal camera: field data and figure scripts

This repository contains the processed field data and the MATLAB scripts that reproduce Figures 4 and 6–15 of the article

> Baek, S., Park, Y.S., Hur, J., Jeong, H. *Nearshore surface currents from a drone-mounted uncooled thermal camera using adaptive thermal image velocimetry (AThIVe).* Submitted to *Coastal Engineering*.

The data were collected at Mallipo Beach, on the west coast of the Taean Peninsula, South Korea, on 14–15 July 2026. Each figure has one NetCDF file with the data it plots and one script that reads the file, computes the statistics shown, and draws the figure.

## Contents

| Figure | Script | Data file | Content |
|---|---|---|---|
| 4 | `fig04_analysis_windows.m` | `data/fig04_analysis_windows.nc` | Tide and drone altitude of the five video records |
| 6 | `fig06_model_setup.m` | `data/fig06_model_setup.nc` | Model bathymetry (SWAN grids, SWASH bed) and forcing (buoy waves, KMA wind) |
| 7 | `fig07_swash_maps.m` | `data/fig07_swash_maps.nc` | SWASH time-mean velocity and wave energy dissipation rate |
| 8 | `fig08_swash_profiles.m` | `data/fig08_swash_profiles.nc` | Cross-shore SWASH profiles with observations at the APF and the ACM |
| 9 | `fig09_velocity_series.m` | `data/fig09_velocity_series.nc` | Cross-shore velocity at the APF from AThIVe and the profiler depth mean |
| 10 | `fig10_mean_fields.m` | `data/fig10_mean_fields.nc` | Time-mean AThIVe surface velocity fields |
| 11 | `fig11_mean_currents.m` | `data/fig11_mean_currents.nc` | Mean current at the APF from AThIVe, SWASH, the profiler, and RGB PIV |
| 12 | `fig12_apf_profiles.m` | `data/fig12_apf_profiles.nc` | Vertical structure of the mean current at the APF |
| 13 | `fig13_wind_excess.m` | `data/fig13_wind_excess.nc` | Surface-current excess relative to the KMA 10-m wind |
| 14 | `fig14_phase_ensembles.m` | `data/fig14_phase_ensembles.nc` | Wave-phase ensembles and velocity spectra at the APF |
| 15 | `fig15_dispersion_slice.m` | `data/fig15_dispersion_slice.nc` | Wavenumber–frequency spectra of the visible video around the APF |

The header of each script lists every variable in its data file, with units, and describes the computations.

Not included in this repository:
- Figures 1–3 (example imagery, flowchart, and site map), Figure 5 (frames of the raw visible video), and the appendix figures.
- The AThIVe processing code.
- The raw drone videos and the raw instrument records. These are available from the corresponding author on request.

## Field records

| Record | Start (KST) | Analysis interval (s from video start) | Wave breaking |
|---|---|---|---|
| D1V1 | 14 Jul 2026 13:24 | 85–345 | at APF |
| D1V2 | 14 Jul 2026 13:45 | 89–183 | at APF |
| D2V1 | 15 Jul 2026 07:11 | 15–150 | none |
| D2V2 | 15 Jul 2026 07:33 | 15–400 | none |
| D2V3 | 15 Jul 2026 07:48 | 15–380 | seaward of APF |

## Conventions

- **Format.** NetCDF-4. Each file has one group per record (`/D1V1`, `/D1V2`, `/D2V1`, `/D2V2`, `/D2V3`). Figure 15 covers only D1V2, D2V2, and D2V3. Variables shared by all records are stored at the root. Every variable has `units` and `long_name` attributes. The global attributes give the title, the figure number, the coordinate system, and the time reference.
- **Coordinates.** Local frame with the origin at the APF. *x* points shoreward, toward 119° from grid north (UTM zone 52N), and *y* points alongshore, toward 29°. Figure 6 also uses UTM 52N easting and northing.
- **Time.** Korea Standard Time (KST, UTC+9). Depending on the variable, time is given as hours or seconds since 2026-07-14 00:00 KST, or as seconds from the start of the video. The `units` attribute of each time variable states which.
- **Elevation.** Metres relative to mean sea level (MSL).
- **Missing values.** NaN marks missing or rejected samples.
- **Abbreviations.**
  - APF: upward-looking acoustic Doppler profiler on the bed.
  - ACM: side-looking acoustic current meter shoreward of the APF.
  - AThIVe: surface velocity from the thermal video.
  - RGB PIV: particle image velocimetry of the simultaneous visible video.
  - SWAN–SWASH: wave and circulation model runs.
  - KMA: Korea Meteorological Administration (buoy 22307 and modeled 10-m wind).

## Requirements and usage

The scripts were tested with MATLAB R2024b. `fig08`, `fig09`, `fig13`, and `fig14` also require the Signal Processing Toolbox.

Run a script from the repository root, for example:

```matlab
fig09_velocity_series
```

Each script draws its figure. To write PNG and PDF files, set `op.exportFig = true` in section 0 of the script.

## Differences from the published figures

- The bootstrap intervals in Figures 8, 11, 12, and 13 depend on random resampling. They differ from the published figures by up to 0.003 m s⁻¹ in magnitude and 2.2° in direction.
- In Figure 6(d), the record lines are drawn at the exact video start times. In the published figure, these times were rounded down to the minute.

## Citation

If you use these data, please cite the article above and this dataset:

> Baek, S., Park, Y.S., Hur, J., Jeong, H. (2026). *Field data and figure scripts for "Nearshore surface currents from a drone-mounted uncooled thermal camera using adaptive thermal image velocimetry (AThIVe)."* Zenodo. DOI: https://doi.org/10.5281/zenodo.24537293

## License

The data and scripts are released under the [Creative Commons Attribution 4.0 International License (CC BY 4.0)](https://creativecommons.org/licenses/by/4.0/).

## Contact

Seungjun Baek, Department of Civil and Environmental Engineering, Seoul National University, tmdwns950@snu.ac.kr
