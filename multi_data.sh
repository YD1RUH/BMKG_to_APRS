#by YD1RUH

#informasi server
serverHost="103.154.80.106"
serverPort="14580"
callsign="GEMPA"
password="14583"
login="user $callsign pass $password vers ShellBeacon 1.0"
delay="5" #dalam detik

while true
	do
	clear
	echo "grabbing data"
	echo ""
	echo ""
	echo ""

	#grabbing data
	curl https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.xml > gempaterkini.xml

	#calculate how many tags gempa
	count=$(perl -nle "print s/<gempa>//g" < gempaterkini.xml | awk '{total += $1} END {print total}')

	#loop for post each tags gempa
	COUNTER=1
	while [  $COUNTER -le $count ]; do
		echo ""
		echo ""
		echo "Data ke:" $COUNTER
	        data=$(xmlstarlet sel -t -c '//gempa['$COUNTER']' -n gempaterkini.xml)
	        tanggal=$(grep -oPm1 "(?<=<Tanggal>)[^<]+" <<< "$data")
		jam=$(grep -oPm1 "(?<=<Jam>)[^<]+" <<< "$data")
	        Magnitude=$(grep -oPm1 "(?<=<Magnitude>)[^<]+" <<< "$data")
	        Kedalaman=$(grep -oPm1 "(?<=<Kedalaman>)[^<]+" <<< "$data")
	        Potensi=$(grep -oPm1 "(?<=<Potensi>)[^<]+" <<< "$data")
	        wilayah=$(grep -oPm1 "(?<=<Wilayah>)[^<]+" <<< "$data")
	        koordinat=$(grep -oPm1 "(?<=<coordinates>)[^<]+" <<< "$data")
	        koordinat2=$(<<< $koordinat sed 's/,/ /g')
		koordinat3=$(GeoConvert -d -p -1 --input-string "$koordinat2")
		koordinat4=$(<<< $koordinat3 sed 's/d//g');
		koordinat5=$(<<< $koordinat4 sed "s/'/./g");
		koordinat6=$(<<< $koordinat5 sed "s/\"//g");
		x=$(awk 'NR == 1 {print $1}'  <<< "$koordinat6");
		y=$(awk '{print $2}' <<< "$koordinat6");

		#construction packet
		position="!$x/$y\Q"
		comment=" $tanggal $jam Magnitude:$Magnitude Kedalaman:$Kedalaman Potensi:$Potensi Wilayah:$wilayah"
	        callsign="GEMPA-"$COUNTER
	        address="${callsign}>APRS,TCPIP:"
		packet="${address}${position}${comment}"
		echo $packet

		#send data to IG server
		nc -C $serverHost $serverPort -q 10 <<-END
		$login
		$packet
		END
		if [ "$1" = "1" ]
			then
			exit
		fi
		#sleep 1
		let COUNTER=COUNTER+1
	done
	sleep $delay
done
