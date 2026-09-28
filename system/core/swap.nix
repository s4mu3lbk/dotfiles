# Swap policy — zram (compressed RAM) as the fast tier, disk swap as backstop.
# zram is higher swap priority than any disk device, so the kernel fills it
# first under memory pressure and only touches disk swap when zram is full.
{...}: {
  zramSwap = {
    enable = true;
    algorithm = "lz4"; # fast compress/decompress; zstd ratios better but CPU-heavier
    memoryPercent = 50; # cap so it can't crowd out real RAM on either host
    memoryMax = "8G";
  };
}
