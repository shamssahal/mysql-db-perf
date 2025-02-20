#!/usr/bin/env python3
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from tabulate import tabulate

def compute_metrics(series):
    desc = series.describe()
    metrics = {
        'count': desc['count'],
        'mean': desc['mean'],
        'median': desc['50%'],
        'std_dev': desc['std'],
        'variance': desc['std'] ** 2,
        'min': desc['min'],
        'max': desc['max'],
        'p90': np.percentile(series, 90),
        'p95': np.percentile(series, 95),
        'p99': np.percentile(series, 99)
    }
    return metrics

def main():
    # Read the CSV files.
    try:
        df_dump = pd.read_csv("dump_create_results.csv")   # expected columns: Run, ddi_t, ss_t, cd_t
        df_perf = pd.read_csv("db_perf_results.csv")         # expected columns: Run, ddi_t, ss_t, dr_t, qe_t
    except Exception as e:
        print("Error reading CSV files:", e)
        return

    # Debug: print head of dataframes to ensure data is loaded.
    print("Dump Create Data:")
    print(df_dump.head(), "\n")
    print("DB Perf Data:")
    print(df_perf.head(), "\n")
    
    # Combine ddi_t and ss_t from both files.
    combined_ddi = pd.concat([df_dump["ddi_t"], df_perf["ddi_t"]])
    combined_ss = pd.concat([df_dump["ss_t"], df_perf["ss_t"]])
    
    # Other metrics remain separate.
    cd_series = df_dump["cd_t"]
    dr_series = df_perf["dr_t"]
    qe_series = df_perf["qe_t"]

    # Compute metrics for each.
    metrics = {
        "ddi_t": compute_metrics(combined_ddi),
        "ss_t": compute_metrics(combined_ss),
        "cd_t": compute_metrics(cd_series),
        "dr_t": compute_metrics(dr_series),
        "qe_t": compute_metrics(qe_series)
    }

    # Prepare a table with rows as metrics and columns as computed statistics.
    headers = ["Metric", "Count", "Mean", "Median", "Std Dev", "Variance", "Min", "Max", "P90", "P95", "P99"]
    table_data = []
    for metric_name, met in metrics.items():
        row = [
            metric_name,
            f"{met['count']:.6f}",
            f"{met['mean']:.6f}",
            f"{met['median']:.6f}",
            f"{met['std_dev']:.6f}",
            f"{met['variance']:.6f}",
            f"{met['min']:.6f}",
            f"{met['max']:.6f}",
            f"{met['p90']:.6f}",
            f"{met['p95']:.6f}",
            f"{met['p99']:.6f}"
        ]
        table_data.append(row)
    
    print("\n===== In-Depth Statistical Analysis =====\n", flush=True)
    print(tabulate(table_data, headers=headers, tablefmt="grid"), flush=True)

    # Prepare data for a combined boxplot.
    data = []
    for metric_name, series in {
        "ddi_t": combined_ddi,
        "ss_t": combined_ss,
        "cd_t": cd_series,
        "dr_t": dr_series,
        "qe_t": qe_series
    }.items():
        for val in series:
            data.append({"metric": metric_name, "value": val})
    df_long = pd.DataFrame(data)

    # Create a boxplot for all metrics.
    plt.figure(figsize=(10, 6))
    sns.boxplot(x="metric", y="value", data=df_long)
    plt.title("Benchmark Metrics Distribution")
    plt.xlabel("Metric")
    plt.ylabel("Time (seconds)")
    plt.tight_layout()
    plt.savefig("benchmark_boxplot.png")
    plt.show()

if __name__ == "__main__":
    main()
