#!/usr/bin/env bash

version() {
	echo "Version 0.0.1"
}

checkreqvar() {(
set -e
reqvar=( "$@" )

for var in "${reqvar[@]}"
do
	if [[ -z ${!var+x} ]]
	then
		echo "${var} is unset, stop program" && return 1
	else
		echo "${var} is set to ${!var}"
	fi
done
)}

checkoptvar() {(
set -e
optvar=( "$@" )

for var in "${optvar[@]}"
do
	echo "${var} is set to ${!var}"
done
)}

removeniisfx() {(
set -e
echo ${1%.nii*}
)}

if_missing_do() {(
set -e
case $1 in
	mkdir )
		if [ ! -d $2 ]
		then
			echo "Create folder(s)" "${@:2}"
			mkdir -p "${@:2}"
		fi
		;;
	stop )
		if [ ! -e $2 ]
		then
			echo "$2 not found"
			return 1
		fi
		;;
	* )
		if [ ! -e $3 ]
		then
			printf "%s is missing, " "$3"
			case $1 in
				copy ) echo "copying $2";		cp $2 $3 ;;
				move ) echo "moving $2";		mv $2 $3 ;;
				mask ) echo "binarising $2";	fslmaths $2 -bin $3 ;;
				* ) echo "and you shouldn't see this"; return 1;;
			esac
		fi
		;;
esac
)}

replace_and() {(
set -e
case $1 in
	mkdir) if [ -d $2 ]; then echo "$2 exists already, removing first"; rm -rf $2; fi; mkdir -p $2 ;;
	touch) if [ -d $2 ]; then echo "$2 exists already, removing first"; rm -rf $2; fi; touch $2 ;;
	* ) echo "This is wrong"; return 1;;
esac
)}


displayhelp_slice_coeff() {(
set -e
echo "Required:"
echo "img"
echo "Optional I/O:"
echo "bckimg bckimgname imgname outdir outname"
echo "Figure look:"
echo "cmap ncmap ncols nrows arange srange crange disprange size cmapres autobox"
echo "System:"
echo "tmp debug"
echo "Extra:"
echo "skip_axial skip_sagittal skip_coronal only_axial only_sagittal only_coronal hide_cbar clusters"
return ${1:-0}
)}

slice_coeffs() {(
set -e

# Check if there is input

[[ ( $# -eq 0 ) ]] && displayhelp_slice_coeff && return 0

# Preparing the default values for variables
bckimg=none
bckimgname=anat
imgname=beta
showcbar=yes
cmap=red-yellow
ncmap=none # ncmap=blue-lightblue
ncols=10
nrows=1
arange=none
srange=none
crange=none
disprange=none
size=none
axial=yes
sagittal=yes
coronal=yes
autobox=no
outdir=none
outname=none
cmapres=256
clusters=no
tmp=.
debug=no

# Parsing required and optional variables with flags
# Also checking if a flag is the help request or the version
while [ ! -z "$1" ]
do
	case "$1" in
		-img)	img=$2;shift;;

		-bckimg)		bckimg=$2;shift;;
		-bckimgname)	bckimgname="$2";shift;;
		-imgname)		imgname="$2";shift;;
		-cmap)			cmap=$2;shift;;
		-ncmap)			ncmap=$2;shift;;
		-ncols)			ncols=$2;shift;;
		-nrows)			nrows=$2;shift;;
		-arange)		arange="$2";shift;;
		-srange)		srange="$2";shift;;
		-crange)		crange="$2";shift;;
		-disprange)		disprange="$2";shift;;
		-size)			size="$2";shift;;
		-cmapres)		cmapres="$2";shift;;
		-clusters)		clusters=yes;;

		-outdir)	outdir=$2;shift;;
		-outname)	outname=$2;shift;;

		-autobox)		autobox=yes;;
		-hide_cbar)		showcbar=no;;
		-skip_axial)	axial=no;;
		-skip_sagittal)	sagittal=no;;
		-skip_coronal)	coronal=no;;
		-only_axial)	axial=yes;sagittal=no;coronal=no;nrows=3;;
		-only_sagittal)	axial=no;sagittal=yes;coronal=no;nrows=3;;
		-only_coronal)	axial=no;sagittal=no;coronal=yes;nrows=3;;

		-tmp)		tmp=$2;shift;;
		-debug)		debug=yes;;

		-h)			displayhelp_slice_coeff;return 0;;
		-v)			version;return 0;;
		*)			echo "Wrong flag: $1";displayhelp_slice_coeff 1;;
	esac
	shift
done

### print input
printline=$( basename -- $0 )
echo "${printline} " "$@"
checkreqvar img

### Derive variables
[[ ${outname} == "none" ]] && outname=$( basename $( removeniisfx ${img} ) )
[[ ${outdir} == "none" ]] && outdir=.
outname=${outdir%/}/$( basename ${outname} )
tmp=${tmp}/tmp_sc_$( basename ${outname})
[[ ${clusters} == "yes" ]] && cmap=clusters50 && cmapres=50 && disprange=50


### print more input
checkoptvar bckimg bckimgname imgname outdir outname cmap ncmap ncols nrows arange srange crange disprange size autobox showcbar axial coronal sagittal tmp debug clusters cmapres disprange

