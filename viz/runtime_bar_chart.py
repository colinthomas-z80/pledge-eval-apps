import csv
from collections import OrderedDict

import matplotlib.pyplot as plt
import numpy as np


def load_grouped_runtimes(csv_path: str):
	"""Read rows as (prefix, variant, runtime) from `label,value` CSV."""
	rows = []
	with open(csv_path, newline="", encoding="utf-8") as f:
		reader = csv.reader(f)
		for row in reader:
			if not row or len(row) < 2:
				continue

			label = row[0].strip()
			try:
				value = float(row[1].strip())
			except ValueError:
				continue

			if "_" in label:
				prefix, variant = label.split("_", 1)
			else:
				prefix, variant = label, "value"

			rows.append((prefix, variant, value))
	return rows


def plot_grouped_bars(rows):
	if not rows:
		raise ValueError("No valid rows found in runtimes CSV.")

	prefixes = list(OrderedDict((prefix, None) for prefix, _, _ in rows).keys())
	variants = list(OrderedDict((variant, None) for _, variant, _ in rows).keys())

	values_by_prefix = {prefix: {variant: 0.0 for variant in variants} for prefix in prefixes}
	for prefix, variant, value in rows:
		values_by_prefix[prefix][variant] = value

	x = np.arange(len(prefixes), dtype=float)
	bar_width = 0.8 / max(1, len(variants))

	fig, ax = plt.subplots(figsize=(10, 5))

	for i, variant in enumerate(variants):
		offsets = x - 0.4 + (i + 0.5) * bar_width
		variant_values = [values_by_prefix[prefix][variant] for prefix in prefixes]
		bars = ax.bar(offsets, variant_values, width=bar_width, label=variant)

		for bar in bars:
			h = bar.get_height()
			if h > 0:
				ax.text(
					bar.get_x() + bar.get_width() / 2,
					h,
					f"{h:.2f}",
					ha="center",
					va="bottom",
					fontsize=8,
				)

	ax.set_xlabel("Application")
	ax.set_ylabel("Runtime (seconds)")
	ax.set_xticks(x)
	ax.set_xticklabels(prefixes)
	ax.legend(title="Runtime")
	ax.grid(axis="y", linestyle="--", alpha=0.3)

	plt.tight_layout()
	plt.savefig("grouped_runtimes.png", dpi=300)
	plt.show()


if __name__ == "__main__":
	data = load_grouped_runtimes("runtimes.csv")
	plot_grouped_bars(data)
