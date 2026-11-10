# Flight data (FDR) extraction and plotting in MATLAB

These scripts do the same work as the Python scripts `Radar_Standard_Data.py`,
`Graphing_Radar.py`, `FBW_Standard_Data.py` and `Merged_Data_Final.py`, but
take the FDR data from **Excel** files.

Needs MATLAB R2020b or newer. No toolboxes are required.

## Quick start

1. Put this folder on the MATLAB path, or copy the `.m` files next to your data.
2. `cd` to the folder that holds your Excel files.
3. Open a `run_*.m` script, edit its **SETTINGS** block (file names, the row that
   holds the parameter names, the sample rate), then press **F5**.
4. The results are written to an `output` subfolder.

| Script | Replaces | Produces |
|---|---|---|
| `run_radar_analysis.m` | `Radar_Standard_Data.py` + `Graphing_Radar.py` | `Data Merge_Kvik_211_226_Parameters.xlsx`, one resampled `.xlsx` per merged file, `Qvik_Rai_Radar.fig/.png`, `Qvik_Rai_Radar_226.fig/.png` |
| `run_fbw_plot.m` | `FBW_Standard_Data.py` | `FBW_Andy_Rai_Basic_1.fig/.png` |
| `run_merge_16hz.m` | `Merged_Data_Final.py` | `Merged_Data.xlsx` |

The `.fig` files are the MATLAB equivalent of the Plotly `.html` files: they open
as interactive figures. The `.png` files are for reports.

## Functions

| Function | Purpose |
|---|---|
| `fdr_read_excel` | Read one Excel export. Trims spaces from the parameter names, renames the time column to `Time`, converts numeric text to numbers, sorts by time and drops duplicate time stamps. |
| `fdr_sample_rate_check` | Prints how many samples each second contains, plus the nominal rate and the largest gap. Use it to find dropouts. |
| `fdr_resample` | Puts the data on a regular grid of `fs` samples per second. `'first'` matches the Python scripts; `'mean'` and `'linear'` are also available. |
| `fdr_merge` | Inner join on `Time`. Duplicate parameter names get a `_<label>` suffix, and the number of surviving rows is reported. |
| `fdr_write_excel` | Writes a fresh `.xlsx` file without an index column, after checking Excel's size limits. |
| `fdr_multiaxis_plot` | Time-history plot with any number of y-axes on the left and right. Zoom and pan act on time for all traces, data tips work, and clicking a legend entry hides or shows that trace. |
| `fdr_link_axes` | Restores the shared time axis after reopening a saved `.fig` file. |

### Defining a plot

```matlab
ax = @(label, params, side, color) struct('Label', label, 'Params', {params}, ...
    'Side', side, 'Color', color);

spec = [
    ax('Height (m)', {'Height'},       'left',  '#0000FF')   % main axis
    ax('Speed',      {'Vind#3'},       'left',  '#FF0000')   % stacked further left
    ax('AOA',        {'ATTACKangl_1'}, 'right', '#006400')
    ];
fdr_multiaxis_plot(T, spec, 'Title', 'My plot', 'OutFile', 'output/my_plot');
```

Parameter names are the Excel column headers with leading and trailing spaces
removed (for example `'226_Tgt_Elev '` becomes `'226_Tgt_Elev'`). If a name is
not found, a warning lists similar names and the plot is still drawn.

## Differences from the Python scripts

- Works with current MATLAB releases. The Python scripts fail on pandas 2 and Plotly 6.
- The FBW plot puts the `Stick_Pitch` and `Stab_L` axis titles on the correct traces.
- Duplicate parameter names in merged files get readable suffixes instead of `_x` and `_y`.
- `run_merge_16hz.m` stores the 16 Hz grid time in `Time`, not the original time stamp of the first file.
- Sample-rate results are printed rather than left in workspace variables.
