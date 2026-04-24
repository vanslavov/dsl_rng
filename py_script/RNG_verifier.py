import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import shutil
import time
import os

from scipy.stats import chisquare, norm
from statsmodels.sandbox.stats.runs import runstest_1samp

# ---------------- CONFIG ----------------
SOURCE_FILE = r"C:\Users\temp\Downloads\For UART testing\signal_log.csv"
TEMP_FILE   = r"C:\Users\temp\Downloads\For UART testing\signal_log_copy.csv"

NUM_BINS = 50

# ---------------- SAFE COPY FUNCTION ----------------
def safe_copy(src, dst, retries=5, delay=0.5):
    for i in range(retries):
        try:
            if os.path.exists(dst):
                os.remove(dst)

            shutil.copy2(src, dst)
            return True
        except Exception as e:
            print(f"[Copy attempt {i+1}] File busy, retrying...")
            time.sleep(delay)

    return False

# ---------------- COPY SNAPSHOT ----------------
print("Creating stable snapshot...")

if not safe_copy(SOURCE_FILE, TEMP_FILE):
    raise RuntimeError("Failed to safely copy CSV file")

print("Snapshot created.")

# ---------------- LOAD DATA ----------------
data = pd.read_csv(TEMP_FILE, on_bad_lines='skip')
values = data['value'].to_numpy(dtype=np.uint32)

print(f"Loaded {len(values)} samples")

# Normalize
values_norm = values / np.max(values)

# ---------------- 1. CHI-SQUARE ----------------
counts, bin_edges = np.histogram(values_norm, bins=NUM_BINS)
expected = np.ones_like(counts) * np.mean(counts)

chi_stat, p_value = chisquare(counts, expected)

print("\n--- Chi-Square Test ---")
print(f"Chi-square: {chi_stat}")
print(f"P-value: {p_value}")

if p_value > 0.05:
    print("✅ PASS (uniform)")
else:
    print("❌ FAIL (non-uniform)")

# ---------------- 2. HISTOGRAM (FAST) ----------------
bin_centers = (bin_edges[:-1] + bin_edges[1:]) / 2

plt.figure()
plt.bar(bin_centers, counts, width=(bin_edges[1]-bin_edges[0]))
plt.title("Uniform Distribution (Snapshot)")
plt.xlabel("Normalized Value")
plt.ylabel("Frequency")
plt.show()

# ---------------- 3. AUTOCORRELATION ----------------
def autocorr(x, lag):
    return np.corrcoef(x[:-lag], x[lag:])[0, 1]

print("\n--- Autocorrelation ---")
for lag in [1, 2, 5, 10]:
    r = autocorr(values_norm, lag)
    print(f"Lag {lag}: {r}")

# ---------------- 4. RUNS TEST ----------------
z_stat, runs_p = runstest_1samp(values_norm)

print("\n--- Runs Test ---")
print(f"Z-stat: {z_stat}")
print(f"P-value: {runs_p}")

if runs_p > 0.05:
    print("✅ PASS (random ordering)")
else:
    print("❌ FAIL (non-random ordering)")

# ---------------- 5. GAUSSIAN TRANSFORM ----------------
subset = values_norm[:200000]  # speed optimization

N = len(subset) // 2
u1 = subset[:N]
u2 = subset[N:2*N]

z0 = np.sqrt(-2 * np.log(u1 + 1e-10)) * np.cos(2 * np.pi * u2)

mu, std = norm.fit(z0)

plt.figure()
plt.hist(z0, bins=50, density=True)

x = np.linspace(min(z0), max(z0), 200)
plt.plot(x, norm.pdf(x, mu, std))

plt.title("Gaussian Check (Box-Muller Transform)")
plt.xlabel("Value")
plt.ylabel("Density")
plt.show()

print("\n--- Gaussian Fit ---")
print(f"Mean: {mu}")
print(f"Std Dev: {std}")

print("\nAnalysis complete.")