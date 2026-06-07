"""Run the synthetic Bayesian observer demo."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from bayesian_heading_observer.model import write_demo_outputs


def main() -> None:
    output_dir = ROOT / "outputs"
    write_demo_outputs(output_dir)
    print(f"Wrote {output_dir / 'model_prediction.png'}")
    print(f"Wrote {output_dir / 'posterior_heatmap.png'}")


if __name__ == "__main__":
    main()
