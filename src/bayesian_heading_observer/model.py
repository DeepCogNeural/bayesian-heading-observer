"""Compact Bayesian observer model used by the synthetic demo.

The original research code is MATLAB and is kept under `matlab/original`.
This Python module is intentionally small: it gives interviewers a runnable
version of the core modeling idea without publishing subject-level data.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from scipy.special import i0


@dataclass(frozen=True)
class ObserverParams:
    """Parameters for the synthetic Bayesian heading observer demo."""

    sensory_kappa: float = 14.0
    action_gain: float = 0.72
    n_grid: int = 721
    prior_width_deg: float = 18.0
    prior_mixture_weight: float = 0.82


def wrap_angle(x: np.ndarray) -> np.ndarray:
    """Wrap angles to [-pi, pi)."""

    return (x + np.pi) % (2 * np.pi) - np.pi


def von_mises_pdf(x: np.ndarray, mu: np.ndarray, kappa: float) -> np.ndarray:
    """Von Mises density on a circular heading axis."""

    return np.exp(kappa * np.cos(wrap_angle(x - mu))) / (2 * np.pi * i0(kappa))


def normalize_density(x: np.ndarray, density: np.ndarray, axis: int = -1) -> np.ndarray:
    """Normalize a density with trapezoidal integration."""

    area = np.trapezoid(density, x=x, axis=axis)
    return density / np.expand_dims(area, axis)


def synthetic_heading_prior(theta: np.ndarray, params: ObserverParams) -> np.ndarray:
    """Build a center-biased prior over heading directions."""

    sigma = np.deg2rad(params.prior_width_deg)
    center_bias = np.exp(-0.5 * (wrap_angle(theta) / sigma) ** 2)
    broad = np.ones_like(theta)
    prior = params.prior_mixture_weight * center_bias + (1 - params.prior_mixture_weight) * broad
    return normalize_density(theta, prior)


def circular_mean(angles: np.ndarray, weights: np.ndarray, axis: int = -1) -> np.ndarray:
    """Weighted circular mean."""

    sin_sum = np.sum(weights * np.sin(angles), axis=axis)
    cos_sum = np.sum(weights * np.cos(angles), axis=axis)
    return np.arctan2(sin_sum, cos_sum)


def circular_std(angles: np.ndarray, weights: np.ndarray, axis: int = -1) -> np.ndarray:
    """Circular standard deviation approximation."""

    sin_sum = np.sum(weights * np.sin(angles), axis=axis)
    cos_sum = np.sum(weights * np.cos(angles), axis=axis)
    r = np.sqrt(sin_sum**2 + cos_sum**2)
    r = np.clip(r, 1e-12, 1.0)
    return np.sqrt(-2 * np.log(r))


def run_observer_demo(params: ObserverParams = ObserverParams()) -> dict[str, np.ndarray]:
    """Run a synthetic Bayesian observer plus perception-action mapping demo."""

    theta = np.linspace(-np.pi, np.pi, params.n_grid, endpoint=False)
    prior = synthetic_heading_prior(theta, params)

    cdf = np.cumsum(prior)
    cdf = cdf / cdf[-1]
    sensory_axis = wrap_angle(2 * np.pi * cdf - np.pi)

    th_sensory = np.interp(theta, theta, sensory_axis)
    m_sensory = th_sensory.copy()
    likelihood = von_mises_pdf(m_sensory[None, :], th_sensory[:, None], params.sensory_kappa)
    likelihood = normalize_density(m_sensory, likelihood, axis=1)

    posterior = likelihood * prior[:, None]
    posterior = normalize_density(theta, posterior, axis=0)
    estimator_by_measurement = circular_mean(theta[:, None], posterior, axis=0)
    report_by_measurement = wrap_angle(params.action_gain * estimator_by_measurement)

    stimulus_deg = np.arange(-42, 43, 6)
    stimulus = np.deg2rad(stimulus_deg)
    response_mean = []
    response_std = []
    response_heatmap = []

    response_bins = np.linspace(-np.pi / 2, np.pi / 2, 181)
    response_centers = 0.5 * (response_bins[:-1] + response_bins[1:])

    for value in stimulus:
        idx = int(np.argmin(np.abs(wrap_angle(theta - value))))
        measurement_weights = likelihood[idx]
        measurement_weights = measurement_weights / measurement_weights.sum()
        response_mean.append(circular_mean(report_by_measurement, measurement_weights))
        response_std.append(circular_std(report_by_measurement, measurement_weights))
        hist, _ = np.histogram(report_by_measurement, bins=response_bins, weights=measurement_weights)
        response_heatmap.append(hist / max(hist.sum(), 1e-12))

    return {
        "theta": theta,
        "prior": prior,
        "stimulus_deg": stimulus_deg.astype(float),
        "response_mean_deg": np.rad2deg(np.array(response_mean)),
        "response_std_deg": np.rad2deg(np.array(response_std)),
        "response_centers_deg": np.rad2deg(response_centers),
        "response_heatmap": np.array(response_heatmap).T,
    }


def write_demo_outputs(output_dir: str | Path = "outputs") -> None:
    """Write expected demo plots."""

    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    result = run_observer_demo()

    stim = result["stimulus_deg"]
    bias = result["response_mean_deg"] - stim

    fig, ax = plt.subplots(figsize=(8, 4.8))
    ax.axhline(0, color="0.7", linewidth=1)
    ax.axvline(0, color="0.85", linewidth=1)
    ax.plot(stim, bias, marker="o", color="#1d4ed8", linewidth=2, label="predicted bias")
    ax.fill_between(
        stim,
        bias - 0.25 * result["response_std_deg"],
        bias + 0.25 * result["response_std_deg"],
        color="#93c5fd",
        alpha=0.35,
        label="scaled response variability",
    )
    ax.set_xlabel("Actual heading (deg)")
    ax.set_ylabel("Response bias (deg)")
    ax.set_title("Synthetic Bayesian observer with perception-action gain")
    ax.legend(frameon=False)
    fig.tight_layout()
    fig.savefig(output / "model_prediction.png", dpi=180)
    plt.close(fig)

    fig, ax = plt.subplots(figsize=(8, 5.2))
    extent = [
        float(stim.min()),
        float(stim.max()),
        float(result["response_centers_deg"].min()),
        float(result["response_centers_deg"].max()),
    ]
    im = ax.imshow(
        result["response_heatmap"],
        origin="lower",
        aspect="auto",
        extent=extent,
        cmap="viridis",
    )
    ax.plot(stim, result["response_mean_deg"], color="white", linewidth=2, label="mean report")
    ax.set_xlabel("Actual heading (deg)")
    ax.set_ylabel("Reported heading (deg)")
    ax.set_title("Predicted response distribution")
    ax.legend(frameon=False, loc="upper left")
    fig.colorbar(im, ax=ax, label="probability")
    fig.tight_layout()
    fig.savefig(output / "posterior_heatmap.png", dpi=180)
    plt.close(fig)


if __name__ == "__main__":
    write_demo_outputs()
