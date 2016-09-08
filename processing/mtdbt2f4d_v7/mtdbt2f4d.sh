SOURCE="/Users/reinfurt/Documents/Softwares/Processing/mtdbt2f4d/mtdbt2f4d_v7/"

mkdir run
processing-java --sketch=$SOURCE --output=$SOURCE/run --run --force
rm -r run
exit
