import os
import sys
from textwrap import wrap

import matplotlib

if os.environ.get("DISPLAY", "") == "" and sys.platform != "win32":
    matplotlib.use("Agg")

import matplotlib.pyplot as plt
from matplotlib.patches import Circle


def _format_items(items, width=18):
    """Format set contents as wrapped text for display inside circles."""
    items = sorted(set(items), key=str)
    if not items:
        return "• (empty)"

    lines = []
    for item in items:
        wrapped = wrap(str(item), width=width)
        if not wrapped:
            lines.append("•")
        else:
            first = True
            for part in wrapped:
                prefix = "• " if first else "  "
                lines.append(f"{prefix}{part}")
                first = False
    return "\n".join(lines)


def create_venn_diagram(set_a, set_b, label_a="Set A", label_b="Set B"):
    """
    Draw a 2-circle Venn diagram with set contents rendered as text inside each circle.
    This approach is more reliable than matplotlib-venn when the regions contain long labels.
    """
    set_a = set(set_a)
    set_b = set(set_b)

    fig, ax = plt.subplots(figsize=(10, 8))

    left_circle = Circle((-1.2, 0), 1.7, facecolor="lightblue", edgecolor="black", linewidth=2, alpha=0.6)
    right_circle = Circle((1.2, 0), 1.7, facecolor="lightcoral", edgecolor="black", linewidth=2, alpha=0.6)
    ax.add_patch(left_circle)
    ax.add_patch(right_circle)

    ax.set_xlim(-3, 3)
    ax.set_ylim(-1.8, 2.7)
    ax.set_aspect("equal")
    ax.axis("off")

    ax.text(-1.5, 2.5, label_a, ha="center", va="center", fontsize=18, fontweight="bold")
    ax.text(0.0, 2.15, "Potential\nConcurrency Loss", ha="center", va="center", fontsize=18, fontweight="bold")
    ax.text(1.6, 2.5, label_b, ha="center", va="center", fontsize=18, fontweight="bold")

    left_text = _format_items(set_a - set_b, width=18)
    right_items = sorted(set(set_b - set_a), key=str)
    right_text = _format_items(right_items, width=18)
    overlap_text = _format_items(set_a & set_b, width=18)

    ax.text(-1.5, 0.1, left_text, ha="center", va="center", fontsize=18, linespacing=2.5, fontweight="bold")
    ax.text(1.7, 0.1, right_text, ha="center", va="center", fontsize=18, linespacing=2.4, fontweight="bold")

    # Draw arrows from each right-hand item toward the diagram center.
    # Align them with the rendered text rows in the right-hand box.
    right_box_x = 1.5
    line_height = 0.42
    start_x = .6
    end_x = .1
    text_top = 0.1 + (len(right_items) - 1) * line_height / 2

    for idx, item in enumerate(right_items):
        if not item:
            continue
        y_text = text_top - idx * line_height
        y_start = y_text #+ 0.1
        y_end = y_text #+ 0.1
        ax.annotate(
            "",
            xy=(end_x, y_end),
            xytext=(start_x, y_start),
            arrowprops=dict(arrowstyle="->", lw=2.5, color="black", mutation_scale=18, shrinkA=0, shrinkB=0),
        )

    # ax.text(0, -0.1, overlap_text, ha="center", va="center", fontsize=15, linespacing=2.5)

    #ax.set_title("Script Compatibility", fontsize=16, fontweight="bold", pad=20)

    output_path = "venn_diagram.png"
    fig.savefig(output_path, dpi=200, bbox_inches="tight")

    if os.environ.get("DISPLAY", ""):
        plt.show()
    else:
        print(f"Saved diagram to {output_path}")

    plt.close(fig)
    return fig


if __name__ == "__main__":
    # Example usage
    set_1 = ['Sequential or Concurrent Processes']
    set_2 = ['Process or Thread Parallelism']

    create_venn_diagram(
        set_1,
        set_2,
        label_a="Compatible",
        label_b="Incompatible",
    )
