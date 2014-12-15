MDS=$MDS
HELPERS="/home/msevilla/mds/scripts/helpers"

echo "how many samples?"
read SAMPLES

echo "data or metadata?"
read FILE

rm thruput.out
for i in $(seq 0 $SAMPLES); do cat statpools-$i  | grep -A1 cephfs_$FILE | tail -1 | awk '{print $3}' >> thruput.temp; done
sed -e 's/going/0/g' thruput.temp > thruput.out
rm thruput.temp