### Remove nifti suffix
for var in img bckimg
do
	eval "${var}=$( removeniisfx ${!var} )"
done

[[ ${debug} == "yes" ]] && set -x

replace_and mkdir ${tmp}

[[ ${autobox} == "yes" ]] && 3dAutobox -overwrite -input ${img}.nii.gz -prefix ${tmp}/${img}_box.nii.gz && img=${tmp}/${img}_box

runconvert="convert -append"

axes=()
[[ ${axial} == "yes" ]] && axes+=( axial )
[[ ${sagittal} == "yes" ]] && axes+=( sagittal )
[[ ${coronal} == "yes" ]] && axes+=( coronal )

if [[ "${size}" == "none" ]]
then
	size=( 1900 )
	let height=200*nrows
	size+=( ${height} )
else
	size=( ${size} )
fi

#Check displayrange
if [[ ${disprange} != "none" ]]
then
	nr=$( wc -w <<< ${disprange} )
	[[ ${nr} -lt 2 ]] && disprange="0 ${disprange}"
	[[ ${nr} -gt 2 ]] && disprange=$( awk '{print $1 " " $2}' <<< ${disprange} )
fi


for ax in "${axes[@]}"
do
	runfsleyes="fsleyes render"
	case ${ax} in
		axial )
				[[ "${arange}" == "none" ]] && arange=( 19.3 139.9 ) || arange=( ${arange} )
				slicespace=$( bc <<< "(${arange[1]}-${arange[0]})/(${nrows}*${ncols})" )
				runfsleyes="${runfsleyes} -of ${tmp}/${outname}_tmp_axial.png --size ${size[*]} --scene lightbox"
				runfsleyes="${runfsleyes} --zaxis 2 --sliceSpacing ${slicespace} --zrange ${arange[*]}" # --sliceSpacing 12
				runconvert="${runconvert} ${tmp}/${outname}_tmp_axial.png"
			;;
		sagittal )
				[[ "${srange}" == "none" ]] && srange=( 39.5 169 ) || srange=( ${srange} )
				slicespace=$( bc <<< "(${srange[1]}-${srange[0]})/(${nrows}*${ncols})" )
				runfsleyes="${runfsleyes} -of ${tmp}/${outname}_tmp_sagittal.png --size ${size[*]} --scene lightbox"
				runfsleyes="${runfsleyes} --zaxis 0 --sliceSpacing ${slicespace} --zrange ${srange[*]}" # --sliceSpacing 13
				runconvert="${runconvert} ${tmp}/${outname}_tmp_sagittal.png"
			;;
		coronal )
				[[ "${crange}" == "none" ]] && crange=( 21 169 ) || crange=( ${crange} )
				slicespace=$( bc <<< "(${crange[1]}-${crange[0]})/(${nrows}*${ncols})" )
				runfsleyes="${runfsleyes} -of ${tmp}/${outname}_tmp_coronal.png --size ${size[*]} --scene lightbox"
				runfsleyes="${runfsleyes} --zaxis 1 --sliceSpacing ${slicespace} --zrange ${crange[*]}" # --sliceSpacing 15
				runconvert="${runconvert} ${tmp}/${outname}_tmp_coronal.png"
			;;
	esac
	runfsleyes="${runfsleyes} --ncols ${ncols} --nrows ${nrows} --hideCursor --bgColour 0.0 0.0 0.0 --fgColour 1.0 1.0 1.0"
	[[ ${showcbar} == "yes" ]] && runfsleyes="${runfsleyes} --showColourBar --colourBarLocation right --colourBarLabelSide bottom-right --colourBarSize 80.0 --labelSize 12"
	runfsleyes="${runfsleyes} --performance 3 --movieSync"
	[[ ${bckimg} != "none" ]] && runfsleyes="${runfsleyes} ${bckimg}.nii.gz --name \"${bckimgname}\" --overlayType volume --alpha 100.0 --brightness 49.75000000000001 --contrast 49.90029860765409 --cmap greyscale --negativeCmap greyscale --displayRange 0.0 631.9035656738281 --clippingRange 0.0 631.9035656738281 --gamma 0.0 --cmapResolution 256 --interpolation none --invert --numSteps 100 --blendFactor 0.1 --smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0"
	runfsleyes="${runfsleyes} ${img}.nii.gz --name \"${imgname}\" --overlayType volume --alpha 100.0 --cmap ${cmap}"
	[[ ${ncmap} != "none" ]] && runfsleyes="${runfsleyes} --negativeCmap ${ncmap} --useNegativeCmap"
	[[ ${disprange} != "none" ]] && runfsleyes="${runfsleyes} --displayRange ${disprange}"
	runfsleyes="${runfsleyes} --gamma 0.0 --cmapResolution ${cmapres} --interpolation none --numSteps 100 --blendFactor 0.1 --smoothing 0 --resolution 100 --numInnerSteps 10 --clipMode intersection --volume 0"
	eval ${runfsleyes}
done

# Mount visions
runconvert="${runconvert} +repage ${outname}.png"
eval ${runconvert}

if [[ ${debug} == "yes" ]]; then set +x; else rm -rf ${tmp}; fi

)}