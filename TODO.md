before

Name           ips        average  deviation         median         99th %
read          9.11      109.74 ms     ±3.57%      108.99 ms      118.06 ms

Benchmarking read...

Name           ips        average  deviation         median         99th %
read         10.67       93.73 ms     ±0.65%       93.69 ms       96.28 ms

main

Name                                        ips        average  deviation         median         99th %
no filter, no compression                  4.87      205.25 ms     ±3.55%      204.67 ms      217.87 ms
no filter, default compression             4.60      217.19 ms     ±4.93%      219.42 ms      233.20 ms
no filter, max compression                 4.53      220.63 ms     ±5.27%      220.70 ms      246.96 ms
up filter, no compression                  3.76      265.61 ms     ±4.74%      262.80 ms      296.80 ms
up filter, default compression             3.63      275.38 ms     ±4.60%      276.45 ms      301.84 ms
paeth filter, no compression               3.50      285.42 ms     ±4.41%      285.29 ms      313.73 ms
paeth filter, default compression          3.38      296.10 ms     ±4.37%      295.59 ms      318.59 ms
up filter, max compression                 3.19      313.60 ms     ±3.83%      314.49 ms      340.17 ms
paeth filter, max compression              2.96      337.39 ms     ±4.11%      337.80 ms      380.09 ms

Comparison:
no filter, no compression                  4.87
no filter, default compression             4.60 - 1.06x slower +11.94 ms
no filter, max compression                 4.53 - 1.07x slower +15.38 ms
up filter, no compression                  3.76 - 1.29x slower +60.36 ms
up filter, default compression             3.63 - 1.34x slower +70.13 ms
paeth filter, no compression               3.50 - 1.39x slower +80.17 ms
paeth filter, default compression          3.38 - 1.44x slower +90.85 ms
up filter, max compression                 3.19 - 1.53x slower +108.34 ms
paeth filter, max compression              2.96 - 1.64x slower +132.14 ms

pixels

Name                                        ips        average  deviation         median         99th %
no filter, no compression                 14.71       67.98 ms     ±7.91%       68.17 ms       84.82 ms
no filter, default compression            13.02       76.79 ms     ±8.14%       76.41 ms       95.40 ms
no filter, max compression                11.68       85.62 ms     ±6.94%       84.92 ms      104.17 ms
up filter, no compression                  6.45      155.14 ms     ±7.31%      156.83 ms      178.53 ms
up filter, default compression             6.17      161.95 ms     ±6.73%      160.68 ms      195.79 ms
paeth filter, no compression               6.05      165.21 ms     ±7.99%      162.99 ms      195.16 ms
paeth filter, default compression          5.80      172.50 ms     ±7.45%      169.80 ms      209.29 ms
up filter, max compression                 4.82      207.43 ms     ±4.87%      209.53 ms      232.50 ms
paeth filter, max compression              4.41      226.81 ms     ±5.16%      223.87 ms      265.56 ms

Comparison:
no filter, no compression                 14.71
no filter, default compression            13.02 - 1.13x slower +8.81 ms
no filter, max compression                11.68 - 1.26x slower +17.64 ms
up filter, no compression                  6.45 - 2.28x slower +87.16 ms
up filter, default compression             6.17 - 2.38x slower +93.97 ms
paeth filter, no compression               6.05 - 2.43x slower +97.23 ms
paeth filter, default compression          5.80 - 2.54x slower +104.52 ms
up filter, max compression                 4.82 - 3.05x slower +139.45 ms
paeth filter, max compression              4.41 - 3.34x slower +158.83 ms

large before

Name                                        ips        average  deviation         median         99th %
no filter, max compression               0.0410        24.42 s     ±0.00%        24.42 s        24.42 s
no filter, no compression                0.0408        24.49 s     ±0.00%        24.49 s        24.49 s
no filter, default compression           0.0405        24.68 s     ±0.00%        24.68 s        24.68 s
up filter, default compression           0.0373        26.79 s     ±0.00%        26.79 s        26.79 s
up filter, max compression               0.0371        26.97 s     ±0.00%        26.97 s        26.97 s
paeth filter, no compression             0.0369        27.11 s     ±0.00%        27.11 s        27.11 s
up filter, no compression                0.0369        27.12 s     ±0.00%        27.12 s        27.12 s
paeth filter, default compression        0.0354        28.21 s     ±0.00%        28.21 s        28.21 s
paeth filter, max compression            0.0353        28.36 s     ±0.00%        28.36 s        28.36 s

Comparison:
no filter, max compression               0.0410
no filter, no compression                0.0408 - 1.00x slower +0.0722 s
no filter, default compression           0.0405 - 1.01x slower +0.26 s
up filter, default compression           0.0373 - 1.10x slower +2.37 s
up filter, max compression               0.0371 - 1.10x slower +2.55 s
paeth filter, no compression             0.0369 - 1.11x slower +2.69 s
up filter, no compression                0.0369 - 1.11x slower +2.70 s
paeth filter, default compression        0.0354 - 1.16x slower +3.79 s
paeth filter, max compression            0.0353 - 1.16x slower +3.94 s

after

Name                                        ips        average  deviation         median         99th %
no filter, default compression             0.26         3.84 s     ±4.05%         3.86 s         3.99 s
no filter, max compression                 0.26         3.85 s     ±3.73%         3.86 s         3.99 s
no filter, no compression                  0.24         4.17 s     ±3.74%         4.14 s         4.33 s
up filter, no compression                 0.152         6.58 s     ±1.42%         6.58 s         6.65 s
up filter, default compression            0.149         6.71 s     ±7.92%         6.71 s         7.09 s
paeth filter, default compression         0.148         6.75 s     ±8.89%         6.75 s         7.17 s
up filter, max compression                0.147         6.79 s     ±1.94%         6.79 s         6.88 s
paeth filter, no compression              0.138         7.27 s     ±1.30%         7.27 s         7.33 s
paeth filter, max compression             0.132         7.59 s    ±12.52%         7.59 s         8.26 s

Comparison:
no filter, default compression             0.26
no filter, max compression                 0.26 - 1.00x slower +0.00585 s
no filter, no compression                  0.24 - 1.08x slower +0.32 s
up filter, no compression                 0.152 - 1.71x slower +2.74 s
up filter, default compression            0.149 - 1.75x slower +2.87 s
paeth filter, default compression         0.148 - 1.76x slower +2.91 s
up filter, max compression                0.147 - 1.77x slower +2.94 s
paeth filter, no compression              0.138 - 1.89x slower +3.42 s
paeth filter, max compression             0.132 - 1.97x slower +3.74 s

