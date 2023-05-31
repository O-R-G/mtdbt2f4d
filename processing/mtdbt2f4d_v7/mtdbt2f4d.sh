SOURCE=$(pwd)

# mkdir run
processing-java --sketch=$SOURCE --output=$SOURCE/run --run --force
rm -r run
exit
