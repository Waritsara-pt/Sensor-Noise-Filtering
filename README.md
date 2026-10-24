# Sensor Noise Filtering System

A sensor signal processing project focused on reducing noise in sensor measurements using digital filtering techniques and MATLAB.

## Overview

Sensor measurements are often affected by noise from environmental conditions, vibration, and electronic interference. These disturbances can cause signal fluctuations and reduce measurement reliability.

This project aims to analyze noisy sensor signals and apply appropriate digital filters to reduce unwanted noise while preserving important signal characteristics.

The system is developed using MATLAB and is designed to support experiments with both simulated signals and real sensor data collected through an ESP32 microcontroller.

## Objectives

Study the characteristics of noise in sensor signals.

Implement and compare different digital filtering techniques.

Develop a MATLAB-based workflow for analyzing and filtering sensor data.

Experiment with simulated signals and real-world sensor measurements.

Evaluate filtering performance through signal visualization and comparison.

## Filtering Techniques

The project explores the following digital filters:

Moving Average Filter — smooths short-term fluctuations in a signal.

Median Filter — helps reduce impulse noise and outliers.

Low-Pass Filter — attenuates high-frequency components.

High-Pass Filter — attenuates low-frequency components.

The filtering methods can be evaluated individually or in different sequences to investigate their effects on the output signal.

## Hardware

ESP32 microcontroller

MAX30102 pulse oximeter and heart-rate sensor

MPU6050 accelerometer and gyroscope

TCS34725 RGB color sensor

## Software and Tools

MATLAB — signal processing, filtering, and visualization

Arduino IDE — ESP32 programming and sensor data acquisition

VS code — serial data collection and CSV file generation

Git and GitHub — version control and project documentation

## Workflow

Collect sensor data using the ESP32.

Export the recorded measurements to CSV files.

Import the data into MATLAB.

Analyze the raw signals and identify potential noise characteristics.

Apply digital filters to the input signals.

Compare the raw and filtered signals using plots and relevant measurements.

## Project Status

### In Progress

The project is being developed through simulated signal experiments and real sensor data testing. Further work focuses on improving filter selection, evaluating filtering performance, and exploring sequential filtering strategies.

## Repository Structure

The repository may include the following components as development progresses:

matlab/ — MATLAB scripts for signal analysis and filtering

arduino/ — ESP32 firmware for sensor data acquisition

python/ — scripts for recording sensor data to CSV

data/ — sample datasets for experiments

results/ — plots and experimental results

## Authors

This project was developed as part of a Signal Processing mini-project.

- Miss Kingkusuma Suttipunyo 67050545

- Mr. Khodchaphak Iam-saart 67050547

- Miss Jarinya Hannakhon 67050549

- Mr. Narongchai Vongsa-ad 67050552

- Miss Waritsar Pungtui 67050576
