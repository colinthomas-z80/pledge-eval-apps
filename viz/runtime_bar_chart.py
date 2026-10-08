import csv
from collections import OrderedDict

import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
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
	primary_prefixes = prefixes[:-2] if len(prefixes) > 2 else []
	secondary_prefixes = prefixes[-2:] if len(prefixes) > 2 else prefixes

	values_by_prefix = {prefix: {variant: 0.0 for variant in variants} for prefix in prefixes}
	for prefix, variant, value in rows:
		values_by_prefix[prefix][variant] = value

	x = np.arange(len(prefixes), dtype=float)
	bar_width = 0.8 / max(1, len(variants))

	fig, ax = plt.subplots(figsize=(10, 5))
	ax_right = ax.twinx()
	ax.set_zorder(2)
	ax_right.set_zorder(1)
	ax.patch.set_visible(False)

	left_max = max((values_by_prefix[prefix][variant] for prefix in primary_prefixes for variant in variants), default=0.0)
	right_max = max((values_by_prefix[prefix][variant] for prefix in secondary_prefixes for variant in variants), default=0.0)
	ax.set_ylim(0, left_max * 1.15 if left_max else 1.0)
	ax_right.set_ylim(0, right_max * 1.1 if right_max else 1.0)
	ax.yaxis.set_major_locator(mticker.MaxNLocator(nbins=4))
	ax_right.yaxis.set_major_locator(mticker.MaxNLocator(nbins=4))
	ax.tick_params(axis="y", labelsize=20)
	ax_right.tick_params(axis="y", labelsize=20)

	legend_handles = {}

	for i, variant in enumerate(variants):
		offsets = x - 0.4 + (i + 0.5) * bar_width
		primary_values = [values_by_prefix[prefix][variant] for prefix in primary_prefixes]
		secondary_values = [values_by_prefix[prefix][variant] for prefix in secondary_prefixes]

		bars = ax.bar(offsets[: len(primary_prefixes)], primary_values, width=bar_width, label=variant)
		if bars and variant not in legend_handles:
			legend_handles[variant] = bars

		secondary_bars = []
		if secondary_prefixes:
			secondary_bars = ax_right.bar(
				offsets[len(primary_prefixes) :],
				secondary_values,
				width=bar_width,
				label=variant,
			)
			if secondary_bars and variant not in legend_handles:
				legend_handles[variant] = secondary_bars

		for bar in bars:
			h = bar.get_height()
			if h > 0:
				ax.text(
					bar.get_x() + bar.get_width() / 2,
					h,
					f"{h:.2f}",
					ha="center",
					va="bottom",
					fontsize=20,
				)

		for bar in secondary_bars:
			h = bar.get_height()
			if h > 999:
				ax_right.text(
					bar.get_x() + bar.get_width() / 2,
					h,
					f"{h:.2f}",
					ha="center",
					va="bottom",
					fontsize=20,
				)

	ax.set_xlabel("Application", fontsize=20)
	ax.set_ylabel("Runtime (seconds)", fontsize=20)
	#ax_right.set_ylabel("Runtime (seconds)")
	ax.set_xticks(x)
	ax.set_xticklabels(prefixes, fontsize=18)
	if secondary_prefixes:
		separator_x = len(primary_prefixes) - 0.5
		ax.axvline(separator_x, color="black", linestyle="--", linewidth=1, alpha=1)
	ax.grid(axis="y", linestyle="--", alpha=0.3)
	ax_right.grid(False)

	legend = ax.legend(legend_handles.values(), legend_handles.keys(), loc="lower right", fontsize=20, title_fontsize=20)
	legend.set_zorder(1000)
	plt.tight_layout()
	plt.savefig("grouped_runtimes.png", dpi=300)
	plt.show()


if __name__ == "__main__":
	data = load_grouped_runtimes("runtimes.csv")
	plot_grouped_bars(data)
