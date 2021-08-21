function print_average () {
  for file_path in $(ls ${STAT_DIR}/*.log)
  do
    echo $(basename ${file_path})
    awk '
    NR == 1 {
      for(i=2; i<=NF; i++) {
          printf "%s%s", $i, (i==NF?ORS:OFS)
      }
    }
    NR > 1 {
      for(i=2; i<=NF; i++) {
          sums[i]+=$i
      } 
    }
    END {
      for(i=2; i<=NF; i++) {
          printf "%s%s", sums[i]/(NR-1), (i==NF?ORS:OFS)
      }
    }' ${file_path} | column -t
    echo ""
  done
}
