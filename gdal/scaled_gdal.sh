#! /bin/bash
#set -e
set -o pipefail

WCdataPrefix=("wc2.1_2.5m" "wc2.1_5m" "wc2.1_10m")
WCdata=("wc2.1_2.5m_bio" "wc2.1_2.5m_elev" "wc2.1_2.5m_prec" "wc2.1_2.5m_srad" "wc2.1_2.5m_tavg" "wc2.1_2.5m_tmax" "wc2.1_2.5m_tmin" "wc2.1_2.5m_vapr" "wc2.1_2.5m_wind" 
"wc2.1_5m_bio" "wc2.1_5m_elev" "wc2.1_5m_prec" "wc2.1_5m_srad" "wc2.1_5m_tavg" "wc2.1_5m_tmax" "wc2.1_5m_tmin" "wc2.1_5m_vapr" "wc2.1_5m_wind" 
"wc2.1_10m_bio" "wc2.1_10m_elev" "wc2.1_10m_prec" "wc2.1_10m_srad" "wc2.1_10m_tavg" "wc2.1_10m_tmax" "wc2.1_10m_tmin" "wc2.1_10m_vapr" "wc2.1_10m_wind")

WCdataPrefixLarge=("wc2.1_30s")
WCdataLarge=("wc2.1_30s_elev" "wc2.1_30s_prec" "wc2.1_30s_srad" "wc2.1_30s_tavg" "wc2.1_30s_tmax" "wc2.1_30s_tmin" "wc2.1_30s_vapr" "wc2.1_30s_wind")
#WCdataLarge=("wc2.1_30s_elev" "wc2.1_30s_prec" "wc2.1_30s_srad" "wc2.1_30s_vapr" "wc2.1_30s_wind")


Geodata=("${WCdata[@]}" "${WCdataLarge[@]}")
GeodataPrefixes=("${WCdataPrefix[@]}" "${WCdataPrefixLarge[@]}")

if [[ $1 = "fetch" ]]; then
    for gt in ${Geodata[@]}; do
        if [[ -f $gt.zip ]]; then 
            echo $gt already exists... Skipping.
            continue 
        fi
        echo $gt
        wget "https://geodata.ucdavis.edu/climate/worldclim/2_1/base/$gt.zip"
        unzip $gt.zip -d $gt
        rm $gt.zip
    done
elif [[ $1 = "clean" ]]; then
    echo "Cleaning up files..."
    for wc in ${GeodataPrefixes[@]}; do
        echo "Deleting all $wc tif files"
        rm "${wc}_elev_prec_srad.tif"
        rm "${wc}_elev_tavg_srad.tif"
        rm "${wc}_elev_tmax_tmin_vapr.tif"
        rm "${wc}_elev_prec_vapr_tavg.tif"
        rm "${wc}_elev_prec_srad_vapr.tif"    
		rm ${wc}_*.tif
    done
    for gt in ${Geodata[@]}; do
        echo "Deleting all $gt vrt files"
        rm $gt.vrt
    done
	if [[ $2 = "all" ]]; then
		echo "Removing directories..."
		for dir in ${WCdata[@]}; do
			echo "Deleting $dir"
			rm -r "${dir}"
		done
		for dir in ${WCdataLarge[@]}; do
			echo "Deleting $dir"
			rm -r "${dir}"
		done
	fi
else
    for gt in ${WCdata[@]}; do
        echo $gt
        gdalbuildvrt $gt.vrt $gt/*.tif
    done

    for wc in ${WCdataPrefix[@]}; do
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_srad.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_srad.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_tavg.vrt" "${wc}_srad.vrt" "${wc}_elev.vrt" "${wc}_elev_tavg_srad.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_tmax.vrt" "${wc}_tmin.vrt" "${wc}_vapr.vrt" "${wc}_elev.vrt" "${wc}_elev_tmax_tmin_vapr.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_vapr.vrt" "${wc}_tavg.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_vapr_tavg.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_srad.vrt" "${wc}_vapr.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_srad_vapr.tif"
    done

    for gt in ${WCdataLarge[@]}; do
        echo $gt
        gdalbuildvrt $gt.vrt $gt/*.tif
    done

    for wc in ${WCdataPrefixLarge[@]}; do
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_srad.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_srad.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_vapr.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_vapr.tif"
        gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_wind.vrt" "${wc}_elev.vrt" "${wc}_elev_wind_prec.tif"
        # gdalwarp -of GTiff -r bilinear -multi "${wc}_tmax.vrt" "${wc}_tmin.vrt" "${wc}_vapr.vrt" "${wc}_elev.vrt" "${wc}_elev_tmax_tmin_vapr.tif"
        # gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_vapr.vrt" "${wc}_tavg.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_vapr_tavg.tif"
        # gdalwarp -of GTiff -r bilinear -multi "${wc}_prec.vrt" "${wc}_srad.vrt" "${wc}_vapr.vrt" "${wc}_elev.vrt" "${wc}_elev_prec_srad_vapr.tif"
    done
fi
