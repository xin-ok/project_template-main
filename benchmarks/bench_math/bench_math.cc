#include <benchmark/benchmark.h>

#include <numeric>
#include <vector>

double sum_of_squares_baseline(const std::vector<double>& data) {
  return std::accumulate(
      data.begin(), data.end(), 0.0, [](double acc, double x) {
        return acc + x * x;
      });
}

static void BM_SumOfSquares(benchmark::State& state) {
  const int n = static_cast<int>(state.range(0));
  std::vector<double> data(n, 1.5);

  for (auto _ : state) {
    double result = sum_of_squares_baseline(data);
    benchmark::DoNotOptimize(result);
  }

  state.SetBytesProcessed(static_cast<int64_t>(state.iterations()) * n *
                          sizeof(double));
  state.SetItemsProcessed(static_cast<int64_t>(state.iterations()) * n);
}

BENCHMARK(BM_SumOfSquares)->Range(64, 1 << 20)->Unit(benchmark::kMicrosecond);

BENCHMARK_MAIN();