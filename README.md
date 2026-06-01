<p align="center">
  <h1 align="center">Human Body Communication (HBC)<br>FEMM Simulation Models</h1>
</p>

<p align="center">
  <strong>Finite Element Analysis of Electro-Quasistatic Human Body Communication Channels</strong><br>
  International Institute of Information Technology, Bangalore (IIIT-B)
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Simulation-FEMM_4.2-blue?style=flat-square" alt="FEMM">
  <img src="https://img.shields.io/badge/Language-Python_|_Lua-critical?style=flat-square" alt="Languages">
  <img src="https://img.shields.io/badge/Domain-Human_Body_Communication-informational?style=flat-square" alt="Domain">
  <img src="https://img.shields.io/badge/Status-Completed-brightgreen?style=flat-square" alt="Status">
</p>

---

## Table of Contents

* [Overview](#overview)
* [Motivation](#motivation)
* [Simulation Models](#simulation-models)
* [Key Features](#key-features)
* [Technical Highlights](#technical-highlights)
* [Repository Structure](#repository-structure)
* [Literature Survey](#literature-survey)
* [Prerequisites](#prerequisites)
* [Installation](#installation)
* [Authors](#authors)
* [License](#license)

---

## Overview

This repository contains Finite Element Method (FEM) simulation models, documentation, and literature survey materials for characterizing Human Body Communication (HBC) channels in the Electro-Quasistatic (EQS) regime.

The project uses **FEMM 4.2** to analyze:

* Potential distributions
* Channel gain
* Electric field propagation
* Capacitive return paths
* Electrode coupling behavior

The work supports research on galvanic and capacitive Human Body Communication channels using realistic multilayer biological tissue models.

---

## Motivation

Human Body Communication (HBC) enables ultra-low-power and secure communication using the human body as a transmission medium. Compared to conventional RF communication, HBC offers:

* Lower power consumption
* Reduced signal leakage
* Improved privacy and security
* Better suitability for wearable and biomedical devices

This project investigates the electrical characteristics of HBC channels using FEM-based simulations to better understand signal propagation and return-path behavior.

---

## Simulation Models

| File                           | Description                                                         |
| :----------------------------- | :------------------------------------------------------------------ |
| `galvanic_planar_auto.py`      | Automated Python-based planar EQS simulation with parametric sweeps |
| `galvanic_cylindrical.lua`     | Axisymmetric cylindrical arm model with skin and muscle layers      |
| `capacitive_cross_section.lua` | Cross-sectional multilayer arm model for capacitive HBC analysis    |

---

## Key Features

| Feature                             | Description                                     |
| :---------------------------------- | :---------------------------------------------- |
| **EQS HBC Modeling**                | Electro-Quasistatic channel characterization    |
| **Multilayer Tissue Modeling**      | Bone, muscle, fat, and skin simulation          |
| **Galvanic & Capacitive HBC**       | Analysis of both coupling mechanisms            |
| **Parametric Sweeps**               | Electrode geometry and channel-length variation |
| **Potential Distribution Analysis** | Electric field visualization                    |
| **Return Path Characterization**    | Capacitive coupling analysis                    |

---

## Technical Highlights

### Tissue Layers Modeled

* Skin
* Fat
* Muscle
* Bone

### Simulation Approaches

* 2D planar FEM simulations
* Axisymmetric cylindrical modeling
* Capacitive return-path analysis
* Parametric geometry sweeps

### Analysis Metrics

* Channel gain
* Electric potential distribution
* Coupling capacitance
* Signal attenuation

---

## Repository Structure

```text
.
├── src/
│   ├── galvanic_planar_auto.py
│   ├── galvanic_cylindrical.lua
│   └── capacitive_cross_section.lua
│
├── docs/
│   ├── manuscript/
│   ├── reports/
│   └── configurations/
│
├── literature/
│
├── requirements.txt
└── README.md
```

---

## Literature Survey

The repository includes foundational papers related to:

* Electro-Quasistatic HBC
* Galvanic coupling
* Capacitive return paths
* FEM-based HBC modeling
* Wearable-to-ground communication channels

---

## Prerequisites

The following tools are required:

1. **FEMM 4.2**
2. **Python 3.x**
3. **pyFEMM**

---

## Installation

```bash
pip install -r requirements.txt
```

---

## Authors

| Name           | Affiliation    |
| :------------- | :------------- |
| Siddhant Deore | IIIT Bangalore |
| Pratham Shetty | IIIT Bangalore |

---

## License

This project is intended for academic and research purposes.

---

<p align="center">
  <sub>© 2026 · IIIT Bangalore · Human Body Communication Research Project</sub>
</p>
