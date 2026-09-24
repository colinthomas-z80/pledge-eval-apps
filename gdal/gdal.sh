#! /bin/bash
#set -e
set -o pipefail

WCdataPrefix=("wc2.1_2.5m" "wc2.1_5m" "wc2.1_10m")
WCdata=("wc2.1_2.5m_bio" "wc2.1_2.5m_elev" "wc2.1_2.5m_prec" "wc2.1_2.5m_srad" "wc2.1_2.5m_tavg" "wc2.1_2.5m_tmax" "wc2.1_2.5m_tmin" "wc2.1_2.5m_vapr" "wc2.1_2.5m_wind" 
"wc2.1_5m_bio" "wc2.1_5m_elev" "wc2.1_5m_prec" "wc2.1_5m_srad" "wc2.1_5m_tavg" "wc2.1_5m_tmax" "wc2.1_5m_tmin" "wc2.1_5m_vapr" "wc2.1_5m_wind" 
"wc2.1_10m_bio" "wc2.1_10m_elev" "wc2.1_10m_prec" "wc2.1_10m_srad" "wc2.1_10m_tavg" "wc2.1_10m_tmax" "wc2.1_10m_tmin" "wc2.1_10m_vapr" "wc2.1_10m_wind")

CCMdata=("ccm3_bio1-9_30s" "ccm3_bio10-19_30s" "ccm3_bio_2-5m" "ccm3_bio_5m" "ccm3_bio_10m"
"ccm3_prec_2-5m" "ccm3_prec_5m" "ccm3_prec_10m" "ccm3_prec_30s"
"ccm3_tmax_2-5m" "ccm3_tmax_5m" "ccm3_tmax_10m" "ccm3_tmax_30s" "ccm3_tmean_2-5m" "ccm3_tmean_5m" "ccm3_tmean_10m" "ccm3_tmin_2-5m" "ccm3_tmin_5m" "ccm3_tmin_10m" "ccm3_tmin_30s")

Geodata=("${WCdata[@]}" "${CCMdata[@]}")

if [[ $1 = "fetch" ]]; then
    for gt in ${WCdata[@]}; do
        if [[ -f $gt.zip ]]; then 
            echo $gt already exists... Skipping.
            continue 
        fi
        echo $gt
        wget "https://geodata.ucdavis.edu/climate/worldclim/2_1/base/$gt.zip"
        unzip $gt.zip -d $gt
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
fi


