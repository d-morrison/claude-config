# Prefer per-operation grouping over persistent grouping (dplyr)

When reviewing or writing R code that uses `dplyr`, prefer **per-operation
grouping** (the `.by` argument) over persistent `group_by()` / `ungroup()`
pairs where the grouping is only needed for one operation.

```r
# Preferred — grouping is scoped to this summarise(), no ungroup() needed
df |> summarise(mean_x = mean(x), .by = group_col)

# Avoid — group_by() persists and must be manually ungroup()'d
df |> group_by(group_col) |> summarise(mean_x = mean(x)) |> ungroup()
```

Reference: <https://dplyr.tidyverse.org/reference/dplyr_by.html>

Flag persistent `group_by()` calls during code review when `.by` would work —
i.e. when the grouping is consumed by exactly one downstream verb and there is
no intentional reason to keep the grouping alive across further operations.
