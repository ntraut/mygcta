#!/bin/bash
# mygcta
# makes it nicer to use gcta
# nicolas traut, v3 16 May 2017
# roberto toro, v2 30 July 2013
# roberto toro, v1 12 July 2012

set -e

if command -v gmktemp >& /dev/null; then
    mktemp=gmktemp
else
    mktemp=mktemp
fi

np=0; nq=0; nc=0; ng=0;
tmp=$($mktemp)
tmp_pheno=$($mktemp --suffix=.pheno)
tmp_qcovar=$($mktemp --suffix=.qcovar)
tmp_covar=$($mktemp --suffix=.covar)
tmp_gxe=$($mktemp --suffix=.gxe)
trap 'echo removing temporary files; rm $tmp $tmp_pheno $tmp_qcovar $tmp_covar $tmp_gxe' EXIT
pca=
out=gcta

while [[ $# -gt 0 ]]
do
	key="$1"
	case $key in
	--pheno)
		file="$2"
		if [[ $np -eq 0 ]]; then
			pheno=$file
		else
		    if [[ $np -eq 1 ]]; then
		        cat $pheno > $tmp_pheno
		        pheno=$tmp_pheno
		    fi
			awk 'NR == FNR {
				k[$1, $2]=$0
				next
			}
			($1, $2) in k {
				printf "%s", k[$1, $2]
				for (i=3; i<=NF; i++)
					printf " %s", $i
				print ""
			}' $tmp_pheno $file > $tmp
			cp $tmp $tmp_pheno
		fi
		shift # past argument
		((++np))
		;;
	--qcovar)
		file="$2"
		if [[ $nq -eq 0 ]]; then
			qcovar=$file
		else
		    if [[ $nq -eq 1 ]]; then
		        cat $qcovar > $tmp_qcovar
		        qcovar=$tmp_qcovar
		    fi
			awk 'NR == FNR {
				k[$1, $2]=$0
				next
			}
			($1, $2) in k {
				printf "%s", k[$1, $2]
				for (i=3; i<=NF; i++)
					printf " %s", $i
				print ""
			}' $tmp_qcovar $file > $tmp
			cp $tmp $tmp_qcovar
		fi
		shift # past argument
		((++nq))
		;;
	--covar)
		file="$2"
		if [[ $nc -eq 0 ]]; then
		    covar=$file
		else
		    if [[ $nc -eq 1 ]]; then
		        cat $covar > $tmp_covar
		        covar=$tmp_covar
		    fi
			awk 'NR == FNR {
				k[$1, $2]=$0
				next
			}
			($1, $2) in k {
				printf "%s", k[$1, $2]
				for (i=3; i<=NF; i++)
					printf " %s", $i
				print ""
			}' $tmp_covar $file > $tmp
			cp $tmp $tmp_covar
		fi
		shift # past argument
		((++nc))
		;;
	--gxe)
		file="$2"
		if [[ $ng -eq 0 ]]; then
		    gxe=$file
		else
		    if [[ $nc -eq 1 ]]; then
		        cat $gxe > $tmp_gxe
		        gxe=$tmp_gxe
		    fi
			awk 'NR == FNR {
				k[$1, $2]=$0
				next
			}
			($1, $2) in k {
				printf "%s", k[$1, $2]
				for (i=3; i<=NF; i++)
					printf " %s", $i
				print ""
			}' $tmp_gxe $file > $tmp
			cp $tmp $tmp_gxe
		fi
		shift # past argument
		((++ng))
		;;
	--pca)
		pca=$2
		cmd="$cmd $key"
		;;
	--out)
		out=$2
		shift # past argument
		;;
	*)
		cmd="$cmd $key"
		;;
	esac
	shift
done

echo "npheno=$np, nqcovar=$nq, ncovar=$nc, ngxe=$ng"

if [[ $np -ne 0 ]]; then
	cmd="$cmd --pheno $pheno"
fi
if [[ $nq -ne 0 ]]; then
	cmd="$cmd --qcovar $qcovar"
fi
if [[ $nc -ne 0 ]]; then
	cmd="$cmd --covar $covar"
fi
if [[ $ng -ne 0 ]]; then
	cmd="$cmd --gxe $gxe"
fi
cmd="$cmd --out $out"

echo "$cmd"
eval "$cmd"

if [[ -n "$pca" && -f $out.eigenvec ]]; then
	pca=$(( $(head -1 $out.eigenvec | awk '{print NF}') - 2 ))
	sed -i "1iFID IID $(seq -f PC%g -s ' ' 1 $pca)" $out.eigenvec
fi
