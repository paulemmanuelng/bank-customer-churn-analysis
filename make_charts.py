"""
make_charts.py
Reads churn.db and saves three charts into charts/.

Run (after building the database, see README):
    python3 make_charts.py
"""

import sqlite3
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

DB = "churn.db"
OUT = Path("charts")
OUT.mkdir(exist_ok=True)

RED = "#E24B4A"      # above-average churn (bad)
BLUE = "#185FA5"     # at/below-average churn
GRAY = "#888888"

con = sqlite3.connect(DB)

# Overall churn rate, used as a reference line on the charts
overall = con.execute(
    "SELECT 100.0 * SUM(exited) / COUNT(*) FROM customers"
).fetchone()[0]


def bar_rate_chart(rows, xlabel, title, filename):
    """Draw a vertical bar chart of churn rate, with the overall rate line."""
    labels = [str(r[0]) for r in rows]
    rates = [r[1] for r in rows]
    colors = [RED if v > overall else BLUE for v in rates]

    fig, ax = plt.subplots(figsize=(8, 5))
    bars = ax.bar(labels, rates, color=colors)
    ax.axhline(overall, color=GRAY, linestyle="--", linewidth=1)
    ax.text(len(labels) - 0.5, overall + 2, f"overall {overall:.1f}%",
            color=GRAY, fontsize=9, ha="right")
    for b, v in zip(bars, rates):
        ax.text(b.get_x() + b.get_width() / 2, v + 1.5, f"{v:.0f}%",
                ha="center", fontsize=10)
    ax.set_ylabel("Churn rate (%)")
    ax.set_xlabel(xlabel)
    ax.set_title(title)
    ax.set_ylim(0, 110)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    fig.savefig(OUT / filename, dpi=150, facecolor="white")
    plt.close(fig)


# Chart 1: churn by number of products
rows = con.execute(
    "SELECT num_products, ROUND(100.0*SUM(exited)/COUNT(*),1) "
    "FROM customers GROUP BY num_products ORDER BY num_products"
).fetchall()
bar_rate_chart(rows, "Number of products held",
               "Churn explodes past 2 products", "churn_by_products.png")

# Chart 2: churn by age band
rows = con.execute(
    """
    SELECT CASE WHEN age<30 THEN '18-29' WHEN age<40 THEN '30-39'
                WHEN age<50 THEN '40-49' WHEN age<60 THEN '50-59'
                ELSE '60+' END AS band,
           ROUND(100.0*SUM(exited)/COUNT(*),1)
    FROM customers GROUP BY band ORDER BY band
    """
).fetchall()
bar_rate_chart(rows, "Age band",
               "Mid-life customers churn most", "churn_by_age.png")

# Chart 3: where the lost customers actually are (volume, not just rate)
seg = con.execute(
    """
    SELECT 'Single product' AS s, SUM(exited) AS churned, ROUND(100.0*SUM(exited)/COUNT(*),1) AS rate FROM customers WHERE num_products = 1
    UNION ALL SELECT 'Inactive members', SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE is_active_member = 0
    UNION ALL SELECT 'Female', SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE gender = 'Female'
    UNION ALL SELECT 'Germany', SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE geography = 'Germany'
    UNION ALL SELECT 'Age 50-59', SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE age BETWEEN 50 AND 59
    UNION ALL SELECT '3-4 products', SUM(exited), ROUND(100.0*SUM(exited)/COUNT(*),1) FROM customers WHERE num_products >= 3
    ORDER BY churned ASC
    """
).fetchall()
names = [r[0] for r in seg]
churned = [r[1] for r in seg]
rates = [r[2] for r in seg]

fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.barh(names, churned, color=BLUE)
for b, n, rt in zip(bars, churned, rates):
    ax.text(b.get_width() + 15, b.get_y() + b.get_height() / 2,
            f"{n:,} lost ({rt:.0f}%)", va="center", fontsize=9)
ax.set_xlabel("Number of churned customers")
ax.set_title("Where the lost customers are (volume vs rate)")
ax.set_xlim(0, max(churned) * 1.25)
ax.spines[["top", "right"]].set_visible(False)
fig.tight_layout()
fig.savefig(OUT / "churn_volume_by_segment.png", dpi=150, facecolor="white")
plt.close(fig)

con.close()
print("Saved 3 charts to charts/")
