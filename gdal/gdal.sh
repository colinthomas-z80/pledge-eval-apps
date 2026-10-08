#! /bin/bash
#set -e
set -o pipefail

WCdataPrefix=("wc2.1_2.5m" "wc2.1_5m" "wc2.1_10m")
WCdata=("wc2.1_2.5m_bio" "wc2.1_2.5m_elev" "wc2.1_2.5m_prec" "wc2.1_2.5m_srad" "wc2.1_2.5m_tavg" "wc2.1_2.5m_tmax" "wc2.1_2.5m_tmin" "wc2.1_2.5m_vapr" "wc2.1_2.5m_wind" 
"wc2.1_5m_bio" "wc2.1_5m_elev" "wc2.1_5m_prec" "wc2.1_5m_srad" "wc2.1_5m_tavg" "wc2.1_5m_tmax" "wc2.1_5m_tmin" "wc2.1_5m_vapr" "wc2.1_5m_wind" 
"wc2.1_10m_bio" "wc2.1_10m_elev" "wc2.1_10m_prec" "wc2.1_10m_srad" "wc2.1_10m_tavg" "wc2.1_10m_tmax" "wc2.1_10m_tmin" "wc2.1_10m_vapr" "wc2.1_10m_wind")

if [[ $1 = "fetch" ]]; then
    for gt in ${WCdata[@]}; do
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
    for wc in ${WCdataPrefix[@]}; do
        echo "Deleting all $wc tif files"
        rm "${wc}_elev_prec_srad.tif"
        rm "${wc}_elev_tavg_srad.tif"
        rm "${wc}_elev_tmax_tmin_vapr.tif"
        rm "${wc}_elev_prec_vapr_tavg.tif"
        rm "${wc}_elev_prec_srad_vapr.tif"    
    done
    for gt in ${WCdata[@]}; do
        echo "Deleting all $gt vrt files"
        rm $gt.vrt
    done
    if [[ $2 = "all" ]]; then
        echo "Removing directories..."
        for dir in ${WCdata[@]}; do
            echo "Deleting $dir"
            rm -r "${dir}"
        done
    fi 
else
    for gt in ${WCdata[@]}; do
        echo $gt
        gdalbuildvrt $gt.vrt $(pwd)/$gt/*.tif
    done

    for wc in ${WCdataPrefix[@]}; do
        gdalwarp -of GTiff -r bilinear -multi "$(pwd)/${wc}_prec.vrt" "$(pwd)/${wc}_srad.vrt" "$(pwd)/${wc}_elev.vrt" "$(pwd)/${wc}_elev_prec_srad.tif"
        gdalwarp -of GTiff -r bilinear -multi "$(pwd)/${wc}_tavg.vrt" "$(pwd)/${wc}_srad.vrt" "$(pwd)/${wc}_elev.vrt" "$(pwd)/${wc}_elev_tavg_srad.tif"
        gdalwarp -of GTiff -r bilinear -multi "$(pwd)/${wc}_tmax.vrt" "$(pwd)/${wc}_tmin.vrt" "$(pwd)/${wc}_vapr.vrt" "$(pwd)/${wc}_elev.vrt" "$(pwd)/${wc}_elev_tmax_tmin_vapr.tif"
        gdalwarp -of GTiff -r bilinear -multi "$(pwd)/${wc}_prec.vrt" "$(pwd)/${wc}_vapr.vrt" "$(pwd)/${wc}_tavg.vrt" "$(pwd)/${wc}_elev.vrt" "$(pwd)/${wc}_elev_prec_vapr_tavg.tif"
        gdalwarp -of GTiff -r bilinear -multi "$(pwd)/${wc}_prec.vrt" "$(pwd)/${wc}_srad.vrt" "$(pwd)/${wc}_vapr.vrt" "$(pwd)/${wc}_elev.vrt" "$(pwd)/${wc}_elev_prec_srad_vapr.tif"
    done
fi


