# satellite-network-slicing-ran
Simulating how 5G network slicing works in satellite systems —  three LEO satellites, three service types, one ground station.  Built with MATLAB's Satellite Communications Toolbox.
# Network Slicing in Satellite Systems for RAN

**Course**: Satellite Communications — Cleveland State University  
**Authors**: Nikhil Reddy Kuntloor, Supriya Rayabandi

## Overview
Simulation of 3GPP-compliant network slicing across LEO satellites using MATLAB's 
Satellite Communications Toolbox. Three slices (eMBB, URLLC, mMTC) are assigned 
to separate satellites communicating with a ground station in Cleveland, OH.

## Files
| File | Description |
|------|-------------|
| `satellite14.m` | Main MATLAB simulation script |
| `final_report_sat_comm.pdf` | Full research paper |
| `FINAL_PRESENTATION_SAT_COM_1.pptx` | Project presentation slides |

## How to Run
1. Requires MATLAB with **Satellite Communications Toolbox**
2. Open `satellite14.m` and run — no additional setup needed
3. The script generates 5 plots: 3D viewer, access windows, target KPIs, 
   dynamic throughput, and dynamic latency

## Key Results
- Simulated 3 LEO satellites at 700 km altitude, 55° inclination
- Priority-based bandwidth allocation: URLLC (5) > eMBB (3) > mMTC (1)
- Dynamic throughput and latency computed over 360 time steps (1-hour window)

## Technologies
MATLAB · Satellite Communications Toolbox · 3GPP NTN · LEO constellation modeling
